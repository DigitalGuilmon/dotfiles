module Shared.Utils (shellEscape, rofiInput, rofiSelect, rofiMenuCommand) where

import Common.Text (shellEscape, trimTrailingNewlines)
import XMonad (MonadIO, liftIO)
import XMonad.Util.Run (runProcessWithInput)

import Variables (myRofiFrequentAbs, myRofiFrequentShell, myThemeAbs, myThemeShell)

rofiInput :: MonadIO m => String -> [String] -> String -> m String
rofiInput prompt extraArgs input = do
  theme <- myThemeAbs
  trimTrailingNewlines <$> liftIO (runProcessWithInput "rofi" (["-dmenu", "-p", prompt, "-theme", theme] ++ extraArgs) input)

rofiSelect :: MonadIO m => String -> String -> [String] -> String -> m String
rofiSelect menuId prompt extraArgs input = do
  theme <- myThemeAbs
  helper <- myRofiFrequentAbs
  trimTrailingNewlines <$> liftIO (runProcessWithInput helper
    (["--menu-id", menuId, "--prompt", prompt, "--theme", theme, "--"] ++ extraArgs) input)

rofiMenuCommand :: String -> String -> [String] -> String
rofiMenuCommand menuId prompt extraArgs =
  myRofiFrequentShell
    ++ " --menu-id " ++ shellEscape menuId
    ++ " --prompt " ++ shellEscape prompt
    ++ " --theme " ++ myThemeShell
    ++ concatMap (\arg -> " " ++ shellEscape arg) ("--" : extraArgs)
