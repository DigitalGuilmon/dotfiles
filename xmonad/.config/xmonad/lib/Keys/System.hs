module Keys.System where

import XMonad
import qualified XMonad.StackSet as W

import Scripts.PowerMenu (powerMenu)
import Scripts.Monitors (monitorMenu)
import Scripts.AudioControl (audioMenu)
import Scripts.NetworkMenu (networkMenu)
import Scripts.NotificationCenter (notificationMenu)

systemKeys :: [(String, X ())]
systemKeys =
    -- Recompilar y reiniciar
    [ ("M-q",          spawn "xmonad --recompile && xmonad --restart")
    , ("M-S-q",        powerMenu)                -- Menú de Energía (Apagar, Reiniciar...)
    , ("M-S-m",        monitorMenu)              -- Menú de configuración de Monitores
    , ("M-x",          kill)                     -- Cerrar ventana activa
    , ("M-<Escape>",   withWindowSet $ \s -> mapM_ killWindow (W.allWindows s)) -- Cerrar todas las ventanas
    , ("M-S-a",        audioMenu)                -- Control de audio (volumen, salida, mic)
    , ("M-S-w",        networkMenu)              -- Gestión de red (WiFi, VPN)
    , ("M-S-x",        notificationMenu)         -- Control de notificaciones (DND, limpiar)
    ]
