module Common.PromptDSL
    ( PromptDoc (..)
    , PromptDocKind (..)
    , PromptFormat (..)
    , PromptLanguage (..)
    , PromptDepth (..)
    , ContextSource (..)
    , ContextArtifact (..)
    , NamedSection (..)
    , ImportSpec (..)
    , PromptParam (..)
    , PromptRule (..)
    , AtomType (..)
    , AtomDecl (..)
    , ExportSpec (..)
    , ContractClause (..)
    , emptyPromptDoc
    , mergePromptDocs
    , asSubprompt
    , serializePromptDoc
    , parsePromptDoc
    , validatePromptDoc
    , compilePromptDoc
    , compilePromptDocWith
    , renderPromptDoc
    , renderPromptDocAs
    , effectivePromptRules
    , effectivePromptRulesWithOrigins
    , extractRuleAtoms
    , atomTypeLabel
    , parseAtomType
    , formatLabel
    , languageLabel
    , depthLabel
    , contextSourceLabel
    ) where

import Data.Char (isAlphaNum, isSpace)
import Data.List (intercalate, nub)
import Data.Maybe (catMaybes, fromMaybe, isJust, isNothing, mapMaybe)

data PromptDocKind
    = FinalPrompt
    | SavedSubprompt
    deriving (Eq, Show, Read)

data PromptFormat
    = FormatPDSL
    | FormatXml
    | FormatMarkdown
    | FormatHybrid
    deriving (Eq, Show, Read)

data PromptLanguage
    = LangSpanish
    | LangEnglish
    deriving (Eq, Show, Read)

data PromptDepth
    = DepthPractical
    | DepthDetailed
    | DepthExhaustive
    deriving (Eq, Show, Read)

data ContextSource
    = ContextClipboard
    | ContextManual
    | ContextNone
    | ContextSaved
    deriving (Eq, Show, Read)

data ContextArtifact = ContextArtifact
    { artifactKind :: String
    , artifactSource :: ContextSource
    , artifactBody :: String
    }
    deriving (Eq, Show, Read)

data NamedSection = NamedSection
    { sectionName :: String
    , sectionBody :: String
    }
    deriving (Eq, Show, Read)

data ImportSpec = ImportSpec
    { importName :: String
    , importAlias :: Maybe String
    }
    deriving (Eq, Show, Read)

data PromptParam = PromptParam
    { paramName :: String
    , paramType :: String
    , paramRequired :: Bool
    , paramDefault :: Maybe String
    , paramDescription :: Maybe String
    }
    deriving (Eq, Show, Read)

data PromptRule
    = RuleMust String
    | RuleForbid String
    | RuleImplies String String
    | RuleExclusive [String]
    | RuleAtLeast Int [String]
    | RuleAtMost Int [String]
    | RuleExactly Int [String]
    deriving (Eq, Show, Read)

-- | Formal taxonomy for declared semantic atoms.  Every atom referenced in a
-- @rules@ block should have a declared type so the Z3 back-end and the LSP can
-- provide richer diagnostics and completions.
data AtomType
    = AtomBehavior    -- ^ Describes how the model should behave (actions/style).
    | AtomObligation  -- ^ Contractual obligations that must be fulfilled.
    | AtomHazard      -- ^ Dangerous patterns that must be avoided.
    | AtomFormat      -- ^ Output-format constraints (xml, markdown, …).
    | AtomQuality     -- ^ Quality or completeness requirements.
    deriving (Eq, Show, Read)

-- | A declared semantic atom within an @atoms {}@ block.
data AtomDecl = AtomDecl
    { atomDeclName :: String
    , atomDeclType :: AtomType
    , atomDeclDescription :: Maybe String
    }
    deriving (Eq, Show, Read)

-- | An atom name exported by a subprompt so consumers know what it provides.
data ExportSpec = ExportSpec
    { exportAtomName :: String
    }
    deriving (Eq, Show, Read)

-- | A module-level contract clause that is validated against the fully-resolved
-- document.  @ContractRequires@ asserts a @must@ rule is active; @ContractForbids@
-- asserts no @must@ rule activates the atom.
data ContractClause
    = ContractRequires String
    | ContractForbids String
    deriving (Eq, Show, Read)

data PromptDoc = PromptDoc
    { docKind :: PromptDocKind
    , docName :: String
    , docFormat :: PromptFormat
    , docLanguage :: PromptLanguage
    , docDepth :: PromptDepth
    , docImports :: [ImportSpec]
    , docExtends :: [String]
    , docProfiles :: [String]
    , docQualityProfiles :: [String]
    , docTargets :: [PromptFormat]
    , docTags :: [String]
    , docOwner :: Maybe String
    , docVersion :: Maybe String
    , docCompat :: Maybe String
    , docDeprecated :: Bool
    , docParams :: [PromptParam]
    , docRoles :: [String]
    , docTasks :: [String]
    , docObjective :: Maybe String
    , docSections :: [NamedSection]
    , docContextArtifacts :: [ContextArtifact]
    , docInstructions :: [String]
    , docDeliverables :: [String]
    , docChecklist :: [String]
    , docQualityBar :: [String]
    , docResponseRules :: [String]
    , docAssumptions :: [String]
    , docNonGoals :: [String]
    , docRisks :: [String]
    , docTradeoffs :: [String]
    , docAcceptanceCriteria :: [String]
    , docVerificationPlan :: [String]
    , docExamples :: [String]
    , docAntiPatterns :: [String]
    , docEvaluationCriteria :: [String]
    , docQuestionsIfMissing :: [String]
    , docRequires :: [String]
    , docForbids :: [String]
    , docMutuallyExclusive :: [String]
    , docRules :: [PromptRule]
    , docAtoms :: [AtomDecl]
    , docExports :: [ExportSpec]
    , docContractClauses :: [ContractClause]
    }
    deriving (Eq, Show, Read)

emptyPromptDoc :: PromptDoc
emptyPromptDoc =
    PromptDoc
        { docKind = FinalPrompt
        , docName = ""
        , docFormat = FormatPDSL
        , docLanguage = LangSpanish
        , docDepth = DepthDetailed
        , docImports = []
        , docExtends = []
        , docProfiles = []
        , docQualityProfiles = []
        , docTargets = []
        , docTags = []
        , docOwner = Nothing
        , docVersion = Nothing
        , docCompat = Nothing
        , docDeprecated = False
        , docParams = []
        , docRoles = []
        , docTasks = []
        , docObjective = Nothing
        , docSections = []
        , docContextArtifacts = []
        , docInstructions = []
        , docDeliverables = []
        , docChecklist = []
        , docQualityBar = []
        , docResponseRules = []
        , docAssumptions = []
        , docNonGoals = []
        , docRisks = []
        , docTradeoffs = []
        , docAcceptanceCriteria = []
        , docVerificationPlan = []
        , docExamples = []
        , docAntiPatterns = []
        , docEvaluationCriteria = []
        , docQuestionsIfMissing = []
        , docRequires = []
        , docForbids = []
        , docMutuallyExclusive = []
        , docRules = []
        , docAtoms = []
        , docExports = []
        , docContractClauses = []
        }

mergePromptDocs :: PromptDoc -> [PromptDoc] -> PromptDoc
mergePromptDocs root fragments = foldl mergeTwo root fragments

asSubprompt :: String -> PromptDoc -> PromptDoc
asSubprompt name doc =
    doc
        { docKind = SavedSubprompt
        , docName = name
        , docObjective = Nothing
        , docSections = objectiveHint ++ docSections doc
        , docImports = []
        , docExtends = []
        }
  where
    objectiveHint =
        case docObjective doc of
            Just value -> [NamedSection "objective_hint" value]
            Nothing -> []

