module Shared.Menu.WindowManager (windowManagerMenu) where

import XMonad
import qualified XMonad.StackSet as W

import Shared.GridMenu (gridGoToWindow)
import Shared.WindowControls (centerWindow, sinkAll, sinkWindow, toggleFloatCentered)
import Shared.Utils (rofiSelect)

windowManagerOptions :: [(String, X ())]
windowManagerOptions =
    [ ("Mostrar todas las ventanas", gridGoToWindow)
    , ("Toggle ventana flotante", toggleFloatCentered)
    , ("Centrar ventana actual", centerWindow)
    , ("Hundir ventana actual", sinkWindow)
    , ("Hundir todas las flotantes", sinkAll)
    , ("Cerrar ventana actual", kill)
    , ("Cerrar todas las ventanas", confirmKillAll)
    ]

windowManagerMenu :: X ()
windowManagerMenu = do
    selection <- rofiSelect
        "xmonad-window-manager"
        "Ventanas"
        ["-i"]
        (unlines (map fst windowManagerOptions))
    case lookup selection windowManagerOptions of
        Just action -> action
        Nothing -> return ()

confirmKillAll :: X ()
confirmKillAll = do
    selection <- rofiSelect "xmonad-window-manager-confirm" "¿Cerrar TODAS las ventanas?" ["-i"] "Sí\nNo"
    case selection of
        "Sí" -> withWindowSet $ \ws -> mapM_ killWindow (W.allWindows ws)
        _ -> return ()
