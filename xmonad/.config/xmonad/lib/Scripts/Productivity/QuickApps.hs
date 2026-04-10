module Scripts.Productivity.QuickApps (quickApps) where

import XMonad
import XMonad.Prompt
import XMonad.Prompt.FuzzyMatch (fuzzyMatch)

data AppPrompt = AppPrompt

instance XPrompt AppPrompt where
    showXPrompt AppPrompt = " Lanzar App: "
    commandToComplete _ c = c
    nextCompletion _ = getNextCompletion

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
    -- Sistema
    , ("Sys: Thunar (Archivos)",  spawn "thunar")
    , ("Sys: Btop (Monitor)",     spawn "ghostty -e btop")
    , ("Sys: Pavucontrol (Audio)",spawn "pavucontrol")
    , ("Sys: Lxappearance",       spawn "lxappearance")
    , ("Sys: VirtualBox",         spawn "virtualbox")
    ]

appXPConfig :: XPConfig
appXPConfig = def
    { font              = "xft:JetBrainsMono Nerd Font:size=11"
    , bgColor           = "#282a36"
    , fgColor           = "#f8f8f2"
    , bgHLight          = "#50fa7b"
    , fgHLight          = "#282a36"
    , borderColor       = "#50fa7b"
    , promptBorderWidth = 2
    , position          = CenteredAt 0.5 0.5
    , height            = 50
    , alwaysHighlight   = True
    , searchPredicate   = fuzzyMatch
    }

-- Menú rápido para lanzar aplicaciones con búsqueda fuzzy
quickApps :: X ()
quickApps = mkXPrompt AppPrompt appXPConfig
    (mkComplFunFromList' appXPConfig (map fst appList))
    (\selection -> case lookup selection appList of
        Just action -> action
        Nothing     -> return ()
    )
