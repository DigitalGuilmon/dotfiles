#!/usr/bin/env sh
#if 0
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
script_root="$script_dir"
while [ ! -d "$script_root/lib" ] && [ "$script_root" != "/" ]; do
    script_root=$(dirname "$script_root")
done
exec runhaskell -XCPP -i"$script_root/lib" "$0" "$@"
#endif

import Data.List (intercalate)
import System.Environment (getArgs)
import System.Exit (exitFailure, exitSuccess)

import Common.PromptDSL (PromptDoc (..), effectivePromptRulesWithOrigins, renderPromptDocAs, PromptFormat (..))
import Common.PromptDSLTooling (analyzePromptSMT, formatDiagnostic, lintPromptFile, renderSolverReportLines, renderTokenReportLines, resolvePromptDocFromFile, tokenReportForPrompt)

main :: IO ()
main = do
    args <- getArgs
    case args of
        [path] -> explainFile path
        _ -> do
            putStrLn "stdin:1:1: error: uso esperado: pdsl_explain.hs <archivo.pdsl>"
            exitFailure

explainFile :: FilePath -> IO ()
explainFile path = do
    resolved <- resolvePromptDocFromFile path
    diagnostics <- lintPromptFile path
    case resolved of
        Left errors -> mapM_ (putStrLn . formatDiagnostic) errors >> exitFailure
        Right doc -> do
            source <- readFile path
            solverReport <- analyzePromptSMT path doc
            let tokenReport = tokenReportForPrompt source doc
            putStrLn ("name: " ++ docName doc)
            putStrLn ("kind: " ++ show (docKind doc))
            putStrLn ("imports: " ++ intercalate ", " (map show (docImports doc)))
            putStrLn ("quality-profiles: " ++ intercalate ", " (docQualityProfiles doc))
            putStrLn ("targets: " ++ intercalate ", " (map show (docTargets doc)))
            putStrLn "effective-rules:"
            mapM_ (\(origin, rule) -> putStrLn ("  - [" ++ origin ++ "] " ++ show rule)) (effectivePromptRulesWithOrigins doc)
            putStrLn "token-report:"
            mapM_ putStrLn (renderTokenReportLines tokenReport)
            putStrLn "smt-report:"
            mapM_ putStrLn (renderSolverReportLines solverReport)
            putStrLn "compiled-xml-preview:"
            putStrLn (renderPromptDocAs FormatXml doc)
            putStrLn "compiled-markdown-preview:"
            putStrLn (renderPromptDocAs FormatMarkdown doc)
            if null diagnostics
                then exitSuccess
                else do
                    putStrLn "diagnostics:"
                    mapM_ (putStrLn . formatDiagnostic) diagnostics
                    exitFailure
