module Rules where

import XMonad
import XMonad.Hooks.ManageDocks (manageDocks)
import XMonad.Hooks.ManageHelpers (isFullscreen, doFullFloat, isDialog, doCenterFloat)
import XMonad.Util.NamedScratchpad (namedScratchpadManageHook)
import qualified XMonad.StackSet as W

import Scratchpads (myScratchpads)
import Variables (myWorkspaces) -- Se importa la variable centralizada

myManageHook :: ManageHook
myManageHook = composeAll
    [ className =? "jetbrains-idea"     --> doShift (myWorkspaces !! 0) -- 1:dev
    , className =? "Code"               --> doShift (myWorkspaces !! 0)
    , className =? "Brave-browser"      --> doShift (myWorkspaces !! 1) -- 2:web
    , className =? "firefox"            --> doShift (myWorkspaces !! 1)
    , className =? "DBeaver"            --> doShift (myWorkspaces !! 3) -- 4:db
    , className =? "Postman"            --> doShift (myWorkspaces !! 4) -- 5:api
    , className =? "Insomnia"           --> doShift (myWorkspaces !! 4)
    , className =? "discord"            --> doShift (myWorkspaces !! 5) -- 6:chat
    , className =? "TelegramDesktop"    --> doShift (myWorkspaces !! 5)
    , className =? "Steam"              --> doShift (myWorkspaces !! 6) -- 7:media
    , className =? "Spotify"            --> doShift (myWorkspaces !! 6)
    , className =? "VirtualBox Manager" --> doShift (myWorkspaces !! 8) -- 9:vm
    , className =? "pavucontrol"        --> doCenterFloat
    , className =? "Lxappearance"       --> doCenterFloat
    , isFullscreen                      --> doFullFloat
    , isDialog                          --> doCenterFloat
    ] <+> manageDocks <+> namedScratchpadManageHook myScratchpads
