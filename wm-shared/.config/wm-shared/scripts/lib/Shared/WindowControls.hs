module Shared.WindowControls where

import XMonad
import qualified XMonad.StackSet as W

centerFloatRect :: W.RationalRect
centerFloatRect = W.RationalRect (1 / 6) (1 / 8) (2 / 3) (3 / 4)

-- Hunde (devuelve al modo tiling) la ventana actual enfocada
sinkWindow :: X ()
sinkWindow = withFocused $ windows . W.sink

-- Hunde TODAS las ventanas del espacio de trabajo actual en una sola operación
sinkAll :: X ()
sinkAll = windows $ \ws -> foldl (\w' win -> W.sink win w') ws (W.index ws)

-- Alterna entre tiling y flotante centrado para la ventana enfocada
toggleFloatCentered :: X ()
toggleFloatCentered = centerWindow

-- Re-centra la ventana enfocada
centerWindow :: X ()
centerWindow = withFocused $ \win -> windows (W.float win centerFloatRect)
