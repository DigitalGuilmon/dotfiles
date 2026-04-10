module Rules.Misc (miscRules) where

import XMonad
import XMonad.Hooks.ManageHelpers (isFullscreen, doFullFloat, isDialog, doCenterFloat)

miscRules :: [ManageHook]
miscRules =
    [ className =? "pavucontrol"        --> doCenterFloat
    , className =? "Lxappearance"       --> doCenterFloat
    , isFullscreen                      --> doFullFloat
    , isDialog                          --> doCenterFloat
    ]
