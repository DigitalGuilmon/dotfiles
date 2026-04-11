module Actions.Rofi (rofiSelect) where

import XMonad (MonadIO, liftIO)
import XMonad.Util.Run (runProcessWithInput)

import Variables (myRofiFrequentAbs, myThemeAbs)

trim :: String -> String
trim = reverse . dropWhile (== '\n') . reverse

rofiSelect :: MonadIO m => String -> String -> [String] -> String -> m String
rofiSelect menuId prompt extraArgs input = do
    theme <- myThemeAbs
    helper <- myRofiFrequentAbs
    trim <$> liftIO (runProcessWithInput helper (["--menu-id", menuId, "--prompt", prompt, "--theme", theme, "--"] ++ extraArgs) input)
