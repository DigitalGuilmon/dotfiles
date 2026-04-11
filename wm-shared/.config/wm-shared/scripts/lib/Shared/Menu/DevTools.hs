module Shared.Menu.DevTools (devMenu) where

import XMonad
import XMonad.Prompt (XPConfig)

import Shared.Menu.Prompt (promptConfig, runStaticPromptMenu)

devOptions :: [(String, X ())]
devOptions =
    -- Docker
    [ ("Docker: Listar Contenedores",   spawn "ghostty -e sh -c 'docker ps -a; echo; echo \"[Enter para cerrar]\"; read'")
    , ("Docker: Compose Up",            spawn "ghostty -e sh -c 'docker compose up -d && echo && echo \"✅ Servicios iniciados\" ; echo \"[Enter para cerrar]\"; read'")
    , ("Docker: Compose Down",          spawn "ghostty -e sh -c 'docker compose down && echo && echo \"🛑 Servicios detenidos\" ; echo \"[Enter para cerrar]\"; read'")
    , ("Docker: Prune (Limpieza)",      spawn "ghostty -e sh -c 'docker system prune -f && echo && echo \"🧹 Limpieza completada\" ; echo \"[Enter para cerrar]\"; read'")
    -- Git (verifica si el directorio actual es un repo git antes de ejecutar)
    , ("Git: Status",                   spawn "ghostty -e sh -c 'git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo \"No es un repositorio git. Directorio: $(pwd)\"; echo; echo \"[Enter para cerrar]\"; read; exit 1; }; git status; echo; echo \"[Enter para cerrar]\"; read'")
    , ("Git: Log (últimos 20)",         spawn "ghostty -e sh -c 'git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo \"No es un repositorio git. Directorio: $(pwd)\"; echo; echo \"[Enter para cerrar]\"; read; exit 1; }; git log --oneline --graph -20; echo; echo \"[Enter para cerrar]\"; read'")
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
devXPConfig = promptConfig "#50fa7b" "#282a36" "#50fa7b"

-- Menú de herramientas de desarrollo
devMenu :: X ()
devMenu = runStaticPromptMenu " DevTools: " devXPConfig devOptions id
