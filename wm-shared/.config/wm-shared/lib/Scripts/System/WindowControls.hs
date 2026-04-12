module Scripts.System.WindowControls where

import XMonad
import qualified XMonad.StackSet as W

-- Hunde (devuelve al modo tiling) la ventana actual enfocada
sinkWindow :: X ()
sinkWindow = withFocused $ windows . W.sink

-- Hunde TODAS las ventanas del espacio de trabajo actual en una sola operación
sinkAll :: X ()
sinkAll = windows $ \ws -> foldl (\w' win -> W.sink win w') ws (W.index ws)
