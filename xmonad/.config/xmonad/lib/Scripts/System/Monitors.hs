module Scripts.System.Monitors (monitorMenu) where

import XMonad
import XMonad.Prompt
import XMonad.Prompt.FuzzyMatch (fuzzyMatch)
import XMonad.Util.Run (runProcessWithInput)

data MonitorPrompt = MonitorPrompt

instance XPrompt MonitorPrompt where
    showXPrompt MonitorPrompt = " Configuración de Pantallas: "
    commandToComplete _ c = c
    nextCompletion _ = getNextCompletion

-- Detecta las salidas conectadas dinámicamente via xrandr
-- Devuelve (pantalla interna, pantalla externa) si hay 2 conectadas,
-- o solo la primera si hay 1.
detectOutputs :: X (String, Maybe String)
detectOutputs = do
    out <- liftIO $ runProcessWithInput "sh" ["-c", "xrandr --query | grep ' connected' | awk '{print $1}'"] ""
    let outputs = lines (filter (/= '\r') out)
    case outputs of
        (primary:secondary:_) -> return (primary, Just secondary)
        (primary:_)           -> return (primary, Nothing)
        _                     -> return ("eDP-1", Nothing)  -- fallback seguro

monitorOptions :: String -> String -> [(String, X ())]
monitorOptions laptop external =
    [ ("1. Solo Laptop",           spawn $ "xrandr --output " ++ laptop ++ " --auto --output " ++ external ++ " --off")
    , ("2. Extender (Derecha)",    spawn $ "xrandr --output " ++ laptop ++ " --auto --output " ++ external ++ " --auto --right-of " ++ laptop)
    , ("3. Extender (Izquierda)",  spawn $ "xrandr --output " ++ laptop ++ " --auto --output " ++ external ++ " --auto --left-of " ++ laptop)
    , ("4. Duplicar (Mirror)",     spawn $ "xrandr --output " ++ laptop ++ " --auto --output " ++ external ++ " --auto --same-as " ++ laptop)
    , ("5. Solo Monitor Externo",  spawn $ "xrandr --output " ++ laptop ++ " --off --output " ++ external ++ " --auto")
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
monitorMenu = do
    (laptop, mExternal) <- detectOutputs
    case mExternal of
        Nothing -> spawn "notify-send '🖥️ Monitor' 'Solo se detectó una pantalla conectada'"
        Just external -> do
            let opts = monitorOptions laptop external
            mkXPrompt MonitorPrompt monitorXPConfig 
                (mkComplFunFromList' monitorXPConfig (map fst opts))
                (\selection -> case lookup selection opts of
                    Just action -> action
                    Nothing     -> return () 
                )
