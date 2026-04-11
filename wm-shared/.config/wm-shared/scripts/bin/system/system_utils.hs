#!/usr/bin/env sh
#if 0
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
script_root="$script_dir"
while [ ! -d "$script_root/lib" ] && [ "$script_root" != "/" ]; do
    script_root=$(dirname "$script_root")
done
exec runhaskell -XCPP -i"$script_root/lib" "$0" "$@"
#endif
{-# LANGUAGE OverloadedStrings #-}

import Control.Monad (unless)

import Standalone.Menu (MenuSpec (..), menuEntry, runMenuSpec)
import StandaloneUtils (confirmSelection, rofiSelection, spawnCommand_)

-- ==========================================
-- CONFIGURACIÓN E ICONOS
-- ==========================================

iconMonitor = "\xf0379"
iconSearch  = "\xf0349"
iconKill    = "\xf0199"
iconPower   = "\xf0425"
iconBack    = "\xf006e"
iconFolder  = "\xf007b"
iconText    = "\xf15c"
iconWarn    = "\xf071"

confirmAction :: String -> IO () -> IO ()
confirmAction warningMsg action = do
    confirmed <- confirmSelection "hypr-system-confirm" (iconWarn ++ " " ++ warningMsg ++ " - ¿Seguro?")
    if confirmed then action else pure ()

-- ==========================================
-- DEFINICIÓN DE MENÚS
-- ==========================================

main :: IO ()
main = mainMenu

mainMenu :: IO ()
mainMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "hypr-system-main"
            , menuSpecPrompt = "Sistema"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry (iconMonitor ++ " Monitores") monitorsMenu
                , menuEntry (iconFolder ++ " Archivos y Búsqueda (FZF)") filesMenu
                , menuEntry (iconKill ++ " Matar Proceso (FZF)") killMenu
                , menuEntry (iconPower ++ " Sesión Hyprland") sessionMenu
                ]
            }

filesMenu :: IO ()
filesMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "hypr-system-files"
            , menuSpecPrompt = "Archivos"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry (iconFolder ++ " Explorador (Ranger)") (spawnCommand_ "ghostty -e ranger")
                , menuEntry (iconSearch ++ " Buscar por Nombre (fd)") searchByName
                , menuEntry (iconText ++ " Buscar por Contenido (rg)") searchByContent
                , menuEntry (iconBack ++ " Volver") mainMenu
                ]
            }

monitorsMenu :: IO ()
monitorsMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "hypr-system-monitors"
            , menuSpecPrompt = "Gestión de Monitores"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry "Recargar Configuración" (spawnCommand_ "hyprctl reload")
                , menuEntry "Espejar Pantallas (Toggle)" (spawnCommand_ "hyprctl keyword monitor ,preferred,auto,1,mirror,eDP-1")
                , menuEntry (iconBack ++ " Volver") mainMenu
                ]
            }

sessionMenu :: IO ()
sessionMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "hypr-system-session"
            , menuSpecPrompt = "Sesión"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry "Bloquear Pantalla" (spawnCommand_ "hyprlock")
                , menuEntry "Cerrar Sesión Hyprland" (confirmAction "Cerrar sesión" $ spawnCommand_ "hyprctl dispatch exit")
                , menuEntry "Reiniciar" (confirmAction "Reiniciar PC" $ spawnCommand_ "reboot")
                , menuEntry "Apagar" (confirmAction "Apagar PC" $ spawnCommand_ "shutdown now")
                , menuEntry (iconBack ++ " Volver") mainMenu
                ]
            }

searchByName :: IO ()
searchByName = do
    spawnCommand_ "ghostty -e bash -c \"fd . $HOME --type f --hidden --exclude '.git' | fzf --prompt='Abrir> ' --layout=reverse --border | xargs -r xdg-open\""

searchByContent :: IO ()
searchByContent = do
    query <- rofiSelection "hypr-system-search-content" "Texto a buscar" ["-i"] ""
    unless (null query) $ do
        let rgCmd = "rg -l -i '" ++ query ++ "' $HOME"
        let fzfCmd = "ghostty -e bash -c \"" ++ rgCmd ++ " | fzf --prompt='Resultados> ' --preview 'cat {}' --layout=reverse --border | xargs -r xdg-open\""
        spawnCommand_ fzfCmd

killMenu :: IO ()
killMenu = do
    let fzfKill = "ghostty -e bash -c \"ps -u $USER -o pid,comm | fzf --prompt='Matar Proceso> ' --header='Selecciona para terminar (Esc para salir)' --layout=reverse --border | awk '{print \\$1}' | xargs -r kill -9\""
    spawnCommand_ fzfKill
