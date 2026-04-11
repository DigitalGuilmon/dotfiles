module Shared.Launchers.Clipboard 
    ( clipboardMenu
    , clipboardClear
    ) where

import XMonad (X)

import Shared.Script (runWmSharedScript, runWmSharedScriptArgs)

clipboardMenu :: X ()
clipboardMenu = runWmSharedScript "productivity/clipboard.hs"

clipboardClear :: X ()
clipboardClear = runWmSharedScriptArgs "productivity/clipboard.hs" ["clear"]
