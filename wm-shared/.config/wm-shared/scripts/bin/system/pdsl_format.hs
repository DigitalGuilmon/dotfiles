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

import Common.PromptDSLTooling (formatPromptSource)

main :: IO ()
main = do
    args <- getArgs
    case args of
        ["--stdin", "--path", _] -> getContents >>= emitFormatted
        ["--stdin"] -> getContents >>= emitFormatted
        [path] -> do
            source <- readFile path
            emitFormatted source
        _ -> do
            putStrLn "stdin:1:1: error: uso esperado: pdsl_format.hs <archivo.pdsl> o pdsl_format.hs --stdin"
            exitFailure

emitFormatted :: String -> IO ()
emitFormatted source =
    case formatPromptSource source of
        Left err -> putStrLn ("stdin:1:1: error: " ++ err) >> exitFailure
        Right formatted -> putStrLn formatted >> exitSuccess