serializePromptDoc :: PromptDoc -> String
serializePromptDoc doc =
    intercalate
        "\n"
        ( map renderImport (docImports doc)
            ++ blankAfter (not (null (docImports doc)))
            ++ [ "prompt " ++ renderBareOrQuoted (docName doc) ++ " {"
               , "  kind " ++ kindCode (docKind doc)
               , "  language " ++ languageCode (docLanguage doc)
               , "  depth " ++ depthCode (docDepth doc)
               ]
            ++ renderMaybeLine "owner" (docOwner doc)
            ++ renderMaybeLine "version" (docVersion doc)
            ++ renderMaybeLine "compat" (docCompat doc)
            ++ ["  deprecated " ++ boolCode (docDeprecated doc)]
            ++ renderRepeatLine "extends" (docExtends doc)
            ++ renderRepeatLine "profile" (docProfiles doc)
            ++ renderRepeatLine "quality_profile" (docQualityProfiles doc)
            ++ renderRepeatLine "tag" (docTags doc)
            ++ renderRepeatLine "role" (docRoles doc)
            ++ renderRepeatLine "task" (docTasks doc)
            ++ maybe [] (renderBlockString "objective") (docObjective doc)
            ++ concatMap renderParam (docParams doc)
            ++ concatMap renderSection (docSections doc)
            ++ concatMap renderContext (docContextArtifacts doc)
            ++ renderListBlock "targets" (map formatLabel (targetFormats doc))
            ++ renderListBlock "instructions" (docInstructions doc)
            ++ renderListBlock "deliverables" (docDeliverables doc)
            ++ renderListBlock "checklist" (docChecklist doc)
            ++ renderListBlock "quality_bar" (docQualityBar doc)
            ++ renderListBlock "response_rules" (docResponseRules doc)
            ++ renderListBlock "assumptions" (docAssumptions doc)
            ++ renderListBlock "non_goals" (docNonGoals doc)
            ++ renderListBlock "risks" (docRisks doc)
            ++ renderListBlock "tradeoffs" (docTradeoffs doc)
            ++ renderListBlock "acceptance_criteria" (docAcceptanceCriteria doc)
            ++ renderListBlock "verification_plan" (docVerificationPlan doc)
            ++ renderListBlock "examples" (docExamples doc)
            ++ renderListBlock "anti_patterns" (docAntiPatterns doc)
            ++ renderListBlock "evaluation_criteria" (docEvaluationCriteria doc)
            ++ renderListBlock "questions_if_missing" (docQuestionsIfMissing doc)
            ++ renderListBlock "requires" (docRequires doc)
            ++ renderListBlock "forbids" (docForbids doc)
            ++ renderListBlock "mutually_exclusive" (docMutuallyExclusive doc)
            ++ renderAtomsBlock (docAtoms doc)
            ++ renderExportsBlock (docExports doc)
            ++ renderContractBlock (docContractClauses doc)
            ++ renderRulesBlock (docRules doc)
            ++ ["}"]
        )
  where
    renderImport spec =
        "import "
            ++ importName spec
            ++ maybe "" (\alias -> " as " ++ alias) (importAlias spec)
    blankAfter True = [""]
    blankAfter False = []
    renderMaybeLine label value = maybe [] (\v -> ["  " ++ label ++ " " ++ show v]) value
    renderRepeatLine label values = map (\value -> "  " ++ label ++ " " ++ show value) values
    renderBlockString label body =
        [ "  " ++ label ++ " \"\"\""
        ] ++ map ("    " ++) (lines body)
            ++ [ "  \"\"\"" ]
    renderSection sectionValue =
        [ "  section " ++ show (sectionName sectionValue) ++ " \"\"\""
        ] ++ map ("    " ++) (lines (sectionBody sectionValue))
            ++ [ "  \"\"\"" ]
    renderContext artifact =
        [ "  context " ++ contextSourceLabel (artifactSource artifact) ++ " " ++ show (artifactKind artifact) ++ " \"\"\""
        ] ++ map ("    " ++) (lines (artifactBody artifact))
            ++ [ "  \"\"\"" ]
    renderParam param =
        [ "  param " ++ show (paramName param) ++ " {"
        , "    type " ++ show (paramType param)
        , "    required " ++ boolCode (paramRequired param)
        ]
            ++ maybe [] (\value -> ["    default " ++ show value]) (paramDefault param)
            ++ maybe [] (\value -> ["    description " ++ show value]) (paramDescription param)
            ++ ["  }"]
    renderListBlock _ [] = []
    renderListBlock label values =
        [ "  " ++ label ++ " {"
        ] ++ map (\value -> "    " ++ show value) values
            ++ ["  }"]
    renderRulesBlock [] = []
    renderRulesBlock values =
        [ "  rules {"
        ] ++ map (\value -> "    " ++ renderRule value) values
            ++ ["  }"]
    renderRule (RuleMust atom) = "must " ++ renderBareOrQuoted atom
    renderRule (RuleForbid atom) = "forbid " ++ renderBareOrQuoted atom
    renderRule (RuleImplies left right) = "implies " ++ renderBareOrQuoted left ++ " " ++ renderBareOrQuoted right
    renderRule (RuleExclusive atoms) = "exclusive " ++ unwords (map renderBareOrQuoted atoms)
    renderRule (RuleAtLeast amount atoms) = "at_least " ++ show amount ++ " " ++ unwords (map renderBareOrQuoted atoms)
    renderRule (RuleAtMost amount atoms) = "at_most " ++ show amount ++ " " ++ unwords (map renderBareOrQuoted atoms)
    renderRule (RuleExactly amount atoms) = "exactly " ++ show amount ++ " " ++ unwords (map renderBareOrQuoted atoms)
    renderAtomsBlock [] = []
    renderAtomsBlock decls =
        ["  atoms {"]
            ++ map renderAtomDecl decls
            ++ ["  }"]
    renderAtomDecl decl =
        "    " ++ renderBareOrQuoted (atomDeclName decl)
            ++ " : " ++ atomTypeCode (atomDeclType decl)
            ++ maybe "" (\d -> " " ++ show d) (atomDeclDescription decl)
    renderExportsBlock [] = []
    renderExportsBlock specs =
        ["  exports {"]
            ++ map (\s -> "    " ++ renderBareOrQuoted (exportAtomName s)) specs
            ++ ["  }"]
    renderContractBlock [] = []
    renderContractBlock clauses =
        ["  contract {"]
            ++ map renderContractClause clauses
            ++ ["  }"]
    renderContractClause (ContractRequires atom) = "    requires " ++ renderBareOrQuoted atom
    renderContractClause (ContractForbids atom) = "    forbids " ++ renderBareOrQuoted atom

parsePromptDoc :: String -> Either String PromptDoc
parsePromptDoc source =
    case parseHumanPromptDoc source of
        Right value -> Right value
        Left _ ->
            case [value | (value, rest) <- reads source, all isSpace rest] of
                [value] -> Right value
                [] -> parseHumanPromptDoc source
                values -> Right (last values)

compilePromptDoc :: String -> Either [String] (PromptDoc, String)
compilePromptDoc = compilePromptDocWith (\_ -> Left "No se pudo resolver el import.")

compilePromptDocWith :: (String -> Either String String) -> String -> Either [String] (PromptDoc, String)
compilePromptDocWith resolver source = do
    parsed <- firstToList (parsePromptDoc source)
    resolved <- resolveImports resolver [] parsed
    let errors = validatePromptDoc resolved
    if null errors
        then Right (resolved, renderPromptDoc resolved)
        else Left errors

