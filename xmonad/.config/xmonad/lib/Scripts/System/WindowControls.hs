module Scripts.System.WindowControls where

import XMonad
import qualified XMonad.StackSet as W

-- Hunde (devuelve al modo tiling) la ventana actual enfocada
sinkWindow :: X ()
sinkWindow = withFocused $ windows . W.sink

-- Hunde TODAS las ventanas del espacio de trabajo actual a la vez
sinkAll :: X ()
sinkAll = gets windowset >>= mapM_ (windows . W.sink) . W.index
