#!/usr/bin/env -S sh -c 'script_dir=$(dirname "$1"); exec runhaskell -i"$script_dir" -i"$script_dir/.." "$1" "$@"' sh
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcessWithExitCode, spawnCommand)
import System.Exit (exitSuccess, ExitCode(..))
import Control.Monad (void)

import StandaloneUtils (notifySend, rofiLines)

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

notify :: String -> String -> IO ()
notify title msg = notifySend ["-a", "Docker Menu", title, msg]

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
    selection <- rofiLines "hypr-docker-main" "Docker Manager" ["-i"] (map fst options)
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
            let back = icBack ++ " Volver"
            selection <- rofiLines "hypr-docker-containers" "Seleccionar Contenedor" ["-i"] (containers ++ [back])
            if selection == (icBack ++ " Volver") || null selection
                then dockerMainMenu
                else handleContainerSelection selection

-- 2. ACCIONES SOBRE UN CONTENEDOR
handleContainerSelection :: String -> IO ()
handleContainerSelection rawLine = do
    let parts = words rawLine
    let cName = head parts
    let cID   = last parts -- El ID está al final por el formato configurado arriba
    
    let actions = [ (icPlay  ++ " Start",    dockerCmd "start" cID cName)
                  , (icStop  ++ " Stop",     dockerCmd "stop"  cID cName)
                  , (icLogs  ++ " Ver Logs", void $ spawnCommand $ "ghostty -e 'docker logs -f " ++ cID ++ "'")
                  , (icTrash ++ " Eliminar", dockerCmd "rm -f" cID cName)
                  , (icBack  ++ " Volver",   listContainersMenu)
                  ]
    
    selection <- rofiLines "hypr-docker-actions" ("Contenedor: " ++ cName) ["-i"] (map fst actions)
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
    selection <- rofiLines "hypr-docker-prune-confirm" "Eliminar todo lo que no se usa (Prune)?" ["-i"] ["No", "Sí"]
    if selection == "Sí"
        then do
            void $ spawnCommand "docker system prune -f"
            notify "Docker" "Sistema limpiado"
        else dockerMainMenu