validatePromptDoc :: PromptDoc -> [String]
validatePromptDoc doc =
    concat
        [ requireNonEmpty "El nombre del documento .pdsl es obligatorio." (docName doc)
        , requireList "Debe existir al menos un role." (docRoles doc)
        , requireList "Debe existir al menos un task." (docTasks doc)
        , validateObjective doc
        , requireList "Debe existir al menos una instruccion." (docInstructions doc)
        , requireList "Debe existir al menos un deliverable." (docDeliverables doc)
        , requireList "Debe existir al menos un criterio de quality bar." (docQualityBar doc)
        , requireList "Debe existir al menos una regla de respuesta." (docResponseRules doc)
        , validateSections (docSections doc)
        , validateArtifacts (docContextArtifacts doc)
        , validateParams (docParams doc)
        , validateImports (docImports doc)
        , validateContracts doc
        , validateRules (effectivePromptRules doc)
        , validateAtomCoverage doc
        , validateExportDeclarations doc
        , validateContractClauses doc
        ]
  where
    requireNonEmpty message value = if null (trim value) then [message] else []
    requireList message values = if null (filter (not . null . trim) values) then [message] else []
    validateObjective promptDoc =
        case docKind promptDoc of
            FinalPrompt ->
                if maybe True (null . trim) (docObjective promptDoc)
                    then ["Un prompt final debe incluir objective."]
                    else []
            SavedSubprompt -> []
    validateSections sections =
        let emptyNames = [ "Todas las sections deben tener nombre." | any (null . trim . sectionName) sections ]
            emptyBodies = [ "Todas las sections deben tener contenido." | any (null . trim . sectionBody) sections ]
            duplicateNames =
                let normalized = map (normalizeName . sectionName) sections
                in if length normalized /= length (nub normalized)
                    then ["No puede haber sections duplicadas en el mismo documento."]
                    else []
        in emptyNames ++ emptyBodies ++ duplicateNames
    validateArtifacts artifacts =
        concat
            [ [ "Cada context-artifact debe tener kind." | any (null . trim . artifactKind) artifacts ]
            , [ "Cada context-artifact debe tener body." | any (null . trim . artifactBody) artifacts ]
            ]
    validateParams params =
        let names = map (normalizeName . paramName) params
            duplicateNames =
                if length names /= length (nub names)
                    then ["No puede haber params duplicados."]
                    else []
            missingType =
                [ "Cada param debe tener type." | any (null . trim . paramType) params ]
        in duplicateNames ++ missingType
    validateImports imports =
        let names = map importName imports
        in if length names /= length (nub names)
            then ["No puede haber imports duplicados."]
            else []
    validateContracts promptDoc =
        [ "No repitas valores en mutually_exclusive." | length (docMutuallyExclusive promptDoc) /= length (nub (docMutuallyExclusive promptDoc)) ]
    validateRules rules =
        concat
             [ [ "Las reglas `must` deben referenciar un atomo no vacio." | any invalidMust rules ]
             , [ "Las reglas `forbid` deben referenciar un atomo no vacio." | any invalidForbid rules ]
             , [ "Las reglas `implies` deben tener origen y destino." | any invalidImplies rules ]
             , [ "Las reglas `exclusive` deben incluir dos o mas atomos." | any invalidExclusive rules ]
             , [ "Las reglas `at_least`, `at_most` y `exactly` deben incluir una cantidad valida y dos o mas atomos." | any invalidCardinality rules ]
             , [ "No puede exigirse y prohibirse el mismo atomo." | hasDirectConflicts rules ]
             ]
    invalidMust (RuleMust atom) = null (normalizeRuleAtom atom)
    invalidMust _ = False
    invalidForbid (RuleForbid atom) = null (normalizeRuleAtom atom)
    invalidForbid _ = False
    invalidImplies (RuleImplies left right) = null (normalizeRuleAtom left) || null (normalizeRuleAtom right)
    invalidImplies _ = False
    invalidExclusive (RuleExclusive atoms) = length (filter (not . null) (map normalizeRuleAtom atoms)) < 2
    invalidExclusive _ = False
    invalidCardinality (RuleAtLeast amount atoms) = invalidCount amount atoms
    invalidCardinality (RuleAtMost amount atoms) = invalidCount amount atoms
    invalidCardinality (RuleExactly amount atoms) = invalidCount amount atoms
    invalidCardinality _ = False
    invalidCount amount atoms =
        let normalized = filter (not . null) (map normalizeRuleAtom atoms)
        in amount < 0 || amount > length normalized || length normalized < 2
    hasDirectConflicts rules =
        let mustAtoms = [normalizeRuleAtom atom | RuleMust atom <- rules, not (null (normalizeRuleAtom atom))]
            forbidAtoms = [normalizeRuleAtom atom | RuleForbid atom <- rules, not (null (normalizeRuleAtom atom))]
        in any (`elem` forbidAtoms) mustAtoms
    validateAtomCoverage promptDoc =
        if null (docAtoms promptDoc)
            then []
            else
                let declaredNames = nub (map (normalizeName . atomDeclName) (docAtoms promptDoc))
                    usedAtoms = nub (filter (not . null) (concatMap extractRuleAtoms (effectivePromptRules promptDoc)))
                    undeclared = filter (`notElem` declaredNames) usedAtoms
                in map (\a -> "El atomo `" ++ a ++ "` es referenciado en `rules` pero no esta declarado en el bloque `atoms`.") undeclared
    validateExportDeclarations promptDoc =
        let declaredAtomNames = nub (map (normalizeName . atomDeclName) (docAtoms promptDoc))
            badExports =
                if null (docAtoms promptDoc)
                    then []
                    else filter (\s -> normalizeName (exportAtomName s) `notElem` declaredAtomNames) (docExports promptDoc)
        in [ "El export `" ++ exportAtomName s ++ "` referencia el atomo `" ++ normalizeName (exportAtomName s) ++ "` que no esta declarado en `atoms`."
           | s <- badExports
           ]
    validateContractClauses promptDoc =
        let mustAtoms = nub [normalizeRuleAtom a | RuleMust a <- effectivePromptRules promptDoc, not (null (normalizeRuleAtom a))]
        in concatMap (checkContractClause mustAtoms) (docContractClauses promptDoc)
    checkContractClause mustAtoms (ContractRequires atom) =
        let normalized = normalizeRuleAtom atom
        in if null normalized
            then ["Clausula `contract requires` debe especificar un atomo valido."]
            else if normalized `notElem` mustAtoms
                then ["El contrato requiere el atomo `" ++ atom ++ "` pero no esta cubierto por las reglas `must` del documento resuelto."]
                else []
    checkContractClause mustAtoms (ContractForbids atom) =
        let normalized = normalizeRuleAtom atom
        in if null normalized
            then ["Clausula `contract forbids` debe especificar un atomo valido."]
            else if normalized `elem` mustAtoms
                then ["El contrato prohibe el atomo `" ++ atom ++ "` pero esta presente en las reglas `must` del documento resuelto."]
                else []

renderPromptDoc :: PromptDoc -> String
renderPromptDoc doc = renderPromptDocAs (defaultRenderFormat doc) doc

renderPromptDocAs :: PromptFormat -> PromptDoc -> String
renderPromptDocAs target doc =
    case target of
        FormatPDSL -> serializePromptDoc doc
        FormatXml -> renderXml FormatXml doc
        FormatMarkdown -> renderMarkdown FormatMarkdown doc
        FormatHybrid -> renderXml FormatHybrid doc ++ "\n\n---\n\n" ++ renderMarkdown FormatHybrid doc

formatLabel :: PromptFormat -> String
formatLabel FormatPDSL = "pdsl"
formatLabel FormatXml = "xml"
formatLabel FormatMarkdown = "markdown"
formatLabel FormatHybrid = "hybrid"

languageLabel :: PromptLanguage -> String
languageLabel LangSpanish = "espanol"
languageLabel LangEnglish = "English"

depthLabel :: PromptDepth -> String
depthLabel DepthPractical = "practical"
depthLabel DepthDetailed = "detailed"
depthLabel DepthExhaustive = "exhaustive"

contextSourceLabel :: ContextSource -> String
contextSourceLabel ContextClipboard = "clipboard"
contextSourceLabel ContextManual = "manual"
contextSourceLabel ContextNone = "none"
contextSourceLabel ContextSaved = "saved"

mergeTwo :: PromptDoc -> PromptDoc -> PromptDoc
mergeTwo left right =
    left
        { docImports = uniqueImports (docImports left ++ docImports right)
        , docExtends = uniqueText (docExtends left ++ docExtends right)
        , docProfiles = uniqueText (docProfiles left ++ docProfiles right)
        , docQualityProfiles = uniqueText (docQualityProfiles left ++ docQualityProfiles right)
        , docTargets = uniqueFormats (docTargets left ++ docTargets right)
        , docTags = uniqueText (docTags left ++ docTags right)
        , docOwner = preferMaybe (docOwner left) (docOwner right)
        , docVersion = preferMaybe (docVersion left) (docVersion right)
        , docCompat = preferMaybe (docCompat left) (docCompat right)
        , docDeprecated = docDeprecated left || docDeprecated right
        , docParams = uniqueParams (docParams left ++ docParams right)
        , docRoles = uniqueText (docRoles left ++ docRoles right)
        , docTasks = uniqueText (docTasks left ++ docTasks right)
        , docObjective = preferMaybe (docObjective left) (docObjective right)
        , docSections = mergeSections (docSections left ++ docSections right)
        , docContextArtifacts = uniqueArtifacts (docContextArtifacts left ++ docContextArtifacts right)
        , docInstructions = uniqueText (docInstructions left ++ docInstructions right)
        , docDeliverables = uniqueText (docDeliverables left ++ docDeliverables right)
        , docChecklist = uniqueText (docChecklist left ++ docChecklist right)
        , docQualityBar = uniqueText (docQualityBar left ++ docQualityBar right)
        , docResponseRules = uniqueText (docResponseRules left ++ docResponseRules right)
        , docAssumptions = uniqueText (docAssumptions left ++ docAssumptions right)
        , docNonGoals = uniqueText (docNonGoals left ++ docNonGoals right)
        , docRisks = uniqueText (docRisks left ++ docRisks right)
        , docTradeoffs = uniqueText (docTradeoffs left ++ docTradeoffs right)
        , docAcceptanceCriteria = uniqueText (docAcceptanceCriteria left ++ docAcceptanceCriteria right)
        , docVerificationPlan = uniqueText (docVerificationPlan left ++ docVerificationPlan right)
        , docExamples = uniqueText (docExamples left ++ docExamples right)
        , docAntiPatterns = uniqueText (docAntiPatterns left ++ docAntiPatterns right)
        , docEvaluationCriteria = uniqueText (docEvaluationCriteria left ++ docEvaluationCriteria right)
        , docQuestionsIfMissing = uniqueText (docQuestionsIfMissing left ++ docQuestionsIfMissing right)
        , docRequires = uniqueText (docRequires left ++ docRequires right)
        , docForbids = uniqueText (docForbids left ++ docForbids right)
        , docMutuallyExclusive = uniqueText (docMutuallyExclusive left ++ docMutuallyExclusive right)
        , docRules = uniqueRules (docRules left ++ docRules right)
        , docAtoms = uniqueAtomDecls (docAtoms left ++ docAtoms right)
        , docExports = uniqueExports (docExports left ++ docExports right)
        , docContractClauses = nub (docContractClauses left ++ docContractClauses right)
        }

