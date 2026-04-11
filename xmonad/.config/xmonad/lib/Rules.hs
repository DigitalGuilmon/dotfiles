module Rules (myManageHook, myHandleEventHook) where

import XMonad
import XMonad.Util.NamedScratchpad (namedScratchpadManageHook)
import XMonad.Hooks.DynamicProperty (dynamicPropertyChange)

import Scratchpads (myScratchpads)
import Rules.Dev (devRules)
import Rules.Web (webRules)
import Rules.Term (termRules)
import Rules.Db (dbRules)
import Rules.Api (apiRules)
import Rules.Chat (chatRules)
import Rules.Media (mediaRules, mediaSpotifyHook)
import Rules.Sys (sysRules)
import Rules.Vm (vmRules)
import Rules.Misc (miscRules)

myManageHook :: ManageHook
myManageHook = composeAll (concat
    [ devRules
    , webRules
    , termRules
    , dbRules
    , apiRules
    , chatRules
    , mediaRules
    , sysRules
    , vmRules
    , miscRules
    ]) <+> namedScratchpadManageHook myScratchpads

-- Aplica reglas cuando WM_CLASS cambia después de mapear la ventana
-- Necesario para apps Electron como Spotify que establecen WM_CLASS tarde
myHandleEventHook :: Event -> X All
myHandleEventHook = dynamicPropertyChange "WM_CLASS" mediaSpotifyHook
