module Scripts.Clipboard 
    ( clipboardMenu
    , clipboardClear
    ) where

import XMonad
import Variables (myTheme)

-- Abre el historial del clipboard con rofi (requiere: greenclip daemon activo)
-- greenclip es un daemon que almacena el historial del clipboard.
-- Alternativa: clipmenu. Si usas clipmenu, cambia el comando a "clipmenu".
clipboardMenu :: X ()
clipboardMenu = spawn $ "rofi -modi 'clipboard:greenclip print' -show clipboard -run-command '{cmd}' -theme " ++ myTheme

-- Limpia todo el historial del clipboard
clipboardClear :: X ()
clipboardClear = spawn "greenclip clear && notify-send '🧹 Clipboard' 'Historial limpiado'"
