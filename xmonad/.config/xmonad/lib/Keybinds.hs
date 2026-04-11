module Keybinds (loadMyKeys) where

import XMonad
import Keybinds.Applier (applyGeneratedKeybinds)
import Keybinds.Loader (loadXmonadKeybinds)

loadMyKeys :: IO [(String, X ())]
loadMyKeys = applyGeneratedKeybinds <$> loadXmonadKeybinds
