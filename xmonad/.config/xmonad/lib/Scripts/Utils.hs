module Scripts.Utils (shellEscape, rofiInput, rofiSelect, rofiMenuCommand) where

import XMonad (MonadIO, liftIO)
import XMonad.Util.Run (runProcessWithInput)

import Variables (myRofiFrequentAbs, myRofiFrequentShell, myThemeAbs, myThemeShell)

-- Escapa una cadena para uso seguro en shell (single-quote wrapping)
shellEscape :: String -> String
shellEscape s = "'" ++ concatMap esc s ++ "'"
  where esc '\'' = "'\\''"
        esc c    = [c]

trim :: String -> String
trim = reverse . dropWhile (== '\n') . reverse

rofiInput :: MonadIO m => String -> [String] -> String -> m String
rofiInput prompt extraArgs input = do
  theme <- myThemeAbs
  trim <$> liftIO (runProcessWithInput "rofi" (["-dmenu", "-p", prompt, "-theme", theme] ++ extraArgs) input)

rofiSelect :: MonadIO m => String -> String -> [String] -> String -> m String
rofiSelect menuId prompt extraArgs input = do
  theme <- myThemeAbs
  helper <- myRofiFrequentAbs
  trim <$> liftIO (runProcessWithInput helper
    (["--menu-id", menuId, "--prompt", prompt, "--theme", theme, "--"] ++ extraArgs) input)

rofiMenuCommand :: String -> String -> [String] -> String
rofiMenuCommand menuId prompt extraArgs =
  myRofiFrequentShell
    ++ " --menu-id " ++ shellEscape menuId
    ++ " --prompt " ++ shellEscape prompt
    ++ " --theme " ++ myThemeShell
    ++ concatMap (\arg -> " " ++ shellEscape arg) ("--" : extraArgs)