renderXml :: PromptFormat -> PromptDoc -> String
renderXml target doc =
    unlines $
        [ "<prompt version=\"4.0\" kind=\"" ++ xmlEscape (kindCode (docKind doc)) ++ "\" name=\"" ++ xmlEscape (docName doc) ++ "\">"
        , indent 1 "<metadata>"
        , xmlNode 2 "source_format" (formatLabel (docFormat doc))
        , xmlNode 2 "compiled_format" (formatLabel target)
        , xmlNode 2 "language" (languageCode (docLanguage doc))
        , xmlNode 2 "depth" (depthCode (docDepth doc))
        ]
            ++ xmlOptionalNode 2 "owner" (docOwner doc)
            ++ xmlOptionalNode 2 "version" (docVersion doc)
            ++ xmlOptionalNode 2 "compat" (docCompat doc)
            ++ [xmlNode 2 "deprecated" (boolCode (docDeprecated doc))]
            ++ xmlListBlock 2 "profiles" "profile" (docProfiles doc)
            ++ xmlListBlock 2 "quality_profiles" "quality_profile" (docQualityProfiles doc)
            ++ xmlListBlock 2 "tags" "tag" (docTags doc)
            ++ xmlListBlock 2 "targets" "target" (map formatLabel (targetFormats doc))
            ++ [indent 1 "</metadata>"]
            ++ renderXmlImports (docImports doc)
            ++ xmlListBlock 1 "roles" "role" (docRoles doc)
            ++ xmlListBlock 1 "tasks" "task" (docTasks doc)
            ++ maybe [] (\value -> [xmlNode 1 "objective" value]) (docObjective doc)
            ++ renderXmlParams (docParams doc)
            ++ renderXmlSections (docSections doc)
            ++ renderXmlContextArtifacts (docContextArtifacts doc)
            ++ renderXmlSemanticBlocks doc
            ++ ["</prompt>"]

renderMarkdown :: PromptFormat -> PromptDoc -> String
renderMarkdown target doc =
    intercalate
        "\n\n"
        ( catMaybes
            [ Just ("# " ++ docName doc)
            , Just (section "Kind" (kindCode (docKind doc)))
            , Just (section "Source format" (formatLabel (docFormat doc)))
            , Just (section "Compiled format" (formatLabel target))
            , Just (section "Language" (languageCode (docLanguage doc)))
            , Just (section "Depth" (depthCode (docDepth doc)))
            , renderSimpleList "Imports" (map renderImportLabel (docImports doc))
            , renderSimpleList "Profiles" (docProfiles doc)
            , renderSimpleList "Quality profiles" (docQualityProfiles doc)
            , renderSimpleList "Tags" (docTags doc)
            , renderSimpleList "Targets" (map formatLabel (targetFormats doc))
            , fmap (section "Owner") (docOwner doc)
            , fmap (section "Version") (docVersion doc)
            , fmap (section "Compat") (docCompat doc)
            , Just (section "Roles" (numberedList (docRoles doc)))
            , Just (section "Tasks" (numberedList (docTasks doc)))
            , fmap (section "Objective") (docObjective doc)
            , renderParamsSection (docParams doc)
            , renderSectionsSection (docSections doc)
            , renderArtifactsSection (docContextArtifacts doc)
            , renderSimpleList "Instructions" (docInstructions doc)
            , renderSimpleList "Deliverables" (docDeliverables doc)
            , renderSimpleList "Checklist" (docChecklist doc)
            , renderSimpleList "Quality bar" (docQualityBar doc)
            , renderSimpleList "Response rules" (docResponseRules doc)
            , renderSimpleList "Assumptions" (docAssumptions doc)
            , renderSimpleList "Non goals" (docNonGoals doc)
            , renderSimpleList "Risks" (docRisks doc)
            , renderSimpleList "Tradeoffs" (docTradeoffs doc)
            , renderSimpleList "Acceptance criteria" (docAcceptanceCriteria doc)
            , renderSimpleList "Verification plan" (docVerificationPlan doc)
            , renderSimpleList "Examples" (docExamples doc)
            , renderSimpleList "Anti patterns" (docAntiPatterns doc)
            , renderSimpleList "Evaluation criteria" (docEvaluationCriteria doc)
            , renderSimpleList "Questions if missing" (docQuestionsIfMissing doc)
            , renderSimpleList "Requires" (docRequires doc)
            , renderSimpleList "Forbids" (docForbids doc)
            , renderSimpleList "Mutually exclusive" (docMutuallyExclusive doc)
            , renderSimpleList "Semantic rules" (map renderPromptRuleLabel (effectivePromptRules doc))
            ]
        )
  where
    renderImportLabel spec = importName spec ++ maybe "" (\alias -> " as " ++ alias) (importAlias spec)

renderSimpleList :: String -> [String] -> Maybe String
renderSimpleList title values =
    if null cleaned then Nothing else Just (section title (numberedList cleaned))
  where
    cleaned = filter (not . null . trim) values

renderParamsSection :: [PromptParam] -> Maybe String
renderParamsSection [] = Nothing
renderParamsSection params =
    Just $
        section
            "Parameters"
            ( intercalate
                "\n\n"
                [ "### " ++ paramName param
                    ++ "\n- type: "
                    ++ paramType param
                    ++ "\n- required: "
                    ++ boolCode (paramRequired param)
                    ++ maybe "" (\value -> "\n- default: " ++ value) (paramDefault param)
                    ++ maybe "" (\value -> "\n- description: " ++ value) (paramDescription param)
                | param <- params
                ]
            )

renderSectionsSection :: [NamedSection] -> Maybe String
renderSectionsSection [] = Nothing
renderSectionsSection sections =
    Just (section "Sections" (intercalate "\n\n" (map (\value -> "### " ++ sectionName value ++ "\n" ++ sectionBody value) sections)))

renderArtifactsSection :: [ContextArtifact] -> Maybe String
renderArtifactsSection [] = Nothing
renderArtifactsSection artifacts =
    Just $
        section
            "Context artifacts"
            ( intercalate
                "\n\n"
                [ "### " ++ artifactKind artifact
                    ++ " ["
                    ++ contextSourceLabel (artifactSource artifact)
                    ++ "]\n<context>\n"
                    ++ artifactBody artifact
                    ++ "\n</context>"
                | artifact <- artifacts
                ]
            )

renderXmlImports :: [ImportSpec] -> [String]
renderXmlImports [] = []
renderXmlImports imports =
    [indent 1 "<imports>"]
        ++ concatMap renderImport imports
        ++ [indent 1 "</imports>"]
  where
    renderImport spec =
        [ indent 2 ("<import name=\"" ++ xmlEscape (importName spec) ++ "\"" ++ maybe "" (\alias -> " alias=\"" ++ xmlEscape alias ++ "\"") (importAlias spec) ++ " />")
        ]

renderXmlParams :: [PromptParam] -> [String]
renderXmlParams [] = []
renderXmlParams params =
    [indent 1 "<params>"]
        ++ concatMap renderParam params
        ++ [indent 1 "</params>"]
  where
    renderParam param =
        [ indent 2 ("<param name=\"" ++ xmlEscape (paramName param) ++ "\" type=\"" ++ xmlEscape (paramType param) ++ "\" required=\"" ++ boolCode (paramRequired param) ++ "\">")
        ]
            ++ xmlOptionalNode 3 "default" (paramDefault param)
            ++ xmlOptionalNode 3 "description" (paramDescription param)
            ++ [indent 2 "</param>"]

renderXmlSections :: [NamedSection] -> [String]
renderXmlSections [] = []
renderXmlSections sections =
    [indent 1 "<sections>"]
        ++ concatMap renderSection sections
        ++ [indent 1 "</sections>"]
  where
    renderSection sectionValue =
        [ indent 2 ("<section name=\"" ++ xmlEscape (sectionName sectionValue) ++ "\">")
        , indent 3 (xmlEscape (sectionBody sectionValue))
        , indent 2 "</section>"
        ]

renderXmlContextArtifacts :: [ContextArtifact] -> [String]
renderXmlContextArtifacts [] = []
renderXmlContextArtifacts artifacts =
    [indent 1 "<source_material>"]
        ++ concatMap renderArtifact artifacts
        ++ [indent 1 "</source_material>"]
  where
    renderArtifact artifact =
        [ indent 2 ("<artifact kind=\"" ++ xmlEscape (artifactKind artifact) ++ "\" source=\"" ++ xmlEscape (contextSourceLabel (artifactSource artifact)) ++ "\">")
        , indent 3 (xmlEscape (artifactBody artifact))
        , indent 2 "</artifact>"
        ]

renderXmlSemanticBlocks :: PromptDoc -> [String]
renderXmlSemanticBlocks doc =
    concat
        [ xmlListBlock 1 "instructions" "instruction" (docInstructions doc)
        , xmlListBlock 1 "deliverables" "deliverable" (docDeliverables doc)
        , xmlListBlock 1 "analysis_checklist" "check" (docChecklist doc)
        , xmlListBlock 1 "quality_bar" "criterion" (docQualityBar doc)
        , xmlListBlock 1 "response_contract" "rule" (docResponseRules doc)
        , xmlListBlock 1 "assumptions" "assumption" (docAssumptions doc)
        , xmlListBlock 1 "non_goals" "non_goal" (docNonGoals doc)
        , xmlListBlock 1 "risks" "risk" (docRisks doc)
        , xmlListBlock 1 "tradeoffs" "tradeoff" (docTradeoffs doc)
        , xmlListBlock 1 "acceptance_criteria" "criterion" (docAcceptanceCriteria doc)
        , xmlListBlock 1 "verification_plan" "step" (docVerificationPlan doc)
        , xmlListBlock 1 "examples" "example" (docExamples doc)
        , xmlListBlock 1 "anti_patterns" "anti_pattern" (docAntiPatterns doc)
        , xmlListBlock 1 "evaluation_criteria" "criterion" (docEvaluationCriteria doc)
        , xmlListBlock 1 "questions_if_missing" "question" (docQuestionsIfMissing doc)
        , xmlListBlock 1 "contracts_requires" "item" (docRequires doc)
        , xmlListBlock 1 "contracts_forbids" "item" (docForbids doc)
        , xmlListBlock 1 "contracts_mutually_exclusive" "item" (docMutuallyExclusive doc)
        , xmlListBlock 1 "semantic_rules" "rule" (map renderPromptRuleLabel (effectivePromptRules doc))
        ]

