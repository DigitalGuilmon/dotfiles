module Keys.Launchers where

import XMonad

import Variables (myTerminal, myTheme)
import Scripts.QuickApps (quickApps)

launcherKeys :: [(String, X ())]
launcherKeys =
    [ ("M-<Return>",   spawn myTerminal)                                         -- Abrir terminal (Ghostty)
    , ("M-v",          spawn (myTerminal ++ " -e lvim"))                         -- Abrir LunarVim
    , ("M-d",          spawn ("rofi -show drun -show-icons -theme " ++ myTheme)) -- Menú de aplicaciones
    , ("M-<Tab>",      spawn ("rofi -show window -show-icons -theme " ++ myTheme)) -- Selector de ventanas
    , ("M-a",          quickApps)                                                -- Lanzador rápido de apps por categoría
    ]
