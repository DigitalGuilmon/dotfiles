#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcessWithExitCode, spawnCommand)
import System.Exit (exitSuccess, ExitCode(..))
import System.Directory (getHomeDirectory)
import Control.Exception (catch, IOException)
import Control.Monad (void, unless)
import Data.Char (isSpace)
import Data.List (dropWhileEnd, isPrefixOf)

-- ==========================================
-- ICONOS (Nerd Fonts)
-- ==========================================
icDocker = "\xf0239" -- Logo Docker
icBox    = "\xf0a37" -- Contenedor
icPlay   = "\xf04b5" -- Start
icStop   = "\xf04db" -- Stop
icTrash  = "\xf01f0" -- Eliminar
icLogs   = "\xf15c"  -- Logs
icPrune  = "\xf0ad"  -- Herramienta/Limpieza
icBack   = "\xf006e"

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

notify :: String -> String -> IO ()
notify title msg = void $ spawnCommand $ "notify-send -a 'Docker Menu' '" ++ title ++ "' '" ++ msg ++ "'"

-- ==========================================
-- LÓGICA PRINCIPAL
-- ==========================================

main :: IO ()
main = dockerMainMenu

dockerMainMenu :: IO ()
dockerMainMenu = do
    let options = [ (icBox   ++ " Gestionar Contenedores", listContainersMenu)
                  , (icPrune ++ " Limpieza (System Prune)", confirmPrune)
                  , (icDocker ++ " Docker Compose Up (CWD)", void $ spawnCommand "ghostty -e 'docker-compose up'")
                  ]
    let optsStr = unlines $ map fst options
    selection <- rofi "Docker Manager" optsStr
    case lookup selection options of
        Just action -> action
        Nothing     -> exitSuccess

-- 1. LISTAR CONTENEDORES
listContainersMenu :: IO ()
listContainersMenu = do
    -- Obtenemos ID, Nombre y Status
    (exitCode, out, _) <- readProcessWithExitCode "docker" ["ps", "-a", "--format", "{{.Names}} | {{.Status}} | {{.ID}}"] ""
    if exitCode /= ExitSuccess || null out
        then notify "Error" "No se pudieron listar los contenedores o Docker no está corriendo."
        else do
            let containers = lines out
            selection <- rofi "Seleccionar Contenedor" (unlines containers ++ icBack ++ " Volver")
            if selection == (icBack ++ " Volver") || null selection
                then dockerMainMenu
                else handleContainerSelection selection

-- 2. ACCIONES SOBRE UN CONTENEDOR
handleContainerSelection :: String -> IO ()
handleContainerSelection rawLine = do
    let parts = words rawLine
    case parts of
      [] -> listContainersMenu
      (cName:rest) -> do
        let cID = case reverse rest of   -- El ID está al final por el formato configurado arriba
                    (x:_) -> x
                    []    -> cName
    
        let actions = [ (icPlay  ++ " Start",    dockerCmd "start" cID cName)
                      , (icStop  ++ " Stop",     dockerCmd "stop"  cID cName)
                      , (icLogs  ++ " Ver Logs", void $ spawnCommand $ "ghostty -e 'docker logs -f " ++ cID ++ "'")
                      , (icTrash ++ " Eliminar", dockerCmd "rm -f" cID cName)
                      , (icBack  ++ " Volver",   listContainersMenu)
                      ]
    
        selection <- rofi ("Contenedor: " ++ cName) (unlines $ map fst actions)
        case lookup selection actions of
            Just action -> action
            Nothing     -> listContainersMenu

-- 3. EJECUTOR DE COMANDOS DOCKER
dockerCmd :: String -> String -> String -> IO ()
dockerCmd cmd cID cName = do
    (exitCode, _, err) <- readProcessWithExitCode "docker" (words cmd ++ [cID]) ""
    if exitCode == ExitSuccess
        then notify "Docker" (cmd ++ " exitoso: " ++ cName)
        else notify "Error Docker" err
    listContainersMenu

-- 4. CONFIRMACIÓN DE PRUNE
confirmPrune :: IO ()
confirmPrune = do
    selection <- rofi "Eliminar todo lo que no se usa (Prune)?" "No\nSí"
    if selection == "Sí"
        then do
            void $ spawnCommand "docker system prune -f"
            notify "Docker" "Sistema limpiado"
        else dockerMainMenu
