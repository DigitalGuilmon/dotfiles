#!/usr/bin/env sh
#if 0
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
script_root="$script_dir"
while [ ! -d "$script_root/lib" ] && [ "$script_root" != "/" ]; do
    script_root=$(dirname "$script_root")
done
exec runhaskell -XCPP -i"$script_root/lib" "$0" "$@"
#endif

import System.Environment (getArgs)
import System.Exit (exitFailure, exitSuccess)

import Common.PromptDSL (PromptFormat (..), renderPromptDocAs)
import Common.PromptDSLTooling (DiagnosticSeverity (..), PromptDiagnostic (..), formatDiagnostic, lintPromptFile, resolvePromptDocFromFile)

main :: IO ()
main = do
    args <- getArgs
    case args of
        [path] ->
            exportFile path FormatXml
        [path, formatToken] ->
            case parseFormatToken formatToken of
                Left err -> putStrLn ("stdin:1:1: error: " ++ err) >> exitFailure
                Right target -> exportFile path target
        _ -> do
            putStrLn "stdin:1:1: error: uso esperado: pdsl_export.hs <archivo.pdsl> [xml|markdown|hybrid|pdsl]"
            exitFailure

exportFile :: FilePath -> PromptFormat -> IO ()
exportFile path target = do
    resolved <- resolvePromptDocFromFile path
    diagnostics <- lintPromptFile path
    case resolved of
        Left errors -> mapM_ (putStrLn . formatDiagnostic) errors >> exitFailure
        Right doc ->
            if any isError diagnostics
                then mapM_ (putStrLn . formatDiagnostic) diagnostics >> exitFailure
                else putStrLn (renderPromptDocAs target doc) >> exitSuccess

parseFormatToken :: String -> Either String PromptFormat
parseFormatToken "xml" = Right FormatXml
parseFormatToken "markdown" = Right FormatMarkdown
parseFormatToken "hybrid" = Right FormatHybrid
parseFormatToken "pdsl" = Right FormatPDSL
parseFormatToken value = Left ("formato desconocido `" ++ value ++ "`, usa xml, markdown, hybrid o pdsl")

isError :: PromptDiagnostic -> Bool
isError diagnostic = diagnosticSeverity diagnostic == DiagnosticError
