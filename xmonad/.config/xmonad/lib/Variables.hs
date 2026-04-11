module Variables where

import XMonad
import System.Directory (getHomeDirectory)

myTerminal :: String
myTerminal    = "ghostty"

myModMask :: KeyMask
myModMask     = mod4Mask 

myBorderWidth :: Dimension
myBorderWidth = 2

-- Ruta con ~ para uso en spawn (shell expande ~)
myTheme :: String
myTheme       = "~/.config/rofi/cyberpunk.rasi"

-- Ruta resuelta para uso en runProcessWithInput (no pasa por shell)
myThemeAbs :: MonadIO m => m String
myThemeAbs = liftIO $ do
    home <- getHomeDirectory
    return $ home ++ "/.config/rofi/cyberpunk.rasi"

myWorkspaces :: [String]
myWorkspaces = ["1:dev", "2:web", "3:term", "4:db", "5:api", "6:chat", "7:media", "8:sys", "9:vm", "10:misc"]
