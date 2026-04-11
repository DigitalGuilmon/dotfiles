module Shared.Launchers.Calculator (calculator) where

import XMonad (X)

import Shared.Script (runWmSharedScript)

calculator :: X ()
calculator = runWmSharedScript "productivity/calculator.hs"
