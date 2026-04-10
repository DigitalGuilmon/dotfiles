module Rules (myManageHook) where

import XMonad
import XMonad.Hooks.ManageDocks (manageDocks)
import XMonad.Util.NamedScratchpad (namedScratchpadManageHook)

import Scratchpads (myScratchpads)
import Rules.Dev (devRules)
import Rules.Web (webRules)
import Rules.Term (termRules)
import Rules.Db (dbRules)
import Rules.Api (apiRules)
import Rules.Chat (chatRules)
import Rules.Media (mediaRules)
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
    ]) <+> manageDocks <+> namedScratchpadManageHook myScratchpads
