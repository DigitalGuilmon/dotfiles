#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcess, spawnCommand)
import System.Exit (exitSuccess)
import Data.List (isInfixOf)

-- Configuración
theme = "~/.config/rofi/themes/modern.rasi"

-- Iconos
iconWifi = "󰖩"
iconBt   = "󰂯"
iconVpn  = "󱚽"

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
    status <- readProcess "nmcli" ["radio", "wifi"] ""
    let toggle = if "enabled" `isInfixOf` status then "Desactivar Wi-Fi" else "Activar Wi-Fi"
    selection <- rofi "Wi-Fi" (toggle ++ "\nVolver")
    case selection of
        "Activar Wi-Fi"   -> spawnCommand "nmcli radio wifi on"
        "Desactivar Wi-Fi" -> spawnCommand "nmcli radio wifi off"
        "Volver"           -> mainMenu
        _                  -> exitSuccess

btMenu :: IO ()
btMenu = do
    status <- readProcess "bluetoothctl" ["show"] ""
    let toggle = if "Powered: yes" `isInfixOf` status then "Desactivar Bluetooth" else "Activar Bluetooth"
    selection <- rofi "Bluetooth" (toggle ++ "\nVolver")
    case selection of
        "Activar Bluetooth"    -> spawnCommand "bluetoothctl power on"
        "Desactivar Bluetooth" -> spawnCommand "bluetoothctl power off"
        "Volver"               -> mainMenu
        _                      -> exitSuccess

vpnMenu :: IO ()
vpnMenu = do
    -- Lista solo conexiones VPN configuradas
    vpns <- readProcess "nmcli" ["-t", "-f", "NAME,TYPE", "connection", "show"] ""
    let vpnList = unlines [line | line <- lines vpns, "vpn" `isInfixOf` line || "wireguard" `isInfixOf` line]
    selection <- rofi "VPN" (vpnList ++ "Volver")
    if selection == "Volver" || null selection
        then mainMenu
        else spawnCommand $ "nmcli connection up " ++ (head $ lines selection)

rofi :: String -> String -> IO String
rofi prompt opts = do
    res <- readProcess "rofi" ["-dmenu", "-i", "-p", prompt, "-theme", theme] opts
    return $ init res -- Elimina el newline final
