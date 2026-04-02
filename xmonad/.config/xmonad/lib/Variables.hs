module Variables where

import XMonad

myTerminal :: String
myTerminal    = "ghostty"

myModMask :: KeyMask
myModMask     = mod4Mask 

myBorderWidth :: Dimension
myBorderWidth = 2

myTheme :: String
myTheme       = "~/.config/rofi/cyberpunk.rasi"

myWorkspaces :: [String]
myWorkspaces = ["1:dev", "2:web", "3:term", "4:db", "5:api", "6:chat", "7:media", "8:sys", "9:vm", "10:misc"]