xmlListBlock :: Int -> String -> String -> [String] -> [String]
xmlListBlock _ _ _ [] = []
xmlListBlock indentLevel container itemTag values =
    [indent indentLevel ("<" ++ container ++ ">")]
        ++ map (\value -> xmlNode (indentLevel + 1) itemTag value) values
        ++ [indent indentLevel ("</" ++ container ++ ">")]

xmlOptionalNode :: Int -> String -> Maybe String -> [String]
xmlOptionalNode indentLevel tag value = maybe [] (\v -> [xmlNode indentLevel tag v]) value

xmlNode :: Int -> String -> String -> String
xmlNode indentLevel tag value =
    indent indentLevel ("<" ++ tag ++ ">" ++ xmlEscape value ++ "</" ++ tag ++ ">")

xmlEscape :: String -> String
xmlEscape = concatMap escapeChar
  where
    escapeChar '&' = "&amp;"
    escapeChar '<' = "&lt;"
    escapeChar '>' = "&gt;"
    escapeChar '"' = "&quot;"
    escapeChar '\'' = "&apos;"
    escapeChar c = [c]

renderPromptRuleLabel :: PromptRule -> String
renderPromptRuleLabel (RuleMust atom) = "must " ++ atom
renderPromptRuleLabel (RuleForbid atom) = "forbid " ++ atom
renderPromptRuleLabel (RuleImplies left right) = "implies " ++ left ++ " " ++ right
renderPromptRuleLabel (RuleExclusive atoms) = "exclusive " ++ unwords atoms
renderPromptRuleLabel (RuleAtLeast amount atoms) = "at_least " ++ show amount ++ " " ++ unwords atoms
renderPromptRuleLabel (RuleAtMost amount atoms) = "at_most " ++ show amount ++ " " ++ unwords atoms
renderPromptRuleLabel (RuleExactly amount atoms) = "exactly " ++ show amount ++ " " ++ unwords atoms

indent :: Int -> String -> String
indent level value = replicate (level * 2) ' ' ++ value

section :: String -> String -> String
section title body = "## " ++ title ++ "\n" ++ body

numberedList :: [String] -> String
numberedList values =
    unlines (zipWith (\index value -> show index ++ ". " ++ value) [1 :: Int ..] cleaned)
  where
    cleaned = filter (not . null . trim) values

resolveImports :: (String -> Either String String) -> [String] -> PromptDoc -> Either [String] PromptDoc
resolveImports resolver stack doc =
    foldl mergeImport (Right cleanDoc) requested
  where
    cleanDoc = doc { docImports = [], docExtends = [] }
    requested = map importName (docImports doc) ++ docExtends doc
    mergeImport acc name = do
        partial <- acc
        imported <- loadOne name
        Right (mergeTwo partial imported)
    loadOne name
        | name `elem` stack = Left ["Se detecto un ciclo de imports: " ++ intercalate " -> " (reverse (name : stack))]
        | otherwise =
            case resolver name of
                Left err -> Left ["No se pudo resolver import `" ++ name ++ "`: " ++ err]
                Right source -> do
                    imported <- firstToList (parsePromptDoc source)
                    resolveImports resolver (name : stack) imported

parseHumanPromptDoc :: String -> Either String PromptDoc
parseHumanPromptDoc source = do
    let prepared = zip [1 :: Int ..] (lines source)
    (imports, rest) <- parseImports prepared []
    parsePromptBody imports rest

parseImports :: [(Int, String)] -> [ImportSpec] -> Either String ([ImportSpec], [(Int, String)])
parseImports [] acc = Right (reverse acc, [])
parseImports (entry@(lineNo, rawLine) : rest) acc
    | null cleaned = parseImports rest acc
    | "import " `startsWith` cleaned = do
        parsed <- parseImportLine lineNo cleaned
        parseImports rest (parsed : acc)
    | otherwise = Right (reverse acc, entry : rest)
  where
    cleaned = stripComment rawLine

parsePromptBody :: [ImportSpec] -> [(Int, String)] -> Either String PromptDoc
parsePromptBody imports entries = do
    (lineNo, header, rest) <- nextMeaningful entries
    name <- parsePromptHeader lineNo header
    let base = emptyPromptDoc { docName = name, docImports = imports }
    parsePromptLines base rest

parsePromptLines :: PromptDoc -> [(Int, String)] -> Either String PromptDoc
parsePromptLines doc [] = Left "El prompt no cierra con `}`."
parsePromptLines doc entries = do
    (lineNo, line, rest) <- nextMeaningful entries
    if line == "}"
        then Right doc
        else
            case () of
                _ | "kind " `startsWith` line ->
                        case parseKind (dropWord line) of
                            Right value -> parsePromptLines (doc { docKind = value }) rest
                            Left err -> Left (atLine lineNo err)
                  | "language " `startsWith` line ->
                        case parseLanguage (dropWord line) of
                            Right value -> parsePromptLines (doc { docLanguage = value }) rest
                            Left err -> Left (atLine lineNo err)
                  | "depth " `startsWith` line ->
                        case parseDepth (dropWord line) of
                            Right value -> parsePromptLines (doc { docDepth = value }) rest
                            Left err -> Left (atLine lineNo err)
                  | "deprecated " `startsWith` line ->
                        case parseStrictBool "deprecated" (dropWord line) of
                            Right value -> parsePromptLines (doc { docDeprecated = value }) rest
                            Left err -> Left (atLine lineNo err)
                  | "owner " `startsWith` line ->
                        case parseSingleString lineNo line of
                            Right value -> parsePromptLines (doc { docOwner = Just value }) rest
                            Left err -> Left err
                  | "version " `startsWith` line ->
                        case parseSingleString lineNo line of
                            Right value -> parsePromptLines (doc { docVersion = Just value }) rest
                            Left err -> Left err
                  | "compat " `startsWith` line ->
                        case parseSingleString lineNo line of
                            Right value -> parsePromptLines (doc { docCompat = Just value }) rest
                            Left err -> Left err
                  | "extends " `startsWith` line ->
                        case consumeString (dropWord line) of
                            Right (value, trailing) | null (trim trailing) ->
                                parsePromptLines (doc { docExtends = docExtends doc ++ [value] }) rest
                            Right _ -> Left (atLine lineNo "La clausula `extends` solo acepta un nombre de prompt.")
                            Left err -> Left (atLine lineNo err)
                  | "profile " `startsWith` line ->
                        appendStringField lineNo line doc docProfiles (\value prompt -> prompt { docProfiles = docProfiles prompt ++ [value] }) rest
                  | "quality_profile " `startsWith` line ->
                        appendStringField lineNo line doc docQualityProfiles (\value prompt -> prompt { docQualityProfiles = docQualityProfiles prompt ++ [value] }) rest
                  | "tag " `startsWith` line ->
                        appendStringField lineNo line doc docTags (\value prompt -> prompt { docTags = docTags prompt ++ [value] }) rest
                  | "role " `startsWith` line ->
                        appendStringField lineNo line doc docRoles (\value prompt -> prompt { docRoles = docRoles prompt ++ [value] }) rest
                  | "task " `startsWith` line ->
                        appendStringField lineNo line doc docTasks (\value prompt -> prompt { docTasks = docTasks prompt ++ [value] }) rest
                  | "objective " `startsWith` line -> do
                        (value, remaining) <- parseMultilineString lineNo line rest
                        parsePromptLines (doc { docObjective = Just value }) remaining
                  | "section " `startsWith` line -> do
                        (sectionValue, remaining) <- parseSection lineNo line rest
                        parsePromptLines (doc { docSections = docSections doc ++ [sectionValue] }) remaining
                  | "context " `startsWith` line -> do
                        (artifact, remaining) <- parseContext lineNo line rest
                        parsePromptLines (doc { docContextArtifacts = docContextArtifacts doc ++ [artifact] }) remaining
                  | "param " `startsWith` line -> do
                        (paramValue, remaining) <- parseParam lineNo line rest
                        parsePromptLines (doc { docParams = docParams doc ++ [paramValue] }) remaining
                  | line == "targets {" -> parseFormatBlock lineNo doc rest
                  | line == "instructions {" -> parseStringBlock lineNo "instructions" (\values prompt -> prompt { docInstructions = values }) doc rest
                  | line == "deliverables {" -> parseStringBlock lineNo "deliverables" (\values prompt -> prompt { docDeliverables = values }) doc rest
                  | line == "checklist {" -> parseStringBlock lineNo "checklist" (\values prompt -> prompt { docChecklist = values }) doc rest
                  | line == "quality_bar {" -> parseStringBlock lineNo "quality_bar" (\values prompt -> prompt { docQualityBar = values }) doc rest
                  | line == "response_rules {" -> parseStringBlock lineNo "response_rules" (\values prompt -> prompt { docResponseRules = values }) doc rest
                  | line == "assumptions {" -> parseStringBlock lineNo "assumptions" (\values prompt -> prompt { docAssumptions = values }) doc rest
                  | line == "non_goals {" -> parseStringBlock lineNo "non_goals" (\values prompt -> prompt { docNonGoals = values }) doc rest
                  | line == "risks {" -> parseStringBlock lineNo "risks" (\values prompt -> prompt { docRisks = values }) doc rest
                  | line == "tradeoffs {" -> parseStringBlock lineNo "tradeoffs" (\values prompt -> prompt { docTradeoffs = values }) doc rest
                  | line == "acceptance_criteria {" -> parseStringBlock lineNo "acceptance_criteria" (\values prompt -> prompt { docAcceptanceCriteria = values }) doc rest
                  | line == "verification_plan {" -> parseStringBlock lineNo "verification_plan" (\values prompt -> prompt { docVerificationPlan = values }) doc rest
                  | line == "examples {" -> parseStringBlock lineNo "examples" (\values prompt -> prompt { docExamples = values }) doc rest
                  | line == "anti_patterns {" -> parseStringBlock lineNo "anti_patterns" (\values prompt -> prompt { docAntiPatterns = values }) doc rest
                  | line == "evaluation_criteria {" -> parseStringBlock lineNo "evaluation_criteria" (\values prompt -> prompt { docEvaluationCriteria = values }) doc rest
                  | line == "questions_if_missing {" -> parseStringBlock lineNo "questions_if_missing" (\values prompt -> prompt { docQuestionsIfMissing = values }) doc rest
                  | line == "requires {" -> parseStringBlock lineNo "requires" (\values prompt -> prompt { docRequires = values }) doc rest
                  | line == "forbids {" -> parseStringBlock lineNo "forbids" (\values prompt -> prompt { docForbids = values }) doc rest
                  | line == "mutually_exclusive {" -> parseStringBlock lineNo "mutually_exclusive" (\values prompt -> prompt { docMutuallyExclusive = values }) doc rest
                  | line == "rules {" -> parseRulesBlock lineNo doc rest
                  | line == "atoms {" -> parseAtomsBlock lineNo doc rest
                  | line == "exports {" -> parseExportsBlock lineNo doc rest
                  | line == "contract {" -> parseContractBlock lineNo doc rest
                  | otherwise -> Left (atLine lineNo ("Sentencia PDSL no reconocida: " ++ line))

