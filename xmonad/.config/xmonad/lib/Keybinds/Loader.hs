module Keybinds.Loader (loadXmonadKeybinds) where

import System.Exit (ExitCode (ExitSuccess))
import System.Process (readProcessWithExitCode)

import Keybinds.Spec (KeybindSpec (..))
import Variables (resolveHomePath)

loadXmonadKeybinds :: IO [KeybindSpec]
loadXmonadKeybinds = do
    script <- resolveHomePath ".config/wm-shared/scripts/bin/system/generate_keybinds.py"
    (exitCode, out, err) <- readProcessWithExitCode "python3" [script, "--dump-xmonad-specs"] ""
    case exitCode of
        ExitSuccess -> mapM parseSpecLine (filter (not . null) (lines out))
        _ -> error ("No se pudieron cargar las keybinds de xmonad desde keybinds.yml:\n" ++ err)

parseSpecLine :: String -> IO KeybindSpec
parseSpecLine line =
    case splitTabs line of
        [keyName, actionName, argValue] ->
            pure $
                KeybindSpec
                    keyName
                    actionName
                    (if argValue == "-" then Nothing else Just argValue)
        _ -> error ("Línea inválida al cargar keybinds de xmonad: " ++ line)

splitTabs :: String -> [String]
splitTabs [] = [""]
splitTabs (c:cs)
    | c == '\t' = "" : splitTabs cs
    | otherwise =
        case splitTabs cs of
            [] -> [[c]]
            (chunk:rest) -> (c : chunk) : rest
