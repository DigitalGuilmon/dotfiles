module Scripts.Multimedia.Screenshot (screenshot) where

import XMonad

import Variables (myWmSharedScriptShell)

screenshot :: X ()
screenshot = spawn $ myWmSharedScriptShell "multimedia/screenshot.hs"