parseFormatBlock :: Int -> PromptDoc -> [(Int, String)] -> Either String PromptDoc
parseFormatBlock lineNo doc rest = do
    (values, remaining) <- collectStringBlockValues lineNo rest
    parsed <- mapM parseFormatValue values
    parsePromptLines (doc { docTargets = parsed }) remaining
  where
    parseFormatValue (valueLineNo, value) =
        case parseFormat value of
            Right parsed -> Right parsed
            Left err -> Left (atLine valueLineNo err)

parseStringBlock :: Int -> String -> ([String] -> PromptDoc -> PromptDoc) -> PromptDoc -> [(Int, String)] -> Either String PromptDoc
parseStringBlock lineNo _ setter doc rest = do
    (values, remaining) <- collectStringBlockValues lineNo rest
    parsePromptLines (setter (map snd values) doc) remaining

parseRulesBlock :: Int -> PromptDoc -> [(Int, String)] -> Either String PromptDoc
parseRulesBlock lineNo doc rest = do
    (values, remaining) <- collectBlockEntries lineNo rest
    parsed <- mapM (uncurry parseRuleLine) values
    parsePromptLines (doc { docRules = docRules doc ++ parsed }) remaining

parseAtomsBlock :: Int -> PromptDoc -> [(Int, String)] -> Either String PromptDoc
parseAtomsBlock lineNo doc rest = do
    (values, remaining) <- collectBlockEntries lineNo rest
    parsed <- mapM (uncurry parseAtomDeclLine) values
    parsePromptLines (doc { docAtoms = docAtoms doc ++ parsed }) remaining

parseAtomDeclLine :: Int -> String -> Either String AtomDecl
parseAtomDeclLine lineNo line = do
    (nameValue, afterName) <- consumeString line
    let afterNameTrimmed = trim afterName
    if not (":" `startsWith` afterNameTrimmed)
        then Left (atLine lineNo "Se esperaba `:` despues del nombre del atomo.")
        else do
            let afterColon = trim (drop 1 afterNameTrimmed)
                typeToken = takeWhile (not . isSpace) afterColon
                afterType = trim (drop (length typeToken) afterColon)
            parsedType <- case parseAtomType typeToken of
                Right t -> Right t
                Left err -> Left (atLine lineNo err)
            description <- if null afterType
                then Right Nothing
                else case consumeString afterType of
                    Right (desc, trailing) | null (trim trailing) -> Right (Just desc)
                    _ -> Left (atLine lineNo "Descripcion de atomo invalida; usa una cadena entre comillas.")
            Right (AtomDecl nameValue parsedType description)

parseExportsBlock :: Int -> PromptDoc -> [(Int, String)] -> Either String PromptDoc
parseExportsBlock lineNo doc rest = do
    (values, remaining) <- collectBlockEntries lineNo rest
    parsed <- mapM (uncurry parseExportLine) values
    parsePromptLines (doc { docExports = docExports doc ++ parsed }) remaining

parseExportLine :: Int -> String -> Either String ExportSpec
parseExportLine lineNo line = do
    (name, trailing) <- consumeString line
    if null (trim trailing)
        then Right (ExportSpec name)
        else Left (atLine lineNo "Linea de exports invalida; usa un nombre de atomo por linea.")

parseContractBlock :: Int -> PromptDoc -> [(Int, String)] -> Either String PromptDoc
parseContractBlock lineNo doc rest = do
    (values, remaining) <- collectBlockEntries lineNo rest
    parsed <- mapM (uncurry parseContractClauseLine) values
    parsePromptLines (doc { docContractClauses = docContractClauses doc ++ parsed }) remaining

parseContractClauseLine :: Int -> String -> Either String ContractClause
parseContractClauseLine lineNo line =
    case () of
        _
            | "requires " `startsWith` line -> do
                (atom, trailing) <- consumeString (dropWord line)
                if null (trim trailing)
                    then Right (ContractRequires atom)
                    else Left (atLine lineNo "La clausula `requires` espera exactamente un atomo.")
            | "forbids " `startsWith` line -> do
                (atom, trailing) <- consumeString (dropWord line)
                if null (trim trailing)
                    then Right (ContractForbids atom)
                    else Left (atLine lineNo "La clausula `forbids` espera exactamente un atomo.")
            | otherwise ->
                Left (atLine lineNo "Clausula de contract invalida. Usa `requires` o `forbids`.")

collectBlockEntries :: Int -> [(Int, String)] -> Either String ([(Int, String)], [(Int, String)])
collectBlockEntries openerLine = go []
  where
    go acc [] = Left (atLine openerLine "Bloque sin cerrar.")
    go acc ((lineNo, rawLine) : rest) =
        let line = stripComment rawLine
        in if null line
            then go acc rest
            else if line == "}"
                then Right (reverse acc, rest)
                else go ((lineNo, line) : acc) rest

collectStringBlockValues :: Int -> [(Int, String)] -> Either String ([(Int, String)], [(Int, String)])
collectStringBlockValues openerLine rest = do
    (values, remaining) <- collectBlockEntries openerLine rest
    parsed <- mapM parseStringEntry values
    Right (parsed, remaining)
  where
    parseStringEntry (lineNo, line) =
        case parseQuotedStringValue line of
            Right value -> Right (lineNo, value)
            Left err -> Left (atLine lineNo err)

parseSection :: Int -> String -> [(Int, String)] -> Either String (NamedSection, [(Int, String)])
parseSection lineNo line rest = do
    (nameValue, remainingInput) <- consumeString (dropWord line)
    ensureTripleStart lineNo remainingInput
    (body, remaining) <- collectTripleString lineNo rest
    Right (NamedSection nameValue body, remaining)

parseContext :: Int -> String -> [(Int, String)] -> Either String (ContextArtifact, [(Int, String)])
parseContext lineNo line rest = do
    let remainder = dropWord line
        sourceToken = takeWhile (not . isSpace) remainder
        afterSource = trim (drop (length sourceToken) remainder)
    sourceValue <- case parseContextSource sourceToken of
        Right value -> Right value
        Left err -> Left (atLine lineNo err)
    (kindValue, remainingInput) <- consumeString afterSource
    ensureTripleStart lineNo remainingInput
    (body, remaining) <- collectTripleString lineNo rest
    Right (ContextArtifact kindValue sourceValue body, remaining)

