module Keys.Productivity where

import XMonad

import Scripts.Productivity.ProjectManager (projectMenu)
import Scripts.Network.Bookmarks (bookmarkMenu)
import Scripts.System.DevTools (devMenu)
import Scripts.Productivity.EmojiPicker (emojiPicker)
import Scripts.Productivity.Calculator (calculator)
import Scripts.Productivity.Timer (timerMenu)
import Scripts.Productivity.TodoList (todoMenu)
import Scripts.System.SystemInfo (systemInfo)

productivityKeys :: [(String, X ())]
productivityKeys =
    [ ("M-o",          projectMenu)   -- Saltar a un proyecto (terminal + editor)
    , ("M-b",          bookmarkMenu)  -- Abrir bookmarks favoritos
    , ("M-S-d",        devMenu)       -- Herramientas de desarrollo (Docker, Git, Tmux...)
    , ("M-e",          emojiPicker)   -- Selector de emojis (copia al clipboard)
    , ("M-r",          calculator)    -- Calculadora rápida con Rofi
    , ("M-y",          timerMenu)     -- Temporizador Pomodoro con Rofi
    , ("M-z",          todoMenu)      -- Gestor de tareas TODO con Rofi
    , ("M-i",          systemInfo)    -- Info del sistema con Rofi
    ]
