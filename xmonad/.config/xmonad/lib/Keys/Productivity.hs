module Keys.Productivity where

import XMonad

import Scripts.ProjectManager (projectMenu)
import Scripts.Bookmarks (bookmarkMenu)
import Scripts.DevTools (devMenu)
import Scripts.EmojiPicker (emojiPicker)
import Scripts.Calculator (calculator)
import Scripts.Timer (timerMenu)
import Scripts.TodoList (todoMenu)
import Scripts.SystemInfo (systemInfo)

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
