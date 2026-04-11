module Scratchpads where

import XMonad
import XMonad.Util.NamedScratchpad
import qualified XMonad.StackSet as W

-- Scratchpads: ventanas flotantes que aparecen y desaparecen con un atajo
myScratchpads :: [NamedScratchpad]
myScratchpads =
    [ NS "vscode" "code --new-window --class=scratchpad-vscode" (className =? "scratchpad-vscode") centerLarge
    , NS "terminal" "ghostty --class=scratchpad-term" (className =? "scratchpad-term") centerMedium
    , NS "filemanager" "thunar" (className =? "Thunar") centerLarge
    , NS "btop" "ghostty --class=scratchpad-btop -e btop" (className =? "scratchpad-btop") centerLarge
    , NS "notes" "ghostty --class=scratchpad-notes -e lvim ~/Notes" (className =? "scratchpad-notes") centerMedium
    ]
  where
    centerLarge  = customFloating $ W.RationalRect (1/10) (1/10) (4/5) (4/5)
    centerMedium = customFloating $ W.RationalRect (1/6) (1/6) (2/3) (2/3)
