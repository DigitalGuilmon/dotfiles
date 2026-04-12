module Keys.System where

import XMonad
import qualified XMonad.StackSet as W
import Scripts.Utils (rofiSelect)

import Scripts.System.PowerMenu (powerMenu)
import Scripts.System.Monitors (monitorMenu)
import Scripts.Multimedia.AudioControl (audioMenu)
import Scripts.Network.NetworkMenu (networkMenu)
import Scripts.System.NotificationCenter (notificationMenu)

systemKeys :: [(String, X ())]
systemKeys =
    -- Recompilar y reiniciar
    [ ("M-q",          spawn "xmonad --recompile && xmonad --restart")
    , ("M-S-q",        powerMenu)                -- Menú de Energía (Apagar, Reiniciar...)
    , ("M-S-m",        monitorMenu)              -- Menú de configuración de Monitores
    , ("M-x",          kill)                     -- Cerrar ventana activa
    , ("M-<Escape>",   confirmKillAll)           -- Cerrar todas las ventanas (con confirmación)
    , ("M-S-a",        audioMenu)                -- Control de audio (volumen, salida, mic)
    , ("M-S-w",        networkMenu)              -- Gestión de red (WiFi, VPN)
    , ("M-S-x",        notificationMenu)         -- Control de notificaciones (DND, limpiar)
    ]

-- Pide confirmación antes de cerrar todas las ventanas
confirmKillAll :: X ()
confirmKillAll = do
    res <- rofiSelect "xmonad-confirm-kill-all" "¿Cerrar TODAS las ventanas?" ["-i"] "Sí\nNo"
    case res of
        "Sí" -> withWindowSet $ \s -> mapM_ killWindow (W.allWindows s)
        _    -> return ()
