#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcessWithExitCode, spawnCommand)
import System.Exit (exitSuccess, ExitCode(..))
import System.Directory (getHomeDirectory)
import System.Environment (getEnv)
import Control.Exception (catch, IOException)
import Control.Monad (void)

-- Iconos (Nerd Fonts)
iconMonitor = "\xf0379"
iconSearch  = "\xf0349"
iconKill    = "\xf0199"
iconPower   = "\xf0425"
iconBack    = "\xf006e"
iconFolder  = "\xf007b"
iconText    = "\xf15c"
iconWarn    = "\xf071"

-- ==========================================
-- MOTOR CORE (Abstracción de Menús)
-- ==========================================

-- Define qué es una opción de menú: Un texto visible y una acción a ejecutar
type MenuOption = (String, IO ())

-- Genera el menú en Rofi y ejecuta la acción seleccionada mágicamente
runMenu :: String -> [MenuOption] -> IO ()
runMenu prompt options = do
    let optsStr = unlines $ map fst options
    selection <- rofi prompt optsStr
    case lookup selection options of
        Just action -> action
        Nothing     -> exitSuccess -- Si presiona Esc o escribe algo inválido

-- Cuadro de diálogo de confirmación
confirmAction :: String -> IO () -> IO ()
confirmAction warningMsg action = do
    let prompt = iconWarn ++ " " ++ warningMsg ++ " - ¿Seguro?"
    selection <- rofi prompt "Sí\nNo"
    if selection == "Sí" then action else exitSuccess

-- ==========================================
-- DEFINICIÓN DE MENÚS (Totalmente declarativo)
-- ==========================================

main :: IO ()
main = mainMenu

mainMenu :: IO ()
mainMenu = runMenu "Sistema"
    [ (iconMonitor ++ " Monitores",                  monitorsMenu)
    , (iconFolder  ++ " Archivos y Búsqueda (FZF)",  filesMenu)
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
    [ ("Recargar Configuración",     safeSpawn "hyprctl reload" >> exitSuccess)
    , ("Espejar Pantallas (Toggle)", safeSpawn "hyprctl keyword monitor ,preferred,auto,1,mirror,eDP-1" >> exitSuccess)
    , (iconBack ++ " Volver",        mainMenu)
    ]

sessionMenu :: IO ()
sessionMenu = runMenu "Sesión"
    [ ("Bloquear Pantalla",      safeSpawn "hyprlock" >> exitSuccess)
    , ("Cerrar Sesión Hyprland", confirmAction "Cerrar sesión" $ safeSpawn "hyprctl dispatch exit" >> exitSuccess)
    , ("Reiniciar",              confirmAction "Reiniciar PC"  $ safeSpawn "reboot" >> exitSuccess)
    , ("Apagar",                 confirmAction "Apagar PC"     $ safeSpawn "shutdown now" >> exitSuccess)
    , (iconBack ++ " Volver",    mainMenu)
    ]

-- ==========================================
-- ACCIONES COMPLEJAS AISLADAS
-- ==========================================

searchByName :: IO ()
searchByName = do
    safeSpawn "ghostty -e bash -c \"fd . $HOME --type f --hidden --exclude '.git' | fzf --prompt='Abrir> ' --layout=reverse --border | xargs -r xdg-open\""
    exitSuccess

searchByContent :: IO ()
searchByContent = do
    query <- rofi "Texto a buscar" ""
    if null query 
        then exitSuccess
        else do
            let rgCmd = "rg -l -i '" ++ query ++ "' $HOME"
            let fzfCmd = "ghostty -e bash -c \"" ++ rgCmd ++ " | fzf --prompt='Resultados> ' --preview 'cat {}' --layout=reverse --border | xargs -r xdg-open\""
            safeSpawn fzfCmd
            exitSuccess

killMenu :: IO ()
killMenu = do
    let fzfKill = "ghostty -e bash -c \"ps -u $USER -o pid,comm | fzf --prompt='Matar Proceso> ' --header='Selecciona para terminar (Esc para salir)' --layout=reverse --border | awk '{print \\$1}' | xargs -r kill -9\""
    safeSpawn fzfKill
    exitSuccess

-- ==========================================
-- WRAPPERS DE EJECUCIÓN (Anti-Crashes)
-- ==========================================

rofi :: String -> String -> IO String
rofi prompt opts = do
    home <- getHomeDirectory
    let theme = home ++ "/.config/rofi/themes/modern.rasi"
    res <- safeReadProcess "rofi" ["-dmenu", "-i", "-p", prompt, "-theme", theme] opts
    return $ if null res then "" else init res

safeSpawn :: String -> IO ()
safeSpawn cmd = catch (void $ spawnCommand cmd) handler
  where
    handler :: IOException -> IO ()
    handler _ = void $ spawnCommand ("notify-send 'Error' 'Fallo: " ++ cmd ++ "'")

safeReadProcess :: String -> [String] -> String -> IO String
safeReadProcess cmd args input = catch runCmd handler
  where
    runCmd = do
        (exitCode, out, _) <- readProcessWithExitCode cmd args input
        case exitCode of
            ExitSuccess   -> return out
            ExitFailure _ -> return ""
    handler :: IOException -> IO String
    handler _ = return ""
