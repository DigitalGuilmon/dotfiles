#!/usr/bin/env -S sh -c 'script_dir=$(dirname "$1"); exec runhaskell -i"$script_dir" -i"$script_dir/.." "$1" "$@"' sh
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcessWithExitCode, spawnCommand)
import System.Exit (exitSuccess)
import Data.List (isInfixOf)

import StandaloneUtils (rofiLines)

-- Iconos
iconWifi = "\xf05a9"
iconBt   = "\xf00af"
iconVpn  = "\xf16bd"

main :: IO ()
main = mainMenu

mainMenu :: IO ()
mainMenu = do
    let options = [iconWifi ++ " Wi-Fi", iconBt ++ " Bluetooth", iconVpn ++ " VPN"]
    selection <- rofiLines "hypr-network-main" "Redes" ["-i"] options
    case selection of
        _ | "Wi-Fi" `isInfixOf` selection     -> wifiMenu
        _ | "Bluetooth" `isInfixOf` selection -> btMenu
        _ | "VPN" `isInfixOf` selection       -> vpnMenu
        _ -> exitSuccess

wifiMenu :: IO ()
wifiMenu = do
    (_, status, _) <- readProcessWithExitCode "nmcli" ["radio", "wifi"] ""
    let toggle = if "enabled" `isInfixOf` status then "Desactivar Wi-Fi" else "Activar Wi-Fi"
    selection <- rofiLines "hypr-network-wifi" "Wi-Fi" ["-i"] [toggle, "Volver"]
    case selection of
        "Activar Wi-Fi"    -> spawnCommand "nmcli radio wifi on" >> return ()
        "Desactivar Wi-Fi" -> spawnCommand "nmcli radio wifi off" >> return ()
        "Volver"           -> mainMenu
        _                  -> exitSuccess

btMenu :: IO ()
btMenu = do
    (_, status, _) <- readProcessWithExitCode "bluetoothctl" ["show"] ""
    let toggle = if "Powered: yes" `isInfixOf` status then "Desactivar Bluetooth" else "Activar Bluetooth"
    selection <- rofiLines "hypr-network-bluetooth" "Bluetooth" ["-i"] [toggle, "Volver"]
    case selection of
        "Activar Bluetooth"    -> spawnCommand "bluetoothctl power on" >> return ()
        "Desactivar Bluetooth" -> spawnCommand "bluetoothctl power off" >> return ()
        "Volver"               -> mainMenu
        _                      -> exitSuccess

vpnMenu :: IO ()
vpnMenu = do
    (_, vpns, _) <- readProcessWithExitCode "nmcli" ["-t", "-f", "NAME,TYPE", "connection", "show"] ""
    let vpnList = [line | line <- lines vpns, "vpn" `isInfixOf` line || "wireguard" `isInfixOf` line]
    selection <- rofiLines "hypr-network-vpn" "VPN" ["-i"] (vpnList ++ ["Volver"])
    if selection == "Volver" || null selection
        then mainMenu
        else spawnCommand ("nmcli connection up " ++ head (lines selection)) >> return ()