parseParam :: Int -> String -> [(Int, String)] -> Either String (PromptParam, [(Int, String)])
parseParam lineNo line rest = do
    (nameValue, remainingInput) <- consumeString (dropWord line)
    if trim remainingInput /= "{"
        then Left (atLine lineNo "Se esperaba `{` despues de param.")
        else go (PromptParam nameValue "" False Nothing Nothing) rest
  where
    go param [] = Left (atLine lineNo "Param sin cerrar.")
    go param ((innerLineNo, rawLine) : remaining) =
        let inner = stripComment rawLine
        in if null inner
            then go param remaining
            else if inner == "}"
                then Right (param, remaining)
                else
                    case () of
                        _ | "type " `startsWith` inner ->
                                case parseSingleString innerLineNo inner of
                                    Right value -> go (param { paramType = value }) remaining
                                    Left err -> Left err
                          | "required " `startsWith` inner ->
                                case parseStrictBool "required" (dropWord inner) of
                                    Right value -> go (param { paramRequired = value }) remaining
                                    Left err -> Left (atLine innerLineNo err)
                          | "default " `startsWith` inner ->
                                case parseSingleString innerLineNo inner of
                                    Right value -> go (param { paramDefault = Just value }) remaining
                                    Left err -> Left err
                          | "description " `startsWith` inner ->
                                case parseSingleString innerLineNo inner of
                                    Right value -> go (param { paramDescription = Just value }) remaining
                                    Left err -> Left err
                          | otherwise -> Left (atLine innerLineNo ("Linea invalida dentro de param: " ++ inner))

parseImportLine :: Int -> String -> Either String ImportSpec
parseImportLine lineNo line =
    case words line of
        ["import", name] -> Right (ImportSpec name Nothing)
        ["import", name, "as", alias] -> Right (ImportSpec name (Just alias))
        _ -> Left (atLine lineNo ("Import invalido: " ++ line))

parseRuleLine :: Int -> String -> Either String PromptRule
parseRuleLine lineNo line =
    case () of
        _
            | "must " `startsWith` line ->
                parseSingleRuleAtomText lineNo "must" (dropWord line) RuleMust
            | "forbid " `startsWith` line ->
                parseSingleRuleAtomText lineNo "forbid" (dropWord line) RuleForbid
            | "implies " `startsWith` line -> do
                (leftAtom, rest) <- consumeString (dropWord line)
                (rightAtom, finalRest) <- consumeString rest
                if null (trim finalRest)
                    then Right (RuleImplies leftAtom rightAtom)
                    else Left (atLine lineNo "La regla `implies` requiere exactamente dos atomos.")
            | "exclusive " `startsWith` line -> do
                atoms <- collectRuleAtoms (dropWord line)
                if length atoms < 2
                    then Left (atLine lineNo "La regla `exclusive` requiere dos o mas atomos.")
                    else Right (RuleExclusive atoms)
            | "at_least " `startsWith` line ->
                parseCardinalityRule lineNo "at_least" (dropWord line) RuleAtLeast
            | "at_most " `startsWith` line ->
                parseCardinalityRule lineNo "at_most" (dropWord line) RuleAtMost
            | "exactly " `startsWith` line ->
                parseCardinalityRule lineNo "exactly" (dropWord line) RuleExactly
            | otherwise ->
                Left
                    ( atLine
                        lineNo
                        "Regla invalida. Usa `must`, `forbid`, `implies`, `exclusive`, `at_least`, `at_most` o `exactly`."
                    )

parseSingleRuleAtomText :: Int -> String -> String -> (String -> PromptRule) -> Either String PromptRule
parseSingleRuleAtomText lineNo keyword input constructor = do
    (atom, rest) <- consumeString input
    if null (trim rest)
        then Right (constructor atom)
        else Left (atLine lineNo ("La regla `" ++ keyword ++ "` requiere exactamente un atomo."))

parseCardinalityRule :: Int -> String -> String -> (Int -> [String] -> PromptRule) -> Either String PromptRule
parseCardinalityRule lineNo keyword input constructor = do
    let amountToken = takeWhile (not . isSpace) (trim input)
        remaining = trim (drop (length amountToken) (trim input))
    amount <-
        case reads amountToken of
            [(value, "")] -> Right value
            _ -> Left (atLine lineNo ("La regla `" ++ keyword ++ "` requiere una cantidad entera valida."))
    atoms <- collectRuleAtoms remaining
    if length atoms < 2
        then Left (atLine lineNo ("La regla `" ++ keyword ++ "` requiere dos o mas atomos."))
        else Right (constructor amount atoms)

collectRuleAtoms :: String -> Either String [String]
collectRuleAtoms input
    | null (trim input) = Right []
    | otherwise = do
        (atom, rest) <- consumeString input
        remaining <- collectRuleAtoms rest
        Right (atom : remaining)

parsePromptHeader :: Int -> String -> Either String String
parsePromptHeader lineNo line =
    if not ("prompt " `startsWith` line) || not ("{" `isSuffixOfTrimmed` line)
        then Left (atLine lineNo "Se esperaba `prompt <name> {`.")
        else do
            let withoutOpen = trim (dropLastChar (trim line))
            case consumeString (dropWord withoutOpen) of
                Right (value, rest)
                    | null (trim rest) -> Right value
                    | otherwise -> Left (atLine lineNo "Cabecera prompt invalida.")
                Left err -> Left (atLine lineNo err)

parseSingleString :: Int -> String -> Either String String
parseSingleString lineNo line =
    case consumeString (dropWord line) of
        Right (value, rest)
            | null (trim rest) -> Right value
            | otherwise -> Left (atLine lineNo ("Sobra texto despues del string: " ++ rest))
        Left err -> Left (atLine lineNo err)

parseMultilineString :: Int -> String -> [(Int, String)] -> Either String (String, [(Int, String)])
parseMultilineString lineNo line rest = do
    ensureTripleStart lineNo (dropWord line)
    collectTripleString lineNo rest

collectTripleString :: Int -> [(Int, String)] -> Either String (String, [(Int, String)])
collectTripleString openerLine = go []
  where
    go acc [] = Left (atLine openerLine "Bloque multilinea sin cerrar.")
    go acc ((_, rawLine) : rest)
        | trim rawLine == "\"\"\"" = Right (trimTrailingBlankLines (intercalate "\n" (reverse acc)), rest)
        | otherwise = go (dropLeadingFour rawLine : acc) rest

nextMeaningful :: [(Int, String)] -> Either String (Int, String, [(Int, String)])
nextMeaningful [] = Left "No se encontro contenido PDSL."
nextMeaningful ((lineNo, rawLine) : rest) =
    let line = stripComment rawLine
    in if null line
        then nextMeaningful rest
        else Right (lineNo, line, rest)

consumeString :: String -> Either String (String, String)
consumeString input =
    case reads (trim input) of
        [(value, rest)] -> Right (value, rest)
        _ ->
            let bare = takeWhile (\c -> not (isSpace c) && c /= '{') (trim input)
                rest = drop (length bare) (trim input)
            in if null bare
                then Left "Se esperaba un string o identificador."
                else Right (bare, rest)

parseQuotedStringValue :: String -> Either String String
parseQuotedStringValue line =
    case reads (trim line) of
        [(value, rest)] | null (trim rest) -> Right value
        _ -> Left "Los bloques de strings solo aceptan valores entre comillas."

ensureTripleStart :: Int -> String -> Either String ()
ensureTripleStart lineNo value =
    if trim value == "\"\"\""
        then Right ()
        else Left (atLine lineNo "Se esperaba apertura de bloque multilinea con `\"\"\"`.")

dropWord :: String -> String
dropWord value = trim (dropWhile (not . isSpace) value)

stripComment :: String -> String
stripComment = trim . takeWhile (/= '#')

renderBareOrQuoted :: String -> String
renderBareOrQuoted value =
    if all isBareChar value && not (null value)
        then value
        else show value

isBareChar :: Char -> Bool
isBareChar c = isAlphaNum c || c == '_' || c == '-' || c == '.'

startsWith :: String -> String -> Bool
startsWith prefix value = prefix == take (length prefix) value

isSuffixOfTrimmed :: String -> String -> Bool
isSuffixOfTrimmed suffix value = suffix == reverse (take (length suffix) (reverse (trim value)))

dropLastChar :: String -> String
dropLastChar [] = []
dropLastChar value = take (length value - 1) value

dropLeadingFour :: String -> String
dropLeadingFour value =
    case value of
        ' ' : ' ' : ' ' : ' ' : rest -> rest
        _ -> value

trimTrailingBlankLines :: String -> String
trimTrailingBlankLines = intercalate "\n" . reverse . dropWhile (null . trim) . reverse . lines

parseStrictBool :: String -> String -> Either String Bool
parseStrictBool fieldName value =
    case trim value of
        "true" -> Right True
        "false" -> Right False
        other -> Left ("`" ++ fieldName ++ "` solo acepta `true` o `false`, no `" ++ other ++ "`.")

parseKind :: String -> Either String PromptDocKind
parseKind "final" = Right FinalPrompt
parseKind "subprompt" = Right SavedSubprompt
parseKind value = Left ("Kind .pdsl desconocido: " ++ value)

