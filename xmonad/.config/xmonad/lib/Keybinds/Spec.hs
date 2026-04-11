module Keybinds.Spec (KeybindSpec (..)) where

data KeybindSpec = KeybindSpec
    { keybindKey :: String
    , keybindAction :: String
    , keybindArg :: Maybe String
    }
    deriving (Eq, Show)
