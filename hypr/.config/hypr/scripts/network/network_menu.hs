#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcessWithExitCode, spawnCommand)
import System.Exit (exitSuccess)
import Data.List (isInfixOf)
import System.Directory (getHomeDirectory) -- Importante para leer la ruta del HOME

-- Iconos
iconWifi = "\xf05a9"
iconBt   = "\xf00af"
iconVpn  = "\xf16bd"

main :: IO ()
main = mainMenu

mainMenu :: IO ()
mainMenu = do
    let options = iconWifi ++ " Wi-Fi\n" ++ iconBt ++ " Bluetooth\n" ++ iconVpn ++ " VPN"
    selection <- rofi "Redes" options
    case selection of
        _ | "Wi-Fi" `isInfixOf` selection     -> wifiMenu
        _ | "Bluetooth" `isInfixOf` selection -> btMenu
        _ | "VPN" `isInfixOf` selection       -> vpnMenu
        _ -> exitSuccess

wifiMenu :: IO ()
wifiMenu = do
    -- readProcessWithExitCode evita que el script crashee si el comando falla
    (_, status, _) <- readProcessWithExitCode "nmcli" ["radio", "wifi"] ""
    let toggle = if "enabled" `isInfixOf` status then "Desactivar Wi-Fi" else "Activar Wi-Fi"
    selection <- rofi "Wi-Fi" (toggle ++ "\nVolver")
    case selection of
        -- Añadimos >> return () para que el tipo coincida con IO ()
        "Activar Wi-Fi"    -> spawnCommand "nmcli radio wifi on" >> return ()
        "Desactivar Wi-Fi" -> spawnCommand "nmcli radio wifi off" >> return ()
        "Volver"           -> mainMenu
        _                  -> exitSuccess

btMenu :: IO ()
btMenu = do
    (_, status, _) <- readProcessWithExitCode "bluetoothctl" ["show"] ""
    let toggle = if "Powered: yes" `isInfixOf` status then "Desactivar Bluetooth" else "Activar Bluetooth"
    selection <- rofi "Bluetooth" (toggle ++ "\nVolver")
    case selection of
        "Activar Bluetooth"    -> spawnCommand "bluetoothctl power on" >> return ()
        "Desactivar Bluetooth" -> spawnCommand "bluetoothctl power off" >> return ()
        "Volver"               -> mainMenu
        _                      -> exitSuccess

vpnMenu :: IO ()
vpnMenu = do
    (_, vpns, _) <- readProcessWithExitCode "nmcli" ["-t", "-f", "NAME,TYPE", "connection", "show"] ""
    let vpnList = unlines [line | line <- lines vpns, "vpn" `isInfixOf` line || "wireguard" `isInfixOf` line]
    selection <- rofi "VPN" (vpnList ++ "Volver")
    if selection == "Volver" || null selection
        then mainMenu
        else case lines selection of
            (conn:_) -> spawnCommand ("nmcli connection up " ++ conn) >> return ()
            _        -> return ()

rofi :: String -> String -> IO String
rofi prompt opts = do
    home <- getHomeDirectory
    let theme = home ++ "/.config/rofi/themes/modern.rasi" -- Construimos la ruta real
    
    -- Manejo seguro por si rofi se cierra con Escape
    (exitCode, out, _) <- readProcessWithExitCode "rofi" ["-dmenu", "-i", "-p", prompt, "-theme", theme] opts
    
    -- Evita hacer 'init' a una string vacía
    return $ if null out then "" else init out
