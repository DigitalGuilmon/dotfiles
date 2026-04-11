module Keys.Launchers where

import XMonad

import Scripts.Productivity.QuickApps (quickApps)

launcherKeys :: [(String, X ())]
launcherKeys =
    [ ("M-<Return>",   spawn "ghostty")                                                              -- Terminal
    , ("M-v",          spawn "ghostty -e lvim")                                                      -- LunarVim
    , ("M-d",          spawn "rofi -show drun -show-icons -theme ~/.config/rofi/cyberpunk.rasi")     -- Menú de aplicaciones
    , ("M-<Tab>",      spawn "rofi -show window -show-icons -theme ~/.config/rofi/cyberpunk.rasi")   -- Selector de ventanas
    , ("M-a",          quickApps)                                                                    -- Lanzador rápido de apps
    ]