parseFormat :: String -> Either String PromptFormat
parseFormat "pdsl" = Right FormatPDSL
parseFormat "xml" = Right FormatXml
parseFormat "markdown" = Right FormatMarkdown
parseFormat "hybrid" = Right FormatHybrid
parseFormat value = Left ("Formato .pdsl desconocido: " ++ value)

parseLanguage :: String -> Either String PromptLanguage
parseLanguage "es" = Right LangSpanish
parseLanguage "en" = Right LangEnglish
parseLanguage value = Left ("Idioma .pdsl desconocido: " ++ value)

parseDepth :: String -> Either String PromptDepth
parseDepth "practical" = Right DepthPractical
parseDepth "detailed" = Right DepthDetailed
parseDepth "exhaustive" = Right DepthExhaustive
parseDepth value = Left ("Depth .pdsl desconocido: " ++ value)

parseContextSource :: String -> Either String ContextSource
parseContextSource "clipboard" = Right ContextClipboard
parseContextSource "manual" = Right ContextManual
parseContextSource "none" = Right ContextNone
parseContextSource "saved" = Right ContextSaved
parseContextSource value = Left ("Context source .pdsl desconocido: " ++ value)

defaultRenderFormat :: PromptDoc -> PromptFormat
defaultRenderFormat doc =
    case targetFormats doc of
        (target : _) -> target
        [] -> FormatXml

targetFormats :: PromptDoc -> [PromptFormat]
targetFormats doc =
    case docTargets doc of
        [] -> [FormatXml]
        values -> filter (/= FormatPDSL) values

effectivePromptRules :: PromptDoc -> [PromptRule]
effectivePromptRules = map snd . effectivePromptRulesWithOrigins

effectivePromptRulesWithOrigins :: PromptDoc -> [(String, PromptRule)]
effectivePromptRulesWithOrigins doc =
    uniqueRuleOrigins
        ( map (\rule -> ("rules", rule)) (docRules doc)
            ++ map (\atom -> ("requires", RuleMust atom)) (docRequires doc)
            ++ map (\atom -> ("forbids", RuleForbid atom)) (docForbids doc)
            ++ legacyExclusive
            ++ embeddedRules "instructions" (docInstructions doc)
            ++ embeddedRules "quality_bar" (docQualityBar doc)
            ++ embeddedRules "response_rules" (docResponseRules doc)
        )
  where
    legacyExclusive =
        case uniqueText (docMutuallyExclusive doc) of
            [] -> []
            [_] -> []
            values -> [("mutually_exclusive", RuleExclusive values)]
    embeddedRules origin =
        mapMaybe (\value -> fmap (\rule -> (origin, rule)) (parseEmbeddedRule value))

kindCode :: PromptDocKind -> String
kindCode FinalPrompt = "final"
kindCode SavedSubprompt = "subprompt"

languageCode :: PromptLanguage -> String
languageCode LangSpanish = "es"
languageCode LangEnglish = "en"

depthCode :: PromptDepth -> String
depthCode DepthPractical = "practical"
depthCode DepthDetailed = "detailed"
depthCode DepthExhaustive = "exhaustive"

boolCode :: Bool -> String
boolCode True = "true"
boolCode False = "false"

mergeSections :: [NamedSection] -> [NamedSection]
mergeSections sections = map toSection grouped
  where
    grouped = foldl addSection [] sections
    addSection [] sectionValue = [(normalizeName (sectionName sectionValue), [sectionValue])]
    addSection ((nameKey, values) : rest) sectionValue
        | nameKey == normalizeName (sectionName sectionValue) = (nameKey, values ++ [sectionValue]) : rest
        | otherwise = (nameKey, values) : addSection rest sectionValue
    toSection (_, values@(firstSection : _)) =
        NamedSection
            { sectionName = sectionName firstSection
            , sectionBody = intercalate "\n\n" (uniqueText (map sectionBody values))
            }
    toSection (_, []) = NamedSection "" ""

uniqueImports :: [ImportSpec] -> [ImportSpec]
uniqueImports = nub

uniqueParams :: [PromptParam] -> [PromptParam]
uniqueParams = foldl addParam []
  where
    addParam acc param =
        if normalizeName (paramName param) `elem` map (normalizeName . paramName) acc
            then acc
            else acc ++ [param]

uniqueArtifacts :: [ContextArtifact] -> [ContextArtifact]
uniqueArtifacts = nub

uniqueFormats :: [PromptFormat] -> [PromptFormat]
uniqueFormats = nub

uniqueRules :: [PromptRule] -> [PromptRule]
uniqueRules = nub

uniqueRuleOrigins :: [(String, PromptRule)] -> [(String, PromptRule)]
uniqueRuleOrigins = foldl addRule []
  where
    addRule acc candidate@(_, rule)
        | any ((== rule) . snd) acc = acc
        | otherwise = acc ++ [candidate]

uniqueText :: [String] -> [String]
uniqueText = nub . filter (not . null . trim)

preferMaybe :: Maybe String -> Maybe String -> Maybe String
preferMaybe left right = if isJust left then left else right

normalizeName :: String -> String
normalizeName = map normalizeChar . trim
  where
    normalizeChar c
        | isAlphaNum c = c
        | otherwise = '-'

normalizeRuleAtom :: String -> String
normalizeRuleAtom = normalizeName

parseEmbeddedRule :: String -> Maybe PromptRule
parseEmbeddedRule rawValue =
    case words (trim rawValue) of
        ("must:" : [atom]) -> Just (RuleMust atom)
        ("forbid:" : [atom]) -> Just (RuleForbid atom)
        ("implies:" : [leftAtom, "->", rightAtom]) -> Just (RuleImplies leftAtom rightAtom)
        ("exclusive:" : atoms) | length atoms >= 2 -> Just (RuleExclusive atoms)
        ("at_least:" : amount : atoms) | length atoms >= 2 -> RuleAtLeast <$> readMaybeInt amount <*> pure atoms
        ("at_most:" : amount : atoms) | length atoms >= 2 -> RuleAtMost <$> readMaybeInt amount <*> pure atoms
        ("exactly:" : amount : atoms) | length atoms >= 2 -> RuleExactly <$> readMaybeInt amount <*> pure atoms
        _ -> Nothing

readMaybeInt :: String -> Maybe Int
readMaybeInt value =
    case reads value of
        [(parsed, "")] -> Just parsed
        _ -> Nothing

trim :: String -> String
trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace

appendStringField :: Int -> String -> PromptDoc -> (PromptDoc -> [String]) -> (String -> PromptDoc -> PromptDoc) -> [(Int, String)] -> Either String PromptDoc
appendStringField lineNo line doc _ setter rest =
    case parseSingleString lineNo line of
        Right value -> parsePromptLines (setter value doc) rest
        Left err -> Left err

atLine :: Int -> String -> String
atLine lineNo message = "line " ++ show lineNo ++ ": " ++ message

firstToList :: Either String a -> Either [String] a
firstToList (Left err) = Left [err]
firstToList (Right value) = Right value

-- | All atom names referenced by a rule (normalized).
extractRuleAtoms :: PromptRule -> [String]
extractRuleAtoms (RuleMust a) = [normalizeRuleAtom a]
extractRuleAtoms (RuleForbid a) = [normalizeRuleAtom a]
extractRuleAtoms (RuleImplies a b) = [normalizeRuleAtom a, normalizeRuleAtom b]
extractRuleAtoms (RuleExclusive as) = map normalizeRuleAtom as
extractRuleAtoms (RuleAtLeast _ as) = map normalizeRuleAtom as
extractRuleAtoms (RuleAtMost _ as) = map normalizeRuleAtom as
extractRuleAtoms (RuleExactly _ as) = map normalizeRuleAtom as

atomTypeCode :: AtomType -> String
atomTypeCode AtomBehavior = "behavior"
atomTypeCode AtomObligation = "obligation"
atomTypeCode AtomHazard = "hazard"
atomTypeCode AtomFormat = "format"
atomTypeCode AtomQuality = "quality"

atomTypeLabel :: AtomType -> String
atomTypeLabel = atomTypeCode

parseAtomType :: String -> Either String AtomType
parseAtomType "behavior" = Right AtomBehavior
parseAtomType "obligation" = Right AtomObligation
parseAtomType "hazard" = Right AtomHazard
parseAtomType "format" = Right AtomFormat
parseAtomType "quality" = Right AtomQuality
parseAtomType value = Left ("Tipo de atomo desconocido: `" ++ value ++ "`. Usa behavior, obligation, hazard, format o quality.")

uniqueAtomDecls :: [AtomDecl] -> [AtomDecl]
uniqueAtomDecls = foldl addDecl []
  where
    addDecl acc decl =
        if normalizeName (atomDeclName decl) `elem` map (normalizeName . atomDeclName) acc
            then acc
            else acc ++ [decl]

uniqueExports :: [ExportSpec] -> [ExportSpec]
uniqueExports = foldl addExport []
  where
    addExport acc spec =
        if exportAtomName spec `elem` map exportAtomName acc
            then acc
            else acc ++ [spec]
