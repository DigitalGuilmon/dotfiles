module Scripts.Monitors (monitorMenu) where

import XMonad
import XMonad.Prompt
import XMonad.Prompt.FuzzyMatch (fuzzyMatch) -- ¡Añadido!

data MonitorPrompt = MonitorPrompt

instance XPrompt MonitorPrompt where
    showXPrompt MonitorPrompt = " Configuración de Pantallas: "
    commandToComplete _ c = c
    nextCompletion _ = getNextCompletion

monitorOptions :: [(String, X ())]
monitorOptions =
    [ ("1. Solo Laptop",           spawn "xrandr --output eDP-1 --auto --output HDMI-1 --off")
    , ("2. Extender (Derecha)",    spawn "xrandr --output eDP-1 --auto --output HDMI-1 --auto --right-of eDP-1")
    , ("3. Extender (Izquierda)",  spawn "xrandr --output eDP-1 --auto --output HDMI-1 --auto --left-of eDP-1")
    , ("4. Duplicar (Mirror)",     spawn "xrandr --output eDP-1 --auto --output HDMI-1 --auto --same-as eDP-1")
    , ("5. Solo Monitor Externo",  spawn "xrandr --output eDP-1 --off --output HDMI-1 --auto")
    ]

monitorXPConfig :: XPConfig
monitorXPConfig = def
    { font              = "xft:JetBrainsMono Nerd Font:size=11"
    , bgColor           = "#282a36" 
    , fgColor           = "#f8f8f2" 
    , bgHLight          = "#ff79c6" 
    , fgHLight          = "#282a36" 
    , borderColor       = "#8be9fd" 
    , promptBorderWidth = 2
    , position          = CenteredAt 0.5 0.5 
    , height            = 50
    , alwaysHighlight   = True
    , searchPredicate   = fuzzyMatch 
    }

monitorMenu :: X ()
monitorMenu = mkXPrompt MonitorPrompt monitorXPConfig 
    (mkComplFunFromList' monitorXPConfig (map fst monitorOptions))
    (\selection -> case lookup selection monitorOptions of
        Just action -> action
        Nothing     -> return () 
    )
