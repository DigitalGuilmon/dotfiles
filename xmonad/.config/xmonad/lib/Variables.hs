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
myWorkspaces = [wsDev, wsWeb, wsTerm, wsDb, wsApi, wsChat, wsMedia, wsSys, wsVm, wsMisc]

-- Constantes de workspace: evitan indexación parcial con (!!) que crashea si se
-- modifica la longitud de myWorkspaces
wsDev, wsWeb, wsTerm, wsDb, wsApi, wsChat, wsMedia, wsSys, wsVm, wsMisc :: String
wsDev   = "1:dev"
wsWeb   = "2:web"
wsTerm  = "3:term"
wsDb    = "4:db"
wsApi   = "5:api"
wsChat  = "6:chat"
wsMedia = "7:media"
wsSys   = "8:sys"
wsVm    = "9:vm"
wsMisc  = "10:misc"
