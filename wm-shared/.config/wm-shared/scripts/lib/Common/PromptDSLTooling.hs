{-# LANGUAGE NamedFieldPuns #-}

module Common.PromptDSLTooling
    ( DiagnosticSeverity (..)
    , PromptDiagnostic (..)
    , PromptTokenReport (..)
    , SolverReport (..)
    , SolverStatus (..)
    , lintPromptFile
    , lintPromptSource
    , formatPromptSource
    , resolvePromptDocFromFile
    , analyzePromptSMT
    , estimateTokenCount
    , tokenReportForPrompt
    , renderTokenReportLines
    , renderSolverReportLines
    , formatDiagnostic
    , findImportPath
    ) where

import Data.Char (isAlphaNum, isSpace)
import Data.List (intercalate, isInfixOf, isPrefixOf, nub, sortOn, stripPrefix)
import Data.Maybe (catMaybes, fromMaybe, mapMaybe)
import System.Directory (doesFileExist, findExecutable, getHomeDirectory)
import System.Exit (ExitCode (..))
import System.FilePath (takeDirectory, (</>))
import System.Process (readProcessWithExitCode)

import Common.PromptDSL
    ( AtomDecl (..)
    , AtomType (..)
    , ContractClause (..)
    , ExportSpec (..)
    , ImportSpec (..)
    , PromptDoc (..)
    , PromptDocKind (..)
    , PromptFormat (..)
    , PromptRule (..)
    , atomTypeLabel
    , effectivePromptRules
    , effectivePromptRulesWithOrigins
    , extractRuleAtoms
    , mergePromptDocs
    , parsePromptDoc
    , renderPromptDocAs
    , serializePromptDoc
    , validatePromptDoc
    )

data DiagnosticSeverity
    = DiagnosticError
    | DiagnosticWarning
    deriving (Eq, Ord, Show, Read)

data PromptDiagnostic = PromptDiagnostic
    { diagnosticPath :: Maybe FilePath
    , diagnosticLine :: Int
    , diagnosticColumn :: Int
    , diagnosticSeverity :: DiagnosticSeverity
    , diagnosticMessage :: String
    , diagnosticCode :: Maybe String
    }
    deriving (Eq, Show, Read)

data PromptTokenReport = PromptTokenReport
    { tokenSourceCount :: Int
    , tokenResolvedPDSLCount :: Int
    , tokenMarkdownCount :: Int
    , tokenXmlCount :: Int
    , tokenHybridCount :: Int
    }
    deriving (Eq, Show, Read)

lintPromptFile :: FilePath -> IO [PromptDiagnostic]
lintPromptFile path = do
    exists <- doesFileExist path
    if not exists
        then pure [mkDiagnostic (Just path) 1 1 DiagnosticError "file-not-found" "el archivo no existe"]
        else readFile path >>= lintPromptSource path

lintPromptSource :: FilePath -> String -> IO [PromptDiagnostic]
lintPromptSource path source =
    case parsePromptDoc source of
        Left err ->
            pure [diagnosticFromMessage (Just path) err]
        Right parsed -> do
            resolved <- resolvePromptDocFromSource [] path parsed
            case resolved of
                Left errors -> pure errors
                Right doc -> do
                    solverReport <- analyzePromptSMT path doc
                    let structuralDiagnostics = map (diagnosticFromMessage (Just path)) (validatePromptDoc doc)
                        qualityDiagnostics = lintPromptQuality path source doc
                    pure (dedupeDiagnostics (structuralDiagnostics ++ qualityDiagnostics ++ solverDiagnostics solverReport))

formatPromptSource :: String -> Either String String
formatPromptSource source = serializePromptDoc <$> parsePromptDoc source

resolvePromptDocFromFile :: FilePath -> IO (Either [PromptDiagnostic] PromptDoc)
resolvePromptDocFromFile path = do
    exists <- doesFileExist path
    if not exists
        then pure (Left [mkDiagnostic (Just path) 1 1 DiagnosticError "file-not-found" "el archivo no existe"])
        else do
            source <- readFile path
            case parsePromptDoc source of
                Left err -> pure (Left [diagnosticFromMessage (Just path) err])
                Right parsed -> resolvePromptDocFromSource [] path parsed

resolvePromptDocFromSource :: [FilePath] -> FilePath -> PromptDoc -> IO (Either [PromptDiagnostic] PromptDoc)
resolvePromptDocFromSource stack path parsed
    | path `elem` stack =
        pure
            (Left [mkDiagnostic (Just path) 1 1 DiagnosticError "import-cycle" ("Ciclo de imports detectado: " ++ intercalate " -> " (reverse (path : stack)))])
    | otherwise = do
        imported <- mapM (resolveImportDoc (path : stack) path) requested
        pure $
            case partitionEithers imported of
                ([], docs) -> Right (mergePromptDocs cleanDoc docs)
                (errors, _) -> Left (concat errors)
  where
    cleanDoc = parsed { docImports = [], docExtends = [] }
    requested = map importName (docImports parsed) ++ docExtends parsed

resolveImportDoc :: [FilePath] -> FilePath -> String -> IO (Either [PromptDiagnostic] PromptDoc)
resolveImportDoc stack basePath importKey = do
    located <- findImportPath basePath importKey
    case located of
        Nothing ->
            pure
                ( Left
                    [ mkDiagnostic
                        (Just basePath)
                        1
                        1
                        DiagnosticError
                        "unresolved-import"
                        ("No se pudo resolver import `" ++ importKey ++ "`")
                    ]
                )
        Just path -> do
            source <- readFile path
            case parsePromptDoc source of
                Left err ->
                    pure (Left [diagnosticFromMessage (Just path) err])
                Right parsed -> resolvePromptDocFromSource stack path parsed

findImportPath :: FilePath -> String -> IO (Maybe FilePath)
findImportPath basePath importKey = firstExistingFile =<< importCandidates basePath importKey

importCandidates :: FilePath -> String -> IO [FilePath]
importCandidates basePath importKey = do
    home <- getHomeDirectory
    let localDir = takeDirectory basePath
        cleanedKey = normalizeImportKey importKey
        normalized = map (\c -> if c == '.' then '/' else c) cleanedKey
        filename = normalized ++ ".pdsl"
        libraryRoots =
            nub
                ( (home </> ".config" </> "wm-shared" </> "prompt-library")
                    : concatMap promptLibraryRoots (ancestorDirs localDir)
                )
    pure $
        nub
            ( [ localDir </> filename
              , localDir </> (cleanedKey ++ ".pdsl")
              ]
                ++ concatMap (libraryCandidates filename cleanedKey) libraryRoots
            )

normalizeImportKey :: String -> String
normalizeImportKey rawValue =
    case reads (trim rawValue) of
        [(value, rest)] | null (trim rest) -> value
        _ -> trim rawValue

ancestorDirs :: FilePath -> [FilePath]
ancestorDirs start = go [start] start
  where
    go acc current =
        let parent = takeDirectory current
        in if parent == current
            then acc
            else go (acc ++ [parent]) parent

promptLibraryRoots :: FilePath -> [FilePath]
promptLibraryRoots dir =
    [ dir </> "prompt-library"
    , dir </> "wm-shared" </> ".config" </> "wm-shared" </> "prompt-library"
    ]

libraryCandidates :: FilePath -> String -> FilePath -> [FilePath]
libraryCandidates filename cleanedKey baseLibrary =
    let subpromptsDir = baseLibrary </> "subprompts"
        buildsDir = baseLibrary </> "builds"
        librariesDir = baseLibrary </> "libraries"
    in [ subpromptsDir </> filename
       , buildsDir </> filename
       , librariesDir </> filename
       , subpromptsDir </> (cleanedKey ++ ".pdsl")
       , buildsDir </> (cleanedKey ++ ".pdsl")
       , librariesDir </> (cleanedKey ++ ".pdsl")
       ]

firstExistingFile :: [FilePath] -> IO (Maybe FilePath)
firstExistingFile [] = pure Nothing
firstExistingFile (path : rest) = do
    exists <- doesFileExist path
    if exists then pure (Just path) else firstExistingFile rest

analyzePromptSMT :: FilePath -> PromptDoc -> IO SolverReport
analyzePromptSMT path doc = do
    executable <- findExecutable "z3"
    case executable of
        Nothing ->
            pure $
                SolverReport
                    { solverStatus = SolverUnavailable
                    , solverWitnessAtoms = []
                    , solverWitnessAtomsByType = []
                    , solverDeclaredAtomsByType = groupAllDeclaredAtomsByType doc
                    , solverUnsatAssertions = []
                    , solverRedundantAssertions = []
                    , solverDiagnostics = typedSemanticsDiagnostics path doc ++ [mkDiagnostic (Just path) 1 1 DiagnosticWarning "z3-missing" "z3 no esta disponible; se omitio la validacion SMT."]
                    }
        Just _ ->
            let assertions = buildSolverAssertionsTyped doc (effectivePromptRulesWithOrigins doc)
            in if null assertions
                then pure $
                    SolverReport
                        { solverStatus = SolverSkipped
                        , solverWitnessAtoms = []
                        , solverWitnessAtomsByType = []
                        , solverDeclaredAtomsByType = groupAllDeclaredAtomsByType doc
                        , solverUnsatAssertions = []
                        , solverRedundantAssertions = []
                        , solverDiagnostics = typedSemanticsDiagnostics path doc
                        }
                else do
                    let smt = renderUnsatSmt assertions
                    (exitCode, stdoutText, stderrText) <- readProcessWithExitCode "z3" ["-in", "-smt2"] smt
                    buildSolverReport path doc exitCode stdoutText stderrText assertions

buildSolverAssertions :: [(String, PromptRule)] -> [SolverAssertion]
buildSolverAssertions rules =
    concat (zipWith encodeRule [0 :: Int ..] rules)
  where
    encodeRule index (origin, rule) =
        case rule of
            RuleMust atom ->
                maybe [] (\sym -> [assertion index 0 [sym] sym ("El atomo `" ++ atom ++ "` es obligatorio (" ++ origin ++ ").")]) (atomSymbol atom)
            RuleForbid atom ->
                maybe [] (\sym -> [assertion index 0 [sym] ("(not " ++ sym ++ ")") ("El atomo `" ++ atom ++ "` esta prohibido (" ++ origin ++ ").")]) (atomSymbol atom)
            RuleImplies left right ->
                case (atomSymbol left, atomSymbol right) of
                    (Just leftSym, Just rightSym) ->
                        [assertion index 0 [leftSym, rightSym] ("(=> " ++ leftSym ++ " " ++ rightSym ++ ")") ("La regla `" ++ left ++ " -> " ++ right ++ "` debe cumplirse (" ++ origin ++ ").")]
                    _ -> []
            RuleExclusive atoms ->
                let normalized = nub (mapMaybe atomSymbol atoms)
                    pairs = [(a, b) | (aIndex, a) <- zip [0 :: Int ..] normalized, (bIndex, b) <- zip [0 :: Int ..] normalized, aIndex < bIndex]
                in [ assertion index pairIndex [leftSym, rightSym] ("(not (and " ++ leftSym ++ " " ++ rightSym ++ "))") ("Los atomos de una regla `exclusive` no pueden coexistir (" ++ origin ++ ").")
                   | (pairIndex, (leftSym, rightSym)) <- zip [0 :: Int ..] pairs
                   ]
            RuleAtLeast amount atoms ->
                cardinalityAssertion origin index "at_least" amount atoms ">="
            RuleAtMost amount atoms ->
                cardinalityAssertion origin index "at_most" amount atoms "<="
            RuleExactly amount atoms ->
                cardinalityAssertion origin index "exactly" amount atoms "="
    assertion ruleIndex localIndex atoms expr message =
        SolverAssertion
            { solverAssertionName = "r" ++ show ruleIndex ++ "_" ++ show localIndex
            , solverAssertionAtoms = atoms
            , solverAssertionExpr = expr
            , solverAssertionMessage = message
            }
    cardinalityAssertion origin ruleIndex keyword amount atoms operator =
        let normalized = nub (mapMaybe atomSymbol atoms)
            sumExpr = "(+ " ++ unwords (map boolToInt normalized) ++ ")"
            expr = "(" ++ operator ++ " " ++ sumExpr ++ " " ++ show amount ++ ")"
            message = "La regla `" ++ keyword ++ "` debe cumplirse (" ++ show amount ++ " de " ++ show (length normalized) ++ ", " ++ origin ++ ")."
        in if length normalized < 2
            then []
            else [assertion ruleIndex 0 normalized expr message]
    boolToInt symbol = "(ite " ++ symbol ++ " 1 0)"

-- | Build SMT assertions enriched with atom-type comments when atom declarations
-- are available.  The solver query is the same; type info is only embedded in
-- the human-readable assertion messages.
buildSolverAssertionsTyped :: PromptDoc -> [(String, PromptRule)] -> [SolverAssertion]
buildSolverAssertionsTyped doc rules =
    map enrichMessage (buildSolverAssertions rules)
  where
    typeMap = [(normalizeAtom (atomDeclName d), atomTypeLabel (atomDeclType d)) | d <- docAtoms doc]
    enrichMessage a = a { solverAssertionMessage = addTypeHint (solverAssertionMessage a) (solverAssertionAtoms a) }
    addTypeHint msg atoms =
        let hints = mapMaybe (\sym -> fmap (\t -> stripAtomPrefix sym ++ ":" ++ t) (lookup (stripAtomPrefix sym) typeMap)) atoms
        in if null hints then msg else msg ++ " [tipos: " ++ intercalate ", " hints ++ "]"
    stripAtomPrefix sym = drop (length ("atom_" :: String)) sym

renderUnsatSmt :: [SolverAssertion] -> String
renderUnsatSmt assertions =
    unlines $
        [ "(set-logic QF_LIA)"
        , "(set-option :produce-unsat-cores true)"
        ]
            ++ map declareAtom atoms
            ++ map renderAssertion assertions
            ++ ["(check-sat)", "(get-unsat-core)"]
  where
    atoms = nub (concatMap referencedAtoms assertions)
    declareAtom atom = "(declare-fun " ++ atom ++ " () Bool)"
    renderAssertion SolverAssertion {solverAssertionName, solverAssertionExpr} =
        "(assert (! " ++ solverAssertionExpr ++ " :named " ++ solverAssertionName ++ "))"

referencedAtoms :: SolverAssertion -> [String]
referencedAtoms = solverAssertionAtoms

buildSolverReport :: FilePath -> PromptDoc -> ExitCode -> String -> String -> [SolverAssertion] -> IO SolverReport
buildSolverReport path doc exitCode stdoutText stderrText assertions =
    case lines stdoutText of
        ("sat" : _) -> do
            witnessAtoms <- queryWitnessAtoms assertions
            redundantAssertions <- findRedundantAssertions assertions
            pure $
                SolverReport
                    { solverStatus = SolverSat
                    , solverWitnessAtoms = witnessAtoms
                    , solverWitnessAtomsByType = groupSelectedAtomsByType doc witnessAtoms
                    , solverDeclaredAtomsByType = groupAllDeclaredAtomsByType doc
                    , solverUnsatAssertions = []
                    , solverRedundantAssertions = redundantAssertions
                    , solverDiagnostics = typedSemanticsDiagnostics path doc
                    }
        ("unsat" : rest) ->
            let coreNames = parseUnsatCore (unwords rest)
                offending = filter (\value -> solverAssertionName value `elem` coreNames) assertions
                summary = "Z3 detecto restricciones incompatibles en el prompt (" ++ show (length offending) ++ " restricciones en el unsat core)."
            in pure $
                SolverReport
                    { solverStatus = SolverUnsat
                    , solverWitnessAtoms = []
                    , solverWitnessAtomsByType = []
                    , solverDeclaredAtomsByType = groupAllDeclaredAtomsByType doc
                    , solverUnsatAssertions = offending
                    , solverRedundantAssertions = []
                    , solverDiagnostics =
                        typedSemanticsDiagnostics path doc
                            ++ mkDiagnostic (Just path) 1 1 DiagnosticError "z3-unsat" summary
                            : map (\value -> mkDiagnostic (Just path) 1 1 DiagnosticError "z3-core" (solverAssertionMessage value)) offending
                    }
        ("unknown" : _) ->
            pure $
                SolverReport
                    { solverStatus = SolverUnknown
                    , solverWitnessAtoms = []
                    , solverWitnessAtomsByType = []
                    , solverDeclaredAtomsByType = groupAllDeclaredAtomsByType doc
                    , solverUnsatAssertions = []
                    , solverRedundantAssertions = []
                    , solverDiagnostics = typedSemanticsDiagnostics path doc ++ [mkDiagnostic (Just path) 1 1 DiagnosticWarning "z3-unknown" "Z3 no pudo determinar la consistencia del prompt."]
                    }
        _ ->
            pure $
                SolverReport
                    { solverStatus = SolverRuntimeIssue
                    , solverWitnessAtoms = []
                    , solverWitnessAtomsByType = []
                    , solverDeclaredAtomsByType = groupAllDeclaredAtomsByType doc
                    , solverUnsatAssertions = []
                    , solverRedundantAssertions = []
                    , solverDiagnostics =
                        typedSemanticsDiagnostics path doc
                            ++ [ mkDiagnostic
                            (Just path)
                            1
                            1
                            DiagnosticWarning
                            "z3-runtime"
                            ("No se pudo interpretar la salida de z3 (" ++ show exitCode ++ "): " ++ trim (stdoutText ++ " " ++ stderrText))
                               ]
                    }

queryWitnessAtoms :: [SolverAssertion] -> IO [String]
queryWitnessAtoms assertions = do
    let smt =
            unlines $
                [ "(set-logic QF_LIA)" ]
                    ++ map declareAtom atoms
                    ++ map renderAssertion assertions
                    ++ ["(check-sat)", "(get-model)"]
        atoms = nub (concatMap referencedAtoms assertions)
        declareAtom atom = "(declare-fun " ++ atom ++ " () Bool)"
        renderAssertion SolverAssertion {solverAssertionName, solverAssertionExpr} =
            "(assert (! " ++ solverAssertionExpr ++ " :named " ++ solverAssertionName ++ "))"
    (exitCode, stdoutText, _) <- readProcessWithExitCode "z3" ["-in", "-smt2"] smt
    pure $
        case lines stdoutText of
            ("sat" : rest) | exitCode == ExitSuccess -> parseWitnessAtoms rest
            _ -> []

findRedundantAssertions :: [SolverAssertion] -> IO [SolverAssertion]
findRedundantAssertions assertions = fmap catMaybes (mapM redundantCheck assertions)
  where
    allAtoms = nub (concatMap referencedAtoms assertions)
    declareAtom atom = "(declare-fun " ++ atom ++ " () Bool)"
    renderAssertion SolverAssertion {solverAssertionName, solverAssertionExpr} =
        "(assert (! " ++ solverAssertionExpr ++ " :named " ++ solverAssertionName ++ "))"
    redundantCheck assertion = do
        let others = filter (\value -> solverAssertionName value /= solverAssertionName assertion) assertions
            smt =
                unlines $
                    [ "(set-logic QF_LIA)" ]
                        ++ map declareAtom allAtoms
                        ++ map renderAssertion others
                        ++ ["(assert (not " ++ solverAssertionExpr assertion ++ "))", "(check-sat)"]
        (exitCode, stdoutText, _) <- readProcessWithExitCode "z3" ["-in", "-smt2"] smt
        pure $
            case lines stdoutText of
                ("unsat" : _) | exitCode == ExitSuccess -> Just assertion
                _ -> Nothing

parseWitnessAtoms :: [String] -> [String]
parseWitnessAtoms = go Nothing []
  where
    go _ acc [] = reverse acc
    go pending acc (rawLine : rest) =
        case pending of
            Just atom ->
                case stripPrefix "true" (trim rawLine) of
                    Just _ -> go Nothing (atom : acc) rest
                    Nothing -> go Nothing acc rest
            Nothing ->
                case stripPrefix "(define-fun atom_" (trim rawLine) of
                    Just remainder ->
                        let atomName = takeWhile (\c -> isAlphaNum c || c == '_') remainder
                        in go (if null atomName then Nothing else Just atomName) acc rest
                    Nothing -> go Nothing acc rest

data SolverStatus
    = SolverSat
    | SolverUnsat
    | SolverUnknown
    | SolverUnavailable
    | SolverRuntimeIssue
    | SolverSkipped
    deriving (Eq, Show, Read)

data SolverReport = SolverReport
    { solverStatus :: SolverStatus
    , solverWitnessAtoms :: [String]
    , solverWitnessAtomsByType :: [(String, [String])]
    , solverDeclaredAtomsByType :: [(String, [String])]
    , solverUnsatAssertions :: [SolverAssertion]
    , solverRedundantAssertions :: [SolverAssertion]
    , solverDiagnostics :: [PromptDiagnostic]
    }

estimateTokenCount :: String -> Int
estimateTokenCount = go 0
  where
    go acc [] = acc
    go acc (c : rest)
        | isSpace c = go acc rest
        | isTokenChar c =
            let remaining = dropWhile isTokenChar rest
            in go (acc + 1) remaining
        | otherwise = go (acc + 1) rest
    isTokenChar c = isAlphaNum c || c `elem` ("_-./:" :: String)

tokenReportForPrompt :: String -> PromptDoc -> PromptTokenReport
tokenReportForPrompt source doc =
    PromptTokenReport
        { tokenSourceCount = estimateTokenCount source
        , tokenResolvedPDSLCount = estimateTokenCount (serializePromptDoc doc)
        , tokenMarkdownCount = estimateTokenCount (renderPromptDocAs FormatMarkdown doc)
        , tokenXmlCount = estimateTokenCount (renderPromptDocAs FormatXml doc)
        , tokenHybridCount = estimateTokenCount (renderPromptDocAs FormatHybrid doc)
        }

renderTokenReportLines :: PromptTokenReport -> [String]
renderTokenReportLines report =
    [ "source-estimate: " ++ show (tokenSourceCount report)
    , "resolved-pdsl-estimate: " ++ show (tokenResolvedPDSLCount report)
    , "compiled-markdown-estimate: " ++ show (tokenMarkdownCount report)
    , "compiled-xml-estimate: " ++ show (tokenXmlCount report)
    , "compiled-hybrid-estimate: " ++ show (tokenHybridCount report)
    ]

renderSolverReportLines :: SolverReport -> [String]
renderSolverReportLines report =
    [ "status: " ++ show (solverStatus report)
    , "witness-atoms: " ++ intercalate ", " (solverWitnessAtoms report)
    , "witness-by-type: " ++ renderAtomGroups (solverWitnessAtomsByType report)
    , "declared-atoms-by-type: " ++ renderAtomGroups (solverDeclaredAtomsByType report)
    , "unsat-core:"
    ]
        ++ map (\value -> "  - " ++ solverAssertionName value ++ " :: " ++ solverAssertionMessage value) (solverUnsatAssertions report)
        ++ [ "redundant-assertions:" ]
        ++ map (\value -> "  - " ++ solverAssertionName value ++ " :: " ++ solverAssertionMessage value) (solverRedundantAssertions report)
  where
    renderAtomGroups groups =
        if null groups
            then "-"
            else intercalate " | " [label ++ "=" ++ intercalate "," values | (label, values) <- groups]

parseUnsatCore :: String -> [String]
parseUnsatCore = words . map sanitize
  where
    sanitize c
        | isAlphaNum c || c == '_' = c
        | otherwise = ' '

atomSymbol :: String -> Maybe String
atomSymbol rawValue =
    case normalizeAtom rawValue of
        "" -> Nothing
        normalized -> Just ("atom_" ++ normalized)

normalizeAtom :: String -> String
normalizeAtom = map normalizeChar . trim
  where
    normalizeChar c
        | isAlphaNum c = c
        | otherwise = '_'

formatDiagnostic :: PromptDiagnostic -> String
formatDiagnostic PromptDiagnostic {diagnosticPath, diagnosticLine, diagnosticColumn, diagnosticSeverity, diagnosticMessage} =
    displayPath ++ ":" ++ show diagnosticLine ++ ":" ++ show diagnosticColumn ++ ": " ++ severityCode diagnosticSeverity ++ ": " ++ diagnosticMessage
  where
    displayPath = maybe "stdin" id diagnosticPath

severityCode :: DiagnosticSeverity -> String
severityCode DiagnosticError = "error"
severityCode DiagnosticWarning = "warning"

diagnosticFromMessage :: Maybe FilePath -> String -> PromptDiagnostic
diagnosticFromMessage path message =
    case parseLinePrefix message of
        Just (lineNo, detail) -> mkDiagnostic path lineNo 1 DiagnosticError "validation" detail
        Nothing -> mkDiagnostic path 1 1 DiagnosticError "validation" message

parseLinePrefix :: String -> Maybe (Int, String)
parseLinePrefix message =
    case splitLinePrefix (trim message) of
        Just (lineToken, detail) ->
            case reads (trim lineToken) of
                [(lineNo, "")] -> Just (lineNo, trim detail)
                _ -> Nothing
        Nothing -> Nothing
  where
    splitLinePrefix value
        | "line " `isPrefixOf` value =
            let afterLine = drop 5 value
                (lineToken, remainder) = break (== ':') afterLine
            in case remainder of
                ':' : rest -> Just (lineToken, rest)
                _ -> Nothing
        | otherwise = Nothing

mkDiagnostic :: Maybe FilePath -> Int -> Int -> DiagnosticSeverity -> String -> String -> PromptDiagnostic
mkDiagnostic path lineNo column severity code message =
    PromptDiagnostic
        { diagnosticPath = path
        , diagnosticLine = max 1 lineNo
        , diagnosticColumn = max 1 column
        , diagnosticSeverity = severity
        , diagnosticMessage = message
        , diagnosticCode = Just code
        }

trim :: String -> String
trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace

partitionEithers :: [Either a b] -> ([a], [b])
partitionEithers = foldr step ([], [])
  where
    step value (lefts, rights) =
        case value of
            Left leftValue -> (leftValue : lefts, rights)
            Right rightValue -> (lefts, rightValue : rights)

data SolverAssertion = SolverAssertion
    { solverAssertionName :: String
    , solverAssertionAtoms :: [String]
    , solverAssertionExpr :: String
    , solverAssertionMessage :: String
    }

data PromptComponent
    = ComponentRole
    | ComponentTask
    | ComponentObjective
    | ComponentInstructions
    | ComponentDeliverables
    | ComponentQualityBar
    | ComponentResponseRules
    | ComponentRules
    deriving (Eq, Show, Read)

data PromptQualitySpec = PromptQualitySpec
    { qualityComponent :: PromptComponent
    , qualityLabel :: String
    , qualityMinimumItems :: Int
    , qualityRecommendedWords :: Int
    , qualityRequiredForFinal :: Bool
    }

lintPromptQuality :: FilePath -> String -> PromptDoc -> [PromptDiagnostic]
lintPromptQuality path source doc =
    concat
        [ blockPresenceDiagnostics
        , emptyBlockDiagnostics
        , roleDiagnostics
        , taskDiagnostics
        , objectiveDiagnostics
        , listDiagnostics instructionsSpecValue (docInstructions doc)
        , listDiagnostics deliverablesSpecValue (docDeliverables doc)
        , listDiagnostics qualityBarSpecValue (docQualityBar doc)
        , listDiagnostics responseRulesSpecValue (docResponseRules doc)
        , ruleCoverageDiagnostics
        , embeddedRuleDiagnostics
        , duplicateRuleDiagnostics
        , legacyRuleDiagnostics
        , duplicateImportDiagnostics
        , duplicateIdeaDiagnostics
        , profileDiagnostics
        , exportCompletenessDiagnostics
        , atomCoverageDiagnostics
        , typeSemanticsDiagnostics
        ]
  where
    locator = makeSourceLocator source
    profiles = qualityProfiles doc
    instructionsSpecValue = selectQualitySpec profiles ComponentInstructions
    deliverablesSpecValue = selectQualitySpec profiles ComponentDeliverables
    qualityBarSpecValue = selectQualitySpec profiles ComponentQualityBar
    responseRulesSpecValue = selectQualitySpec profiles ComponentResponseRules
    objectiveMinimumWords = selectObjectiveMinimum profiles
    objectiveRecommendedWords = selectObjectiveRecommended profiles
    responseRuleSourceItems = collectSourceListBlock source "response_rules"
    blockPresenceDiagnostics =
        concatMap (presenceDiagnostic path locator doc)
            [ instructionsSpecValue
            , deliverablesSpecValue
            , qualityBarSpecValue
            , responseRulesSpecValue
            ]
    emptyBlockDiagnostics =
        concat
            [ emptyListBlockDiagnostic "instructions"
            , emptyListBlockDiagnostic "deliverables"
            , emptyListBlockDiagnostic "quality_bar"
            , emptyListBlockDiagnostic "response_rules"
            , emptyListBlockDiagnostic "acceptance_criteria"
            , emptyListBlockDiagnostic "verification_plan"
            , emptyListBlockDiagnostic "assumptions"
            , emptyListBlockDiagnostic "questions_if_missing"
            , emptyListBlockDiagnostic "risks"
            , emptyListBlockDiagnostic "anti_patterns"
            ]
    roleDiagnostics =
        case docRoles doc of
            [] -> []
            values -> concatMap (sentenceQualityDiagnostics path locator ComponentRole "role" 2 4) values
    taskDiagnostics =
        case docTasks doc of
            [] -> []
            values -> concatMap (sentenceQualityDiagnostics path locator ComponentTask "task" 4 6) values
    objectiveDiagnostics =
        case docObjective doc of
            Nothing -> []
            Just value ->
                sentenceQualityDiagnostics path locator ComponentObjective "objective" objectiveMinimumWords objectiveRecommendedWords value
                    ++ [ mkDiagnostic (Just path) (lineForComponent locator ComponentObjective) 1 DiagnosticWarning "objective-actionability" "El objective deberia describir un resultado observable o evaluable."
                       | not (containsActionVerb value)
                       ]
    ruleCoverageDiagnostics =
        let rulesCount = length (effectivePromptRules doc)
        in [ mkDiagnostic (Just path) (lineForComponent locator ComponentRules) 1 DiagnosticWarning "rules-missing" "Conviene definir un bloque `rules` explicito para capturar restricciones formales del prompt."
           | rulesCount == 0
           ]
    embeddedRuleDiagnostics =
        [ mkDiagnostic (Just path) (lineForComponent locator ComponentResponseRules) 1 DiagnosticWarning "embedded-rules" "Hay reglas embebidas en `response_rules`; conviene moverlas a un bloque `rules` formal."
        | any isEmbeddedRuleText responseRuleSourceItems
        ]
    duplicateRuleDiagnostics =
        let rendered = map show (effectivePromptRules doc)
            duplicates = [value | value <- nub rendered, length (filter (== value) rendered) > 1]
        in [ mkDiagnostic (Just path) (lineForComponent locator ComponentRules) 1 DiagnosticWarning "duplicate-rules" "Hay reglas efectivas repetidas; conviene consolidarlas para evitar redundancia."
           | not (null duplicates)
           ]
    legacyRuleDiagnostics =
        [ mkDiagnostic (Just path) (lineForComponent locator ComponentRules) 1 DiagnosticWarning "legacy-rules-present" "Sigues usando `requires`, `forbids` o `mutually_exclusive`; conviene materializarlo todo en `rules`."
        | not (null (docRules doc))
            && (not (null (docRequires doc)) || not (null (docForbids doc)) || not (null (docMutuallyExclusive doc)))
        ]
    duplicateImportDiagnostics =
        let importNames = map importName (docImports doc) ++ docExtends doc
            duplicates = [name | name <- nub importNames, length (filter (== name) importNames) > 1]
        in [ mkDiagnostic (Just path) 1 1 DiagnosticWarning "duplicate-imports" "Hay imports o extends duplicados; conviene consolidarlos."
           | not (null duplicates)
           ]
    duplicateIdeaDiagnostics =
        let combined = [("instruction", value) | value <- docInstructions doc]
                ++ [("deliverable", value) | value <- docDeliverables doc]
                ++ [("quality", value) | value <- docQualityBar doc]
                ++ [("response-rule", value) | value <- docResponseRules doc]
            normalized = map (\(label, value) -> (label, normalizeSentence value)) combined
            duplicated = [label | (label, value) <- normalized, not (null value), length [() | (_, candidate) <- normalized, candidate == value] > 1]
        in [ mkDiagnostic (Just path) 1 1 DiagnosticWarning "duplicate-ideas" "Hay ideas repetidas entre instructions, deliverables, quality_bar o response_rules; conviene consolidarlas."
           | not (null duplicated)
           ]
    profileDiagnostics =
        concat
            [ [ mkDiagnostic (Just path) 1 1 DiagnosticWarning "quality-profile-missing" "Conviene declarar al menos un `quality_profile` para adaptar el lint al tipo de prompt."
              | docKind doc == FinalPrompt && null (docQualityProfiles doc)
              ]
            , [ mkDiagnostic (Just path) 1 1 DiagnosticWarning "research-missing-assumptions" "El perfil `research` deberia declarar `assumptions` para explicitar supuestos del analisis."
              | "research" `elem` profiles, null (docAssumptions doc)
              ]
            , [ mkDiagnostic (Just path) 1 1 DiagnosticWarning "research-missing-questions" "El perfil `research` deberia declarar `questions_if_missing` para gestionar informacion insuficiente."
              | "research" `elem` profiles, null (docQuestionsIfMissing doc)
              ]
            , [ mkDiagnostic (Just path) 1 1 DiagnosticWarning "engineering-missing-acceptance" "El perfil `engineering` deberia declarar `acceptance_criteria` verificables."
              | "engineering" `elem` profiles, null (docAcceptanceCriteria doc)
              ]
            , [ mkDiagnostic (Just path) 1 1 DiagnosticWarning "engineering-missing-verification" "El perfil `engineering` deberia declarar `verification_plan` para comprobar el resultado."
              | "engineering" `elem` profiles, null (docVerificationPlan doc)
              ]
            , [ mkDiagnostic (Just path) 1 1 DiagnosticWarning "security-missing-risks" "El perfil `security` deberia declarar `risks` para cubrir amenazas y tradeoffs."
              | "security" `elem` profiles, null (docRisks doc)
              ]
            , [ mkDiagnostic (Just path) 1 1 DiagnosticWarning "security-missing-antipatterns" "El perfil `security` deberia declarar `anti_patterns` para prohibiciones operativas explicitas."
              | "security" `elem` profiles, null (docAntiPatterns doc)
              ]
            ]
    exportCompletenessDiagnostics =
        let rulesLine = lineForComponent locator ComponentRules
            allRules = effectivePromptRules doc
            directMust = nub [normalizeAtom a | RuleMust a <- allRules, not (null (normalizeAtom a))]
            implications = [(normalizeAtom l, normalizeAtom r) | RuleImplies l r <- allRules, not (null (normalizeAtom l)), not (null (normalizeAtom r))]
            reachableAtoms = transitiveClosure implications directMust
        in [ mkDiagnostic (Just path) rulesLine 1 DiagnosticWarning "uncovered-export"
               ("El atomo exportado `" ++ exportAtomName e ++ "` no esta cubierto por ninguna regla `must` ni implicacion transitiva; el export puede ser silencioso.")
           | e <- docExports doc
           , normalizeAtom (exportAtomName e) `notElem` reachableAtoms
           ]
    atomCoverageDiagnostics =
        if null (docAtoms doc)
            then []
            else
                let rulesLine = lineForComponent locator ComponentRules
                    declaredNames = nub (map (normalizeAtom . atomDeclName) (docAtoms doc))
                    usedAtoms = nub (filter (not . null) (map normalizeAtom (concatMap extractRuleAtoms (effectivePromptRules doc))))
                    undeclared = filter (`notElem` declaredNames) usedAtoms
                in [ mkDiagnostic (Just path) rulesLine 1 DiagnosticWarning "undeclared-atom"
                       ("El atomo `" ++ a ++ "` se usa en `rules` pero no esta declarado en `atoms`; conviene declararlo para que el sistema conozca su tipo.")
                   | a <- undeclared
                   ]
    typeSemanticsDiagnostics = typedSemanticsDiagnostics path doc
    listDiagnostics spec values =
        let cleaned = filter (\value -> not (null (trim value)) && not (isEmbeddedRuleText value)) values
            headerLine = lineForComponent locator (qualityComponent spec)
            shortItems =
                [ mkDiagnostic (Just path) headerLine 1 DiagnosticWarning "text-too-short" ("Cada item de `" ++ qualityLabel spec ++ "` deberia ser mas especifico.")
                | any (\value -> wordCount value < qualityRecommendedWords spec) cleaned
                ]
            vagueItems =
                [ mkDiagnostic (Just path) headerLine 1 DiagnosticWarning "vague-language" ("`" ++ qualityLabel spec ++ "` contiene lenguaje vago (`etc`, `cosas`, `algo`, `stuff`, `things`).")
                | any containsVagueLanguage cleaned
                ]
            punctuationItems =
                [ mkDiagnostic (Just path) headerLine 1 DiagnosticWarning "missing-punctuation" ("Los items de `" ++ qualityLabel spec ++ "` deberian cerrar con puntuacion para mejorar claridad.")
                | any (not . hasClosingPunctuation) cleaned
                ]
        in shortItems ++ vagueItems ++ punctuationItems
    emptyListBlockDiagnostic blockName =
        [ mkDiagnostic (Just path) (fromMaybe 1 (findLineExact locator (blockName ++ " {"))) 1 DiagnosticWarning "empty-block" ("El bloque `" ++ blockName ++ "` esta vacio.")
        | sourceBlockDeclared source blockName
            && null (collectSourceListBlock source blockName)
        ]

presenceDiagnostic :: FilePath -> SourceLocator -> PromptDoc -> PromptQualitySpec -> [PromptDiagnostic]
presenceDiagnostic path locator doc spec
    | qualityRequiredForFinal spec && isFinalWithoutItems = [mkDiagnostic (Just path) (lineForComponent locator (qualityComponent spec)) 1 DiagnosticWarning "missing-structure" ("Un buen prompt final normalmente debe definir `" ++ qualityLabel spec ++ "`.")]
    | otherwise = []
  where
    isFinalWithoutItems =
        docKind doc == FinalPrompt
            && componentItemCount doc (qualityComponent spec) < qualityMinimumItems spec

sentenceQualityDiagnostics :: FilePath -> SourceLocator -> PromptComponent -> String -> Int -> Int -> String -> [PromptDiagnostic]
sentenceQualityDiagnostics path locator component codeLabel minimumWords recommendedWords value =
    catMaybes
        [ if wordCount value < minimumWords
            then Just (mkDiagnostic (Just path) (lineForComponent locator component) 1 DiagnosticWarning (codeLabel ++ "-too-short") ("El `" ++ codeLabel ++ "` es demasiado corto para ser preciso."))
            else Nothing
        , if containsVagueLanguage value
            then Just (mkDiagnostic (Just path) (lineForComponent locator component) 1 DiagnosticWarning (codeLabel ++ "-vague") ("El `" ++ codeLabel ++ "` contiene lenguaje vago; conviene hacerlo verificable y concreto."))
            else Nothing
        , if wordCount value < recommendedWords
            then Just (mkDiagnostic (Just path) (lineForComponent locator component) 1 DiagnosticWarning (codeLabel ++ "-thin") ("El `" ++ codeLabel ++ "` podria explicitar mejor restricciones, resultado esperado o criterio de exito."))
            else Nothing
        , if not (hasClosingPunctuation value)
            then Just (mkDiagnostic (Just path) (lineForComponent locator component) 1 DiagnosticWarning (codeLabel ++ "-punctuation") ("El `" ++ codeLabel ++ "` deberia cerrar con puntuacion para mejorar legibilidad."))
            else Nothing
        ]

instructionsSpec, deliverablesSpec, qualityBarSpec, responseRulesSpec :: PromptQualitySpec
instructionsSpec = PromptQualitySpec ComponentInstructions "instructions" 2 6 True
deliverablesSpec = PromptQualitySpec ComponentDeliverables "deliverables" 2 5 True
qualityBarSpec = PromptQualitySpec ComponentQualityBar "quality_bar" 1 5 True
responseRulesSpec = PromptQualitySpec ComponentResponseRules "response_rules" 1 4 True

qualityProfiles :: PromptDoc -> [String]
qualityProfiles doc = nub (map normalizeSentence (docQualityProfiles doc ++ docProfiles doc))

selectQualitySpec :: [String] -> PromptComponent -> PromptQualitySpec
selectQualitySpec profiles component
    | "research" `elem` profiles = researchSpec component
    | "security" `elem` profiles = securitySpec component
    | "engineering" `elem` profiles = engineeringSpec component
    | "concise" `elem` profiles || "quick-response" `elem` profiles = conciseSpec component
    | otherwise = defaultSpec component

selectObjectiveMinimum :: [String] -> Int
selectObjectiveMinimum profiles
    | "research" `elem` profiles = 10
    | "security" `elem` profiles = 10
    | "engineering" `elem` profiles = 9
    | "concise" `elem` profiles || "quick-response" `elem` profiles = 6
    | otherwise = 8

selectObjectiveRecommended :: [String] -> Int
selectObjectiveRecommended profiles
    | "research" `elem` profiles = 16
    | "security" `elem` profiles = 15
    | "engineering" `elem` profiles = 14
    | "concise" `elem` profiles || "quick-response" `elem` profiles = 9
    | otherwise = 12

defaultSpec, researchSpec, securitySpec, engineeringSpec, conciseSpec :: PromptComponent -> PromptQualitySpec
defaultSpec component =
    case component of
        ComponentInstructions -> instructionsSpec
        ComponentDeliverables -> deliverablesSpec
        ComponentQualityBar -> qualityBarSpec
        ComponentResponseRules -> responseRulesSpec
        other -> PromptQualitySpec other "component" 0 0 False

researchSpec component =
    case component of
        ComponentInstructions -> PromptQualitySpec component "instructions" 3 8 True
        ComponentDeliverables -> PromptQualitySpec component "deliverables" 2 7 True
        ComponentQualityBar -> PromptQualitySpec component "quality_bar" 2 7 True
        ComponentResponseRules -> PromptQualitySpec component "response_rules" 2 6 True
        other -> defaultSpec other

securitySpec component =
    case component of
        ComponentInstructions -> PromptQualitySpec component "instructions" 3 8 True
        ComponentDeliverables -> PromptQualitySpec component "deliverables" 2 6 True
        ComponentQualityBar -> PromptQualitySpec component "quality_bar" 2 7 True
        ComponentResponseRules -> PromptQualitySpec component "response_rules" 2 6 True
        other -> defaultSpec other

engineeringSpec component =
    case component of
        ComponentInstructions -> PromptQualitySpec component "instructions" 2 7 True
        ComponentDeliverables -> PromptQualitySpec component "deliverables" 2 6 True
        ComponentQualityBar -> PromptQualitySpec component "quality_bar" 2 6 True
        ComponentResponseRules -> PromptQualitySpec component "response_rules" 2 5 True
        other -> defaultSpec other

conciseSpec component =
    case component of
        ComponentInstructions -> PromptQualitySpec component "instructions" 1 4 True
        ComponentDeliverables -> PromptQualitySpec component "deliverables" 1 4 True
        ComponentQualityBar -> PromptQualitySpec component "quality_bar" 1 4 True
        ComponentResponseRules -> PromptQualitySpec component "response_rules" 1 3 True
        other -> defaultSpec other

componentItemCount :: PromptDoc -> PromptComponent -> Int
componentItemCount doc component =
    case component of
        ComponentInstructions -> length (filter (not . null . trim) (docInstructions doc))
        ComponentDeliverables -> length (filter (not . null . trim) (docDeliverables doc))
        ComponentQualityBar -> length (filter (not . null . trim) (docQualityBar doc))
        ComponentResponseRules -> length (filter (not . null . trim) (docResponseRules doc))
        ComponentRules -> length (effectivePromptRules doc)
        ComponentRole -> length (filter (not . null . trim) (docRoles doc))
        ComponentTask -> length (filter (not . null . trim) (docTasks doc))
        ComponentObjective -> maybe 0 (const 1) (docObjective doc)

data SourceLocator = SourceLocator
    { locatorLines :: [(Int, String)]
    }

makeSourceLocator :: String -> SourceLocator
makeSourceLocator source = SourceLocator (zip [1 ..] (lines source))

lineForComponent :: SourceLocator -> PromptComponent -> Int
lineForComponent locator component =
    fromMaybe 1 $
        case component of
            ComponentRole -> findLineWithPrefix locator "role "
            ComponentTask -> findLineWithPrefix locator "task "
            ComponentObjective -> findLineWithPrefix locator "objective "
            ComponentInstructions -> findLineExact locator "instructions {"
            ComponentDeliverables -> findLineExact locator "deliverables {"
            ComponentQualityBar -> findLineExact locator "quality_bar {"
            ComponentResponseRules -> findLineExact locator "response_rules {"
            ComponentRules -> findLineExact locator "rules {"

findLineExact :: SourceLocator -> String -> Maybe Int
findLineExact locator expected =
    fmap fst (findSourceLine locator (\line -> stripComment line == expected))

findLineWithPrefix :: SourceLocator -> String -> Maybe Int
findLineWithPrefix locator prefix =
    fmap fst (findSourceLine locator (\line -> prefix `isPrefixOf` stripComment line))

findSourceLine :: SourceLocator -> (String -> Bool) -> Maybe (Int, String)
findSourceLine SourceLocator {locatorLines} predicate =
    case filter (predicate . snd) locatorLines of
        match : _ -> Just match
        [] -> Nothing

containsActionVerb :: String -> Bool
containsActionVerb value =
    any (`isInfixOf` lowered) ["disena", "implementa", "analiza", "evalua", "explica", "propone", "detect", "design", "implement", "analyze", "evaluate", "explain", "propose", "verify", "valida"]
  where
    lowered = normalizeSentence value

containsVagueLanguage :: String -> Bool
containsVagueLanguage value =
    any (`isInfixOf` lowered) ["etc", "cosas", "algo", "varios", "stuff", "things", "somehow", "maybe", "mas o menos"]
  where
    lowered = normalizeSentence value

hasClosingPunctuation :: String -> Bool
hasClosingPunctuation value =
    case reverse (trim value) of
        [] -> False
        c : _ -> c `elem` (".:;!?" :: String)

wordCount :: String -> Int
wordCount = length . words . trim

normalizeSentence :: String -> String
normalizeSentence = map normalizeChar . trim
  where
    normalizeChar c
        | isAlphaNum c = toLowerCompat c
        | isSpace c = ' '
        | otherwise = ' '

toLowerCompat :: Char -> Char
toLowerCompat c
    | 'A' <= c && c <= 'Z' = toEnum (fromEnum c + 32)
    | otherwise = c

stripComment :: String -> String
stripComment = trim . takeWhile (/= '#')

collectSourceListBlock :: String -> String -> [String]
collectSourceListBlock source blockName = go False (lines source)
  where
    header = blockName ++ " {"
    go _ [] = []
    go inside (rawLine : rest)
        | stripComment rawLine == header = go True rest
        | inside && stripComment rawLine == "}" = []
        | inside =
            case trim (stripComment rawLine) of
                ('"' : xs) ->
                    case reverse xs of
                        ('"' : innerRev) -> reverse innerRev : go True rest
                        _ -> go True rest
                _ -> go True rest
        | otherwise = go False rest

sourceBlockDeclared :: String -> String -> Bool
sourceBlockDeclared source blockName =
    any ((== blockName ++ " {") . stripComment) (lines source)

isEmbeddedRuleText :: String -> Bool
isEmbeddedRuleText value =
    any (`isPrefixOf` trim value) ["must:", "forbid:", "implies:", "exclusive:", "at_least:", "at_most:", "exactly:"]

dedupeDiagnostics :: [PromptDiagnostic] -> [PromptDiagnostic]
dedupeDiagnostics = nub

groupAllDeclaredAtomsByType :: PromptDoc -> [(String, [String])]
groupAllDeclaredAtomsByType doc = groupSelectedAtomsByType doc (map atomDeclName (docAtoms doc))

groupSelectedAtomsByType :: PromptDoc -> [String] -> [(String, [String])]
groupSelectedAtomsByType doc selectedAtoms =
    let selected = nub (filter (not . null) (map normalizeAtom selectedAtoms))
        decls =
            [ (atomTypeLabel (atomDeclType decl), normalizeAtom (atomDeclName decl))
            | decl <- docAtoms doc
            , normalizeAtom (atomDeclName decl) `elem` selected
            ]
        labels = nub (map fst decls)
        groups =
            [ (label, sortOn id (nub [name | (candidateLabel, name) <- decls, candidateLabel == label]))
            | label <- labels
            ]
    in filter (not . null . snd) groups

typedSemanticsDiagnostics :: FilePath -> PromptDoc -> [PromptDiagnostic]
typedSemanticsDiagnostics path doc
    | null (docAtoms doc) = []
    | otherwise =
        concat
            [ [ mkDiagnostic (Just path) 1 1 DiagnosticWarning "must-hazard"
                  ("El atomo de tipo `hazard` `" ++ atom ++ "` aparece en `must`; normalmente un hazard deberia mitigarse o prohibirse, no exigirse.")
              | atom <- mustHazards
              ]
            , [ mkDiagnostic (Just path) 1 1 DiagnosticWarning "forbid-obligation"
                  ("El atomo de tipo `obligation` `" ++ atom ++ "` aparece en `forbid`; revisa si el contrato esta invertido.")
              | atom <- forbidObligations
              ]
            , [ mkDiagnostic (Just path) 1 1 DiagnosticWarning "contract-requires-hazard"
                  ("El contrato `requires` referencia el hazard `" ++ atom ++ "`; normalmente los hazards deberian aparecer en mitigaciones o `forbid`.")
              | atom <- contractRequiresHazards
              ]
            ]
  where
    typeMap = [(normalizeAtom (atomDeclName decl), atomDeclType decl) | decl <- docAtoms doc]
    atomTypeOf atom = lookup (normalizeAtom atom) typeMap
    mustHazards = nub [normalizeAtom atom | RuleMust atom <- effectivePromptRules doc, atomTypeOf atom == Just AtomHazard]
    forbidObligations = nub [normalizeAtom atom | RuleForbid atom <- effectivePromptRules doc, atomTypeOf atom == Just AtomObligation]
    contractRequiresHazards =
        [ normalizeAtom atom
        | ContractRequires atom <- docContractClauses doc
        , atomTypeOf atom == Just AtomHazard
        ]

-- | Compute the transitive closure of a set of nodes under a binary relation.
-- Repeatedly adds atoms reachable via one implication step until fixpoint.
transitiveClosure :: [(String, String)] -> [String] -> [String]
transitiveClosure edges = go
  where
    go current =
        let next = nub [r | (l, r) <- edges, l `elem` current, r `notElem` current]
        in if null next then current else go (current ++ next)
