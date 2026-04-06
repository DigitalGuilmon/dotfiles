#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcessWithExitCode, spawnCommand)
import System.Exit (exitSuccess, ExitCode(..))
import System.Directory (getHomeDirectory)
import Control.Exception (catch, IOException)
import Control.Monad (void, unless)
import Data.Char (isSpace)
import Data.List (dropWhileEnd)

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

-- ==========================================
-- HELPERS
-- ==========================================

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace

rofi :: String -> String -> IO String
rofi prompt opts = do
    home <- getHomeDirectory
    let theme = home ++ "/.config/rofi/themes/modern.rasi"
    (exitCode, out, _) <- catch (readProcessWithExitCode "rofi" ["-dmenu", "-i", "-p", prompt, "-theme", theme] opts)
                                (\(_ :: IOException) -> return (ExitFailure 1, "", ""))
    return $ trim out

safeSpawn :: String -> IO ()
safeSpawn cmd = void $ spawnCommand cmd

notify :: String -> String -> IO ()
notify title msg = void $ spawnCommand $ "notify-send '" ++ title ++ "' '" ++ msg ++ "'"

-- ==========================================
-- MOTOR DE MENÚS
-- ==========================================

type MenuOption = (String, IO ())

runMenu :: String -> [MenuOption] -> IO ()
runMenu prompt options = do
    let optsStr = unlines $ map fst options
    selection <- rofi prompt optsStr
    case lookup selection options of
        Just action -> action
        Nothing     -> exitSuccess 

confirmAction :: String -> IO () -> IO ()
confirmAction warningMsg action = do
    let prompt = iconWarn ++ " " ++ warningMsg ++ " - ¿Seguro?"
    selection <- rofi prompt "Sí\nNo"
    if selection == "Sí" then action else exitSuccess

-- ==========================================
-- DEFINICIÓN DE MENÚS
-- ==========================================

main :: IO ()
main = mainMenu

mainMenu :: IO ()
mainMenu = runMenu "Sistema"
    [ (iconMonitor ++ " Monitores",                monitorsMenu)
    , (iconFolder  ++ " Archivos y Búsqueda (FZF)", filesMenu)
    , (iconKill    ++ " Matar Proceso (FZF)",        killMenu)
    , (iconPower   ++ " Sesión Hyprland",            sessionMenu)
    ]

filesMenu :: IO ()
filesMenu = runMenu "Archivos"
    [ (iconFolder ++ " Explorador (Ranger)",         safeSpawn "ghostty -e ranger" >> exitSuccess)
    , (iconSearch ++ " Buscar por Nombre (fd)",      searchByName)
    , (iconText   ++ " Buscar por Contenido (rg)",   searchByContent)
    , (iconBack   ++ " Volver",                      mainMenu)
    ]

monitorsMenu :: IO ()
monitorsMenu = runMenu "Gestión de Monitores"
    [ ("Recargar Configuración",      safeSpawn "hyprctl reload" >> exitSuccess)
    , ("Espejar Pantallas (Toggle)",  safeSpawn "hyprctl keyword monitor ,preferred,auto,1,mirror,eDP-1" >> exitSuccess)
    , (iconBack ++ " Volver",          mainMenu)
    ]

sessionMenu :: IO ()
sessionMenu = runMenu "Sesión"
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
    query <- rofi "Texto a buscar" ""
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
