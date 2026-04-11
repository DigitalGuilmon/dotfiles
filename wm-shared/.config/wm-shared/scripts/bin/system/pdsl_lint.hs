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

import Common.PromptDSLTooling (formatDiagnostic, lintPromptFile, lintPromptSource)

main :: IO ()
main = do
    args <- getArgs
    diagnostics <- case args of
        [path] ->
            lintPromptFile path
        ["--stdin", "--path", path] -> do
            source <- getContents
            lintPromptSource path source
        _ -> do
            putStrLn "stdin:1:1: error: uso esperado: pdsl_lint.hs <archivo.pdsl> o pdsl_lint.hs --stdin --path <archivo.pdsl>"
            exitFailure
    case diagnostics of
        [] -> exitSuccess
        values -> do
            mapM_ (putStrLn . formatDiagnostic) values
            exitFailure
