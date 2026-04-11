module Shared.Menu.Monitors (monitorMenu) where

import XMonad
import XMonad.Prompt (XPConfig)
import XMonad.Util.Run (runProcessWithInput)
import Data.Char (isAlphaNum)

import Shared.Menu.Prompt (promptConfig, runStaticPromptMenu)

-- Detecta las salidas conectadas dinámicamente via xrandr
-- Devuelve (pantalla interna, pantalla externa) si hay 2 conectadas,
-- o solo la primera si hay 1.

-- Sanitiza un nombre de output de xrandr para uso seguro en shell
sanitizeOutput :: String -> String
sanitizeOutput = filter (\c -> isAlphaNum c || c `elem` ("-_." :: String))

detectOutputs :: X (String, Maybe String)
detectOutputs = do
    out <- runProcessWithInput "sh" ["-c", "xrandr --query | grep ' connected' | awk '{print $1}'"] ""
    let outputs = filter (not . null) . map sanitizeOutput $ lines (filter (/= '\r') out)
    case outputs of
        (primary:secondary:_) -> return (primary, Just secondary)
        (primary:_)           -> return (primary, Nothing)
        _                     -> return ("eDP-1", Nothing)  -- fallback si xrandr falla

monitorOptions :: String -> String -> [(String, X ())]
monitorOptions laptop external =
    [ ("1. Solo Laptop",           spawn $ "xrandr --output '" ++ laptop ++ "' --auto --output '" ++ external ++ "' --off")
    , ("2. Extender (Derecha)",    spawn $ "xrandr --output '" ++ laptop ++ "' --auto --output '" ++ external ++ "' --auto --right-of '" ++ laptop ++ "'")
    , ("3. Extender (Izquierda)",  spawn $ "xrandr --output '" ++ laptop ++ "' --auto --output '" ++ external ++ "' --auto --left-of '" ++ laptop ++ "'")
    , ("4. Duplicar (Mirror)",     spawn $ "xrandr --output '" ++ laptop ++ "' --auto --output '" ++ external ++ "' --auto --same-as '" ++ laptop ++ "'")
    , ("5. Solo Monitor Externo",  spawn $ "xrandr --output '" ++ laptop ++ "' --off --output '" ++ external ++ "' --auto")
    ]

monitorXPConfig :: XPConfig
monitorXPConfig = promptConfig "#ff79c6" "#282a36" "#8be9fd"

monitorMenu :: X ()
monitorMenu = do
    (laptop, mExternal) <- detectOutputs
    case mExternal of
        Nothing -> spawn "notify-send '🖥️ Monitor' 'Solo se detectó una pantalla conectada'"
        Just external -> do
            let opts = monitorOptions laptop external
            runStaticPromptMenu " Configuración de Pantallas: " monitorXPConfig opts id
