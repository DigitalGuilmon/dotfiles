#!/usr/bin/env -S sh -c 'script_dir=$(dirname "$1"); exec runhaskell -i"$script_dir" -i"$script_dir/.." "$1" "$@"' sh
{-# LANGUAGE OverloadedStrings #-}

import System.Process (spawnCommand)
import System.Exit (exitSuccess)
import Control.Monad (void, unless)

import StandaloneUtils (notifySend, rofiLines, rofiSelection)

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

safeSpawn :: String -> IO ()
safeSpawn cmd = void $ spawnCommand cmd

notify :: String -> String -> IO ()
notify title msg = notifySend [title, msg]

-- ==========================================
-- MOTOR DE MENÚS
-- ==========================================

type MenuOption = (String, IO ())

runMenu :: String -> String -> [MenuOption] -> IO ()
runMenu menuId prompt options = do
    selection <- rofiLines menuId prompt ["-i"] (map fst options)
    case lookup selection options of
        Just action -> action
        Nothing     -> exitSuccess 

confirmAction :: String -> IO () -> IO ()
confirmAction warningMsg action = do
    let prompt = iconWarn ++ " " ++ warningMsg ++ " - ¿Seguro?"
    selection <- rofiLines "hypr-system-confirm" prompt ["-i"] ["Sí", "No"]
    if selection == "Sí" then action else exitSuccess

-- ==========================================
-- DEFINICIÓN DE MENÚS
-- ==========================================

main :: IO ()
main = mainMenu

mainMenu :: IO ()
mainMenu = runMenu "hypr-system-main" "Sistema"
    [ (iconMonitor ++ " Monitores",                monitorsMenu)
    , (iconFolder  ++ " Archivos y Búsqueda (FZF)", filesMenu)
    , (iconKill    ++ " Matar Proceso (FZF)",        killMenu)
    , (iconPower   ++ " Sesión Hyprland",            sessionMenu)
    ]

filesMenu :: IO ()
filesMenu = runMenu "hypr-system-files" "Archivos"
    [ (iconFolder ++ " Explorador (Ranger)",         safeSpawn "ghostty -e ranger" >> exitSuccess)
    , (iconSearch ++ " Buscar por Nombre (fd)",      searchByName)
    , (iconText   ++ " Buscar por Contenido (rg)",   searchByContent)
    , (iconBack   ++ " Volver",                      mainMenu)
    ]

monitorsMenu :: IO ()
monitorsMenu = runMenu "hypr-system-monitors" "Gestión de Monitores"
    [ ("Recargar Configuración",      safeSpawn "hyprctl reload" >> exitSuccess)
    , ("Espejar Pantallas (Toggle)",  safeSpawn "hyprctl keyword monitor ,preferred,auto,1,mirror,eDP-1" >> exitSuccess)
    , (iconBack ++ " Volver",          mainMenu)
    ]

sessionMenu :: IO ()
sessionMenu = runMenu "hypr-system-session" "Sesión"
    [ ("Bloquear Pantalla",      safeSpawn "hyprlock" >> exitSuccess)
    , ("Cerrar Sesión Hyprland", confirmAction "Cerrar sesión" $ safeSpawn "hyprctl dispatch exit" >> exitSuccess)
    , ("Reiniciar",              confirmAction "Reiniciar PC"  $ safeSpawn "reboot" >> exitSuccess)
    , ("Apagar",                 confirmAction "Apagar PC"      $ safeSpawn "shutdown now" >> exitSuccess)
    , (iconBack ++ " Volver",    mainMenu)
    ]

searchByName :: IO ()
searchByName = do
    safeSpawn "ghostty -e bash -c \"fd . $HOME --type f --hidden --exclude '.git' | fzf --prompt='Abrir> ' --layout=reverse --border | xargs -r xdg-open\""
    exitSuccess

searchByContent :: IO ()
searchByContent = do
    query <- rofiSelection "hypr-system-search-content" "Texto a buscar" ["-i"] ""
    unless (null query) $ do
        let rgCmd = "rg -l -i '" ++ query ++ "' $HOME"
        let fzfCmd = "ghostty -e bash -c \"" ++ rgCmd ++ " | fzf --prompt='Resultados> ' --preview 'cat {}' --layout=reverse --border | xargs -r xdg-open\""
        safeSpawn fzfCmd
        exitSuccess

killMenu :: IO ()
killMenu = do
    let fzfKill = "ghostty -e bash -c \"ps -u $USER -o pid,comm | fzf --prompt='Matar Proceso> ' --header='Selecciona para terminar (Esc para salir)' --layout=reverse --border | awk '{print \\$1}' | xargs -r kill -9\""
    safeSpawn fzfKill
    exitSuccess
