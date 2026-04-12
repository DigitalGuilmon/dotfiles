#!/usr/bin/env runhaskell

import Control.Exception (IOException, try)
import Control.Monad (void)
import Data.Char (isDigit, isLower, isSpace)
import Data.List (dropWhileEnd)
import System.Directory (findExecutable, getHomeDirectory)
import System.Exit (ExitCode (ExitSuccess, ExitFailure))
import System.IO (hClose, hPutStr)
import System.Process
    ( CreateProcess (std_in)
    , StdStream (CreatePipe)
    , createProcess
    , proc
    , readProcessWithExitCode
    , spawnCommand
    , waitForProcess
    )

main :: IO ()
main = do
    expr <- rofiInput "wm-shared-calculator" "Calc:" ["-i", "-mesg", "Ejemplos: 2+2 | sqrt(144) | 100*0.15 | 2**10"] ""
    case expr of
        "" -> return ()
        _ | not (isSafeExpr expr) ->
                notify "Calculadora" "Expresion invalida. Solo se permiten numeros y funciones matematicas seguras."
          | otherwise -> do
                result <- evalExpression expr
                case result of
                    Left err -> notify "Calculadora" err
                    Right value -> do
                        copied <- copyToClipboard value
                        let suffix = if copied then " (copiado)" else ""
                        notify "Calculadora" (expr ++ " = " ++ value ++ suffix)

safeMathFunctions :: [String]
safeMathFunctions =
    [ "sqrt", "sin", "cos", "tan", "asin", "acos", "atan", "atan2"
    , "log", "log2", "log10", "exp", "pow", "abs", "round", "ceil", "floor"
    , "pi", "e", "tau", "inf", "degrees", "radians", "factorial"
    , "hypot", "gcd", "lcm", "trunc", "fmod", "fsum"
    ]

isSafeExpr :: String -> Bool
isSafeExpr s = all isSafeChar s && all (`elem` safeMathFunctions) (extractWords s)
  where
    isSafeChar c = isDigit c || c `elem` (".+-*/() ," :: String) || isLower c
    extractWords [] = []
    extractWords (c:cs)
        | isLower c =
            let (word, rest) = span isLower (c : cs)
            in word : extractWords rest
        | otherwise = extractWords cs

evalExpression :: String -> IO (Either String String)
evalExpression expr = do
    let script =
            unlines
                [ "from math import *"
                , "import sys"
                , "safe = {name: globals()[name] for name in " ++ show safeMathFunctions ++ " if name in globals()}"
                , "safe.update({'abs': abs, 'round': round})"
                , "print(eval(sys.argv[1], {'__builtins__': {}}, safe))"
                ]
    (exitCode, out, err) <- readProcessWithExitCode "python3" ["-c", script, expr] ""
    pure $ case exitCode of
        ExitSuccess -> Right (trim out)
        ExitFailure _ ->
            let msg = trim err
            in Left $ if null msg then "No se pudo evaluar la expresion." else msg

rofiInput :: String -> String -> [String] -> String -> IO String
rofiInput menuId prompt extraArgs input = do
    home <- getHomeDirectory
    let theme = home ++ "/.config/rofi/themes/modern.rasi"
        helper = home ++ "/.config/rofi/scripts/frequent-menu.py"
        args = ["--menu-id", menuId, "--prompt", prompt, "--theme", theme, "--"] ++ extraArgs
    result <- try (readProcessWithExitCode helper args input) :: IO (Either IOException (ExitCode, String, String))
    pure $ case result of
        Left _ -> ""
        Right (_, out, _) -> trim out

copyToClipboard :: String -> IO Bool
copyToClipboard value = do
    wlCopy <- findExecutable "wl-copy"
    xclip <- findExecutable "xclip"
    xsel <- findExecutable "xsel"
    case () of
        _ | maybe False (const True) wlCopy -> runClipboard "wl-copy" [] value
          | maybe False (const True) xclip -> runClipboard "xclip" ["-selection", "clipboard"] value
          | maybe False (const True) xsel -> runClipboard "xsel" ["--clipboard", "--input"] value
          | otherwise -> pure False

runClipboard :: FilePath -> [String] -> String -> IO Bool
runClipboard command args value = do
    (maybeIn, _, _, processHandle) <- createProcess (proc command args) {std_in = CreatePipe}
    case maybeIn of
        Nothing -> pure False
        Just handle -> do
            hPutStr handle value
            hClose handle
            exitCode <- waitForProcess processHandle
            pure (exitCode == ExitSuccess)

notify :: String -> String -> IO ()
notify title msg =
    void $ spawnCommand $
        "notify-send " ++ shellEscape title ++ " " ++ shellEscape msg

shellEscape :: String -> String
shellEscape s = "'" ++ concatMap escapeChar s ++ "'"
  where
    escapeChar '\'' = "'\\''"
    escapeChar c = [c]

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace
