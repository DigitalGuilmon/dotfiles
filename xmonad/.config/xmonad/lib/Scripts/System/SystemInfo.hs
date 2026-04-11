module Scripts.System.SystemInfo (systemInfo) where

import XMonad
import XMonad.Util.Run (runProcessWithInput)
import Variables (myThemeAbs)

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
    theme <- myThemeAbs
    selection <- runProcessWithInput "rofi"
        ["-dmenu", "-p", "SysInfo:", "-theme", theme, "-i"] infoOptions
    let res = filter (/= '\n') selection
    case res of
        "CPU y Carga del sistema" -> spawn "notify-send '🖥️ CPU' \"$(top -bn1 | head -5 | tail -3)\""
        "Memoria RAM"             -> spawn "notify-send '🧠 RAM' \"$(free -h | head -2)\""
        "Uso de Disco"            -> spawn "notify-send '💾 Disco' \"$(df -h / /home 2>/dev/null | column -t)\""
        "Info de Red"             -> spawn "notify-send '🌐 Red' \"IP Local: $(hostname -I | awk '{print $1}')\\nIP Pública: $(curl -s --max-time 5 ifconfig.me || echo 'No disponible')\\nDNS: $(cat /etc/resolv.conf | grep nameserver | head -1)\""
        "Uptime"                  -> spawn "notify-send '⏱️ Uptime' \"$(uptime -p)\""
        "Kernel y OS"             -> spawn "notify-send '🐧 Sistema' \"Kernel: $(uname -r)\\nOS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')\\nArch: $(uname -m)\""
        "GPU"                     -> spawn "notify-send '🎮 GPU' \"$(lspci | grep -i vga)\""
        "Paquetes instalados"     -> spawn "notify-send '📦 Paquetes' \"Pacman: $(pacman -Q 2>/dev/null | wc -l)\\nAUR: $(pacman -Qm 2>/dev/null | wc -l)\\nFlatpak: $(flatpak list 2>/dev/null | wc -l)\""
        "Servicios activos"       -> spawn "notify-send '⚙️ Servicios' \"$(systemctl list-units --type=service --state=running --no-pager --no-legend | head -10)\""
        _                         -> return ()
