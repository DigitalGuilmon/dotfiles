module Rules where

import XMonad
import XMonad.Hooks.ManageDocks (manageDocks)
import XMonad.Hooks.ManageHelpers (isFullscreen, doFullFloat, isDialog, doCenterFloat)
import XMonad.Util.NamedScratchpad (namedScratchpadManageHook)
import qualified XMonad.StackSet as W

import Scratchpads (myScratchpads)

myManageHook :: ManageHook
myManageHook = composeAll
    [ className =? "jetbrains-idea"     --> doShift "1:dev"
    , className =? "Code"               --> doShift "1:dev"
    , className =? "Brave-browser"      --> doShift "2:web"
    , className =? "firefox"            --> doShift "2:web"
    , className =? "DBeaver"            --> doShift "4:db"
    , className =? "Postman"            --> doShift "5:api"
    , className =? "Insomnia"           --> doShift "5:api"
    , className =? "discord"            --> doShift "6:chat"
    , className =? "TelegramDesktop"    --> doShift "6:chat"
    , className =? "Steam"              --> doShift "7:media"
    , className =? "Spotify"            --> doShift "7:media"
    , className =? "VirtualBox Manager" --> doShift "9:vm"
    , className =? "pavucontrol"        --> doCenterFloat
    , className =? "Lxappearance"       --> doCenterFloat
    , isFullscreen                      --> doFullFloat
    , isDialog                          --> doCenterFloat
    ] <+> manageDocks <+> namedScratchpadManageHook myScratchpads
