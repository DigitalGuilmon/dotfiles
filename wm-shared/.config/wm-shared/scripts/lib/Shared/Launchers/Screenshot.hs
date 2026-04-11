module Shared.Launchers.Screenshot (screenshot) where

import XMonad (X)

import Shared.Script (runWmSharedScript)

screenshot :: X ()
screenshot = runWmSharedScript "multimedia/screenshot.hs"
