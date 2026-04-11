module Common.SystemInfo (systemInfoOptions) where

systemInfoOptions :: [(String, String)]
systemInfoOptions =
    [ ("CPU y Carga del sistema", "notify-send '🖥️ CPU' \"$(top -bn1 | head -5 | tail -3)\"")
    , ("Memoria RAM", "notify-send '🧠 RAM' \"$(free -h | head -2)\"")
    , ("Uso de Disco", "notify-send '💾 Disco' \"$(df -h / /home 2>/dev/null | column -t)\"")
    , ("Info de Red", "body=$(printf 'IP Local: %s\\nIP Pública: %s\\nDNS: %s' \"$(hostname -I | awk '{print $1}')\" \"$(curl -s --max-time 5 ifconfig.me || echo 'No disponible')\" \"$(grep nameserver /etc/resolv.conf | head -1)\") && notify-send '🌐 Red' \"$body\"")
    , ("Uptime", "notify-send '⏱️ Uptime' \"$(uptime -p)\"")
    , ("Kernel y OS", "body=$(printf 'Kernel: %s\\nOS: %s\\nArch: %s' \"$(uname -r)\" \"$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\"')\" \"$(uname -m)\") && notify-send '🐧 Sistema' \"$body\"")
    , ("GPU", "notify-send '🎮 GPU' \"$(lspci | grep -i vga)\"")
    , ("Paquetes instalados", "body=$(printf 'Pacman: %s\\nAUR: %s\\nFlatpak: %s' \"$(pacman -Q 2>/dev/null | wc -l)\" \"$(pacman -Qm 2>/dev/null | wc -l)\" \"$(flatpak list 2>/dev/null | wc -l)\") && notify-send '📦 Paquetes' \"$body\"")
    , ("Servicios activos", "notify-send '⚙️ Servicios' \"$(systemctl list-units --type=service --state=running --no-pager --no-legend | head -10)\"")
    ]
