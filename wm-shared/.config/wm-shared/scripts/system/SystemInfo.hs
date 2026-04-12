module Scripts.System.SystemInfo (systemInfo) where

import XMonad
import Scripts.Utils (rofiSelect)

infoOptions :: String
infoOptions = unlines
    [ "CPU y Carga del sistema"
    , "Memoria RAM"
    , "Uso de Disco"
    , "Info de Red"
    , "Uptime"
    , "Kernel y OS"
    , "GPU"
    , "Paquetes instalados"
    , "Servicios activos"
    ]

-- Dashboard de información del sistema usando rofi
-- Muestra la info seleccionada con notify-send
systemInfo :: X ()
systemInfo = do
    res <- rofiSelect "xmonad-system-info" "SysInfo:" ["-i"] infoOptions
    case res of
        "CPU y Carga del sistema" -> spawn "notify-send '🖥️ CPU' \"$(top -bn1 | head -5 | tail -3)\""
        "Memoria RAM"             -> spawn "notify-send '🧠 RAM' \"$(free -h | head -2)\""
        "Uso de Disco"            -> spawn "notify-send '💾 Disco' \"$(df -h / /home 2>/dev/null | column -t)\""
        "Info de Red"             -> spawn "body=$(printf 'IP Local: %s\\nIP Pública: %s\\nDNS: %s' \"$(hostname -I | awk '{print $1}')\" \"$(curl -s --max-time 5 ifconfig.me || echo 'No disponible')\" \"$(cat /etc/resolv.conf | grep nameserver | head -1)\") && notify-send '🌐 Red' \"$body\""
        "Uptime"                  -> spawn "notify-send '⏱️ Uptime' \"$(uptime -p)\""
        "Kernel y OS"             -> spawn "body=$(printf 'Kernel: %s\\nOS: %s\\nArch: %s' \"$(uname -r)\" \"$(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')\" \"$(uname -m)\") && notify-send '🐧 Sistema' \"$body\""
        "GPU"                     -> spawn "notify-send '🎮 GPU' \"$(lspci | grep -i vga)\""
        "Paquetes instalados"     -> spawn "body=$(printf 'Pacman: %s\\nAUR: %s\\nFlatpak: %s' \"$(pacman -Q 2>/dev/null | wc -l)\" \"$(pacman -Qm 2>/dev/null | wc -l)\" \"$(flatpak list 2>/dev/null | wc -l)\") && notify-send '📦 Paquetes' \"$body\""
        "Servicios activos"       -> spawn "notify-send '⚙️ Servicios' \"$(systemctl list-units --type=service --state=running --no-pager --no-legend | head -10)\""
        _                         -> return ()
