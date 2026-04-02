module Scratchpads where

import XMonad
import XMonad.Util.NamedScratchpad
import qualified XMonad.StackSet as W

-- Definimos el scratchpad en una sola línea para evitar errores de indentación
myScratchpads :: [NamedScratchpad]
myScratchpads = [ NS "vscode" "code-oss --new-window --user-data-dir=~/.config/Code-OSS-Scratchpad" (className =? "code-oss") (customFloating $ W.RationalRect (1/10) (1/10) (4/5) (4/5)) ]
