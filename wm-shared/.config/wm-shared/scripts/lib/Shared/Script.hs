module Shared.Script
    ( runWmSharedScript
    , runWmSharedScriptArgs
    ) where

import XMonad (X, spawn)

import Common.Text (shellEscape)
import Variables (myWmSharedScriptShell)

runWmSharedScript :: FilePath -> X ()
runWmSharedScript relPath = spawn (myWmSharedScriptShell relPath)

runWmSharedScriptArgs :: FilePath -> [String] -> X ()
runWmSharedScriptArgs relPath args =
    spawn $
        myWmSharedScriptShell relPath
            ++ concatMap (\arg -> " " ++ shellEscape arg) args
