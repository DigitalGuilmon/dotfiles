module Shared.Menu.QuickApps (quickApps) where

import XMonad
import XMonad.Prompt (XPConfig)

import Shared.Menu.Prompt (promptConfig, runStaticPromptMenu)

appList :: [(String, X ())]
appList =
    -- Desarrollo
    [ ("Dev: LunarVim",         spawn "ghostty -e lvim")
    , ("Dev: VS Code",          spawn "code")
    , ("Dev: IntelliJ IDEA",    spawn "idea")
    , ("Dev: DBeaver (DB)",     spawn "dbeaver")
    , ("Dev: Postman (API)",    spawn "postman")
    , ("Dev: Lazygit",          spawn "ghostty -e lazygit")
    , ("Dev: Docker Desktop",   spawn "docker-desktop")
    -- Navegadores
    , ("Web: Brave",            spawn "brave")
    , ("Web: Firefox",          spawn "firefox")
    -- Comunicación
    , ("Chat: Discord",         spawn "discord")
    , ("Chat: Telegram",        spawn "telegram-desktop")
    -- Multimedia
    , ("Media: Spotify",        spawn "spotify-launcher")
    , ("Media: VLC",            spawn "vlc")
    , ("Media: OBS Studio",     spawn "obs")
    -- Sistema (Thunar se gestiona exclusivamente como scratchpad vía M-S-f
    -- porque Thunar ignora --class y todas sus ventanas son capturadas por el scratchpad)
    , ("Sys: Btop (Monitor)",     spawn "ghostty -e btop")
    , ("Sys: Pavucontrol (Audio)",spawn "pavucontrol")
    , ("Sys: Lxappearance",       spawn "lxappearance")
    , ("Sys: VirtualBox",         spawn "virtualbox")
    ]

appXPConfig :: XPConfig
appXPConfig = promptConfig "#50fa7b" "#282a36" "#50fa7b"

-- Menú rápido para lanzar aplicaciones con búsqueda fuzzy
quickApps :: X ()
quickApps = runStaticPromptMenu " Lanzar App: " appXPConfig appList id
