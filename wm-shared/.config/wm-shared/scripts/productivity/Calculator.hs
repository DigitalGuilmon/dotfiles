module Scripts.Productivity.Calculator (calculator) where

import XMonad

import Variables (myWmSharedScriptShell)

calculator :: X ()
calculator = spawn $ myWmSharedScriptShell "productivity/calculator.hs"
