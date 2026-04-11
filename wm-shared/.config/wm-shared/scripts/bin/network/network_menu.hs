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

import System.Process (readProcessWithExitCode)
import Data.List (isInfixOf)

import Standalone.Menu (MenuSpec (..), menuEntry, runMenuSpec, selectMenuSpec)
import StandaloneUtils (shellEscape, spawnCommand_)

-- Iconos
iconWifi = "\xf05a9"
iconBt   = "\xf00af"
iconVpn  = "\xf16bd"

main :: IO ()
main = mainMenu

mainMenu :: IO ()
mainMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "hypr-network-main"
            , menuSpecPrompt = "Redes"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry (iconWifi ++ " Wi-Fi") wifiMenu
                , menuEntry (iconBt ++ " Bluetooth") btMenu
                , menuEntry (iconVpn ++ " VPN") vpnMenu
                ]
            }

wifiMenu :: IO ()
wifiMenu = do
    (_, status, _) <- readProcessWithExitCode "nmcli" ["radio", "wifi"] ""
    let toggleLabel = if "enabled" `isInfixOf` status then "Desactivar Wi-Fi" else "Activar Wi-Fi"
        toggleCommand = if toggleLabel == "Activar Wi-Fi" then "nmcli radio wifi on" else "nmcli radio wifi off"
    runMenuSpec $
        MenuSpec
            { menuSpecId = "hypr-network-wifi"
            , menuSpecPrompt = "Wi-Fi"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry toggleLabel (spawnCommand_ toggleCommand)
                , menuEntry "Volver" mainMenu
                ]
            }

btMenu :: IO ()
btMenu = do
    (_, status, _) <- readProcessWithExitCode "bluetoothctl" ["show"] ""
    let toggleLabel = if "Powered: yes" `isInfixOf` status then "Desactivar Bluetooth" else "Activar Bluetooth"
        toggleCommand = if toggleLabel == "Activar Bluetooth" then "bluetoothctl power on" else "bluetoothctl power off"
    runMenuSpec $
        MenuSpec
            { menuSpecId = "hypr-network-bluetooth"
            , menuSpecPrompt = "Bluetooth"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry toggleLabel (spawnCommand_ toggleCommand)
                , menuEntry "Volver" mainMenu
                ]
            }

vpnMenu :: IO ()
vpnMenu = do
    (_, vpns, _) <- readProcessWithExitCode "nmcli" ["-t", "-f", "NAME,TYPE", "connection", "show"] ""
    let vpnList = [line | line <- lines vpns, "vpn" `isInfixOf` line || "wireguard" `isInfixOf` line]
        entries =
            map (\entry -> menuEntry entry (spawnCommand_ ("nmcli connection up " ++ shellEscape (takeWhile (/= ':') entry)))) vpnList
                ++ [menuEntry "Volver" mainMenu]
    runMenuSpec $
        MenuSpec
            { menuSpecId = "hypr-network-vpn"
            , menuSpecPrompt = "VPN"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries = entries
            }
