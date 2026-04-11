module Scripts.System.DevTools (devMenu) where

import XMonad
import XMonad.Prompt
import XMonad.Prompt.FuzzyMatch (fuzzyMatch)

data DevPrompt = DevPrompt

instance XPrompt DevPrompt where
    showXPrompt DevPrompt = " DevTools: "
    commandToComplete _ c = c
    nextCompletion _ = getNextCompletion

devOptions :: [(String, X ())]
devOptions =
    -- Docker
    [ ("Docker: Listar Contenedores",   spawn "ghostty -e sh -c 'docker ps -a; echo; echo \"[Enter para cerrar]\"; read'")
    , ("Docker: Compose Up",            spawn "ghostty -e sh -c 'docker compose up -d && echo && echo \"✅ Servicios iniciados\" ; echo \"[Enter para cerrar]\"; read'")
    , ("Docker: Compose Down",          spawn "ghostty -e sh -c 'docker compose down && echo && echo \"🛑 Servicios detenidos\" ; echo \"[Enter para cerrar]\"; read'")
    , ("Docker: Prune (Limpieza)",      spawn "ghostty -e sh -c 'docker system prune -f && echo && echo \"🧹 Limpieza completada\" ; echo \"[Enter para cerrar]\"; read'")
    -- Git
    , ("Git: Status",                   spawn "ghostty -e sh -c 'git status; echo; echo \"[Enter para cerrar]\"; read'")
    , ("Git: Log (últimos 20)",         spawn "ghostty -e sh -c 'git log --oneline --graph -20; echo; echo \"[Enter para cerrar]\"; read'")
    , ("Git: Lazygit",                  spawn "ghostty -e lazygit")
    -- Tmux
    , ("Tmux: Nueva Sesión Dev",        spawn "ghostty -e tmux new-session -s dev")
    , ("Tmux: Attach Sesión",          spawn "ghostty -e sh -c 'tmux ls 2>/dev/null && tmux attach || echo \"No hay sesiones activas\"; echo; echo \"[Enter para cerrar]\"; read'")
    -- Sistema
    , ("Sys: htop/btop",               spawn "ghostty -e btop")
    , ("Sys: Uso de Disco (ncdu)",     spawn "ghostty -e ncdu /")
    , ("Sys: Logs del Sistema",        spawn "ghostty -e sh -c 'journalctl -f'")
    , ("Sys: Procesos Zombie",         spawn "result=$(ps aux | awk '$8==\"Z\" {print $0}' | head -10); notify-send '🧟 Zombies' \"${result:-Ninguno encontrado}\"")
    ]

devXPConfig :: XPConfig
devXPConfig = def
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

-- Menú de herramientas de desarrollo
devMenu :: X ()
devMenu = mkXPrompt DevPrompt devXPConfig
    (mkComplFunFromList' devXPConfig (map fst devOptions))
    (\selection -> case lookup selection devOptions of
        Just action -> action
        Nothing     -> return ()
    )
