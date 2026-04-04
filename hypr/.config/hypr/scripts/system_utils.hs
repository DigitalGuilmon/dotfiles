#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcess, spawnCommand)
import System.Exit (exitSuccess)
import Data.List (isInfixOf)
import Control.Monad (unless)

-- Configuración estética
theme = "~/.config/rofi/themes/modern.rasi"

-- Iconos (Nerd Fonts)
iconMonitor = "󰍹"
iconSearch  = "󰍉"
iconKill    = "󰆙"
iconPower   = "󰐥"
iconBack    = "󰁮"

main :: IO ()
main = mainMenu

mainMenu :: IO ()
mainMenu = do
    let options = iconMonitor ++ " Monitores\n" ++ 
                  iconSearch  ++ " Buscar Archivos\n" ++ 
                  iconKill    ++ " Matar Proceso\n" ++ 
                  iconPower   ++ " Sesión Hyprland"
    selection <- rofi "Sistema" options
    case selection of
        _ | "Monitores" `isInfixOf` selection -> monitorsMenu
        _ | "Buscar"    `isInfixOf` selection -> searchMenu
        _ | "Matar"     `isInfixOf` selection -> killMenu
        _ | "Sesión"    `isInfixOf` selection -> sessionMenu
        _ -> exitSuccess

monitorsMenu :: IO ()
monitorsMenu = do
    -- Obtiene info básica de monitores vía hyprctl
    monInfo <- readProcess "hyprctl" ["monitors"] ""
    let options = "Recargar Configuración\nEspejar Pantallas (Toggle)\n" ++ iconBack ++ " Volver"
    selection <- rofi "Gestión de Monitores" options
    case selection of
        "Recargar Configuración" -> spawnCommand "hyprctl reload"
        "Espejar Pantallas (Toggle)" -> spawnCommand "hyprctl keyword monitor ,preferred,auto,1,mirror,eDP-1" 
        "Volver" -> mainMenu
        _ -> exitSuccess

searchMenu :: IO ()
searchMenu = do
    -- Usa 'fd' para buscar en el Home (omitiendo carpetas ocultas para velocidad)
    -- Al seleccionar, abre con xdg-open
    spawnCommand "fd . $HOME --exclude '.*' | rofi -dmenu -p 'Abrir' -theme ~/.config/rofi/themes/modern.rasi | xargs -r xdg-open"
    exitSuccess

killMenu :: IO ()
killMenu = do
    -- Lista procesos del usuario actual
    processes <- readProcess "ps" ["-u", "elsadeveloper", "-o", "comm"] ""
    selection <- rofi "Matar Proceso" (processes ++ iconBack ++ " Volver")
    unless (null selection || "Volver" `isInfixOf` selection) $ do
        spawnCommand $ "pkill -9 " ++ selection
        spawnCommand $ "notify-send 'Sistema' 'Proceso " ++ selection ++ " terminado'"
    if "Volver" `isInfixOf` selection then mainMenu else exitSuccess

sessionMenu :: IO ()
sessionMenu = do
    let options = "Bloquear Pantalla\nCerrar Sesión Hyprland\nReiniciar\nApagar\n" ++ iconBack ++ " Volver"
    selection <- rofi "Sesión" options
    case selection of
        "Bloquear Pantalla"     -> spawnCommand "hyprlock"
        "Cerrar Sesión Hyprland" -> spawnCommand "hyprctl dispatch exit"
        "Reiniciar"             -> spawnCommand "reboot"
        "Apagar"                -> spawnCommand "shutdown now"
        "Volver"                -> mainMenu
        _                       -> exitSuccess

-- Función auxiliar para rofi
rofi :: String -> String -> IO String
rofi prompt opts = do
    res <- readProcess "rofi" ["-dmenu", "-i", "-p", prompt, "-theme", theme] opts
    return $ if null res then "" else init res
