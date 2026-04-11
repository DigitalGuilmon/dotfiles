module Scripts.System.NotificationCenter (notificationMenu) where

import XMonad
import XMonad.Prompt
import XMonad.Prompt.FuzzyMatch (fuzzyMatch)

data NotifPrompt = NotifPrompt

instance XPrompt NotifPrompt where
    showXPrompt NotifPrompt = " Notificaciones: "
    commandToComplete _ c = c
    nextCompletion _ = getNextCompletion

-- Control de notificaciones via dunst (o dunstctl)
notifOptions :: [(String, X ())]
notifOptions =
    [ ("1. Mostrar Historial",          spawn "dunstctl history-pop")
    , ("2. Cerrar Última",              spawn "dunstctl close")
    , ("3. Cerrar Todas",               spawn "dunstctl close-all")
    , ("4. No Molestar: Activar",       spawn "notify-send -t 800 '🔕 DND' 'Modo No Molestar activado'; sleep 1; dunstctl set-paused true")
    , ("5. No Molestar: Desactivar",    spawn "dunstctl set-paused false && notify-send '🔔 DND' 'Notificaciones restauradas'")
    , ("6. Toggle No Molestar",         spawn "dunstctl set-paused toggle")
    , ("7. Estado Actual",              spawn "notify-send '📊 Dunst' \"Pausado: $(dunstctl is-paused) | Esperando: $(dunstctl count waiting) | Mostradas: $(dunstctl count displayed)\"")
    ]

notifXPConfig :: XPConfig
notifXPConfig = def
    { font              = "xft:JetBrainsMono Nerd Font:size=11"
    , bgColor           = "#282a36"
    , fgColor           = "#f8f8f2"
    , bgHLight          = "#ff5555"
    , fgHLight          = "#f8f8f2"
    , borderColor       = "#ff5555"
    , promptBorderWidth = 2
    , position          = CenteredAt 0.5 0.5
    , height            = 50
    , alwaysHighlight   = True
    , searchPredicate   = fuzzyMatch
    }

-- Menú de control de notificaciones
notificationMenu :: X ()
notificationMenu = mkXPrompt NotifPrompt notifXPConfig
    (mkComplFunFromList' notifXPConfig (map fst notifOptions))
    (\selection -> case lookup selection notifOptions of
        Just action -> action
        Nothing     -> return ()
    )
