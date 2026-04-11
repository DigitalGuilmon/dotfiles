module Scripts.Network.NetworkMenu (networkMenu) where

import XMonad
import XMonad.Prompt
import XMonad.Prompt.FuzzyMatch (fuzzyMatch)

import Variables (myTheme)

data NetworkPrompt = NetworkPrompt

instance XPrompt NetworkPrompt where
    showXPrompt NetworkPrompt = " Red: "
    commandToComplete _ c = c
    nextCompletion _ = getNextCompletion

-- Usa printf '%q' para escapar valores dinámicos (SSID/VPN) contra inyección shell
networkOptions :: [(String, X ())]
networkOptions =
    [ ("1. WiFi: Escanear y Conectar",  spawn $ "nmcli device wifi rescan && notify-send '📡 WiFi' 'Escaneando...' && sleep 2 && SSID=$(nmcli -t -f SSID device wifi list | sort -u | rofi -dmenu -p 'WiFi SSID:' -theme " ++ myTheme ++ ") && [ -n \"$SSID\" ] && ghostty -e sh -c 'exec nmcli device wifi connect \"$0\" --ask' \"$SSID\"")
    , ("2. WiFi: Activar",             spawn "nmcli radio wifi on && notify-send '📶 WiFi' 'Activado'")
    , ("3. WiFi: Desactivar",          spawn "nmcli radio wifi off && notify-send '📴 WiFi' 'Desactivado'")
    , ("4. WiFi: Estado Actual",        spawn "notify-send '🌐 Red' \"$(nmcli -t -f NAME,DEVICE connection show --active)\"")
    , ("5. VPN: Conectar",             spawn $ "VPN=$(nmcli -t -f NAME,TYPE connection show | grep vpn | cut -d: -f1 | rofi -dmenu -p 'VPN:' -theme " ++ myTheme ++ ") && [ -n \"$VPN\" ] && nmcli connection up id \"$VPN\" && notify-send '🔒 VPN' \"Conectado a $VPN\"")
    , ("6. VPN: Desconectar",          spawn $ "VPN=$(nmcli -t -f NAME,TYPE connection show --active | grep vpn | cut -d: -f1 | rofi -dmenu -p 'Desconectar VPN:' -theme " ++ myTheme ++ ") && [ -n \"$VPN\" ] && nmcli connection down id \"$VPN\" && notify-send '🔓 VPN' \"Desconectado de $VPN\"")
    , ("7. IP Pública",                spawn "notify-send '🌍 IP Pública' \"$(curl -s ifconfig.me)\"")
    , ("8. Ping Test",                 spawn "notify-send '🏓 Ping' \"$(ping -c 3 8.8.8.8 2>&1 | tail -1)\"")
    ]

networkXPConfig :: XPConfig
networkXPConfig = def
    { font              = "xft:JetBrainsMono Nerd Font:size=11"
    , bgColor           = "#282a36"
    , fgColor           = "#f8f8f2"
    , bgHLight          = "#8be9fd"
    , fgHLight          = "#282a36"
    , borderColor       = "#8be9fd"
    , promptBorderWidth = 2
    , position          = CenteredAt 0.5 0.5
    , height            = 50
    , alwaysHighlight   = True
    , searchPredicate   = fuzzyMatch
    }

-- Menú de gestión de red y conectividad
networkMenu :: X ()
networkMenu = mkXPrompt NetworkPrompt networkXPConfig
    (mkComplFunFromList' networkXPConfig (map fst networkOptions))
    (\selection -> case lookup selection networkOptions of
        Just action -> action
        Nothing     -> return ()
    )
