module Actions.WindowControls
    ( centerWindow
    , sinkAll
    , sinkWindow
    , toggleFloatCentered
    ) where

import XMonad
import qualified XMonad.StackSet as W

centerFloatRect :: W.RationalRect
centerFloatRect = W.RationalRect (1 / 6) (1 / 8) (2 / 3) (3 / 4)

sinkWindow :: X ()
sinkWindow = withFocused $ windows . W.sink

sinkAll :: X ()
sinkAll = windows $ \ws -> foldl (\w' win -> W.sink win w') ws (W.index ws)

toggleFloatCentered :: X ()
toggleFloatCentered = centerWindow

centerWindow :: X ()
centerWindow = withFocused $ \win -> windows (W.float win centerFloatRect)
