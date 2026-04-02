Config { 
    -- Apariencia general (Paleta Dracula)
    font = "xft:JetBrainsMono Nerd Font:weight=bold:pixelsize=16:antialias=true:hinting=true",
    additionalFonts = ["xft:JetBrainsMono Nerd Font:pixelsize=20:antialias=true:hinting=true"],
    bgColor = "#282a36",
    fgColor = "#f8f8f2",
    
    -- Posicionamiento (Arriba, 100% ancho, 36px de alto)
    position = TopSize L 100 36,
    lowerOnStart = True,
    hideOnStart = False,
    allDesktops = True,
    persistent = True,
    
    -- Módulos
    commands = [ 
        -- RED / TRÁFICO (Pink color: #ff79c6)
        Run Com "bash" ["-c", "iface=$(ip route | grep default | awk '{print $5}' | head -n1); rx1=$(cat /sys/class/net/$iface/statistics/rx_bytes); sleep 1; rx2=$(cat /sys/class/net/$iface/statistics/rx_bytes); awk -v a=$rx1 -v b=$rx2 'BEGIN {printf \"%.2f MB/s\", (b-a)/1048576}'"] "net" 20,

        -- CPU (Primary color: #bd93f9)
        Run Cpu ["-t", "<fc=#bd93f9> CPU</fc> <total>%", "-H", "50", "-h", "#ff5555"] 20,
        
        -- TEMPERATURA CPU (Orange color: #ffb86c)
        --Run CoreTemp ["-t", "<fc=#ffb86c></fc> <core0>°C", "-L", "40", "-H", "75", "-l", "#50fa7b", "-n", "#f1fa8c", "-h", "#ff5555"] 50,

        -- RAM (Green color: #50fa7b)
        Run Memory ["-t", "<fc=#50fa7b>󰍛 RAM</fc> <usedratio>%"] 20,
        
        -- DISCO RAÍZ (Yellow color: #f1fa8c)
        Run DiskU [("/", "<fc=#f1fa8c>󰋊 Disco</fc> <free>")] [] 60,

        -- ACTUALIZACIONES DEL SISTEMA (Red color: #ff5555)
        Run Com "bash" ["-c", "checkupdates 2>/dev/null | wc -l || echo 0"] "updates" 36000,

        -- VOLUMEN PIPEWIRE (Green color: #50fa7b)
        Run Com "bash" ["-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}' | cut -d'.' -f1 | sed 's/$/%/'"] "vol" 5,

        -- UPTIME / TIEMPO ENCENDIDO (Cyan color: #8be9fd)
        -- Nota: El icono ya está dentro de este comando
        Run Uptime ["-t", "<fc=#8be9fd>󰔟</fc> <days>d <hours>h <minutes>m"] 360,

        -- CLIMA (Orange color: #ffb86c)
        Run Weather "MMMX" ["-t", "<fc=#ffb86c>󰖐</fc> <tempC>°C"] 3600,

        -- FECHA Y HORA (Secondary color: #8be9fd)
        Run Date "<fc=#8be9fd></fc> %d %b - %H:%M" "date" 10,
        
        -- Lector para recibir el título de la ventana desde XMonad
        Run UnsafeStdinReader
    ],
    
    sepChar = "%",
    alignSep = "}{",
    
    -- Plantilla de disposición:
    -- IZQUIERDA: Uptime y Actualizaciones
    -- CENTRO: Título de la ventana
    -- DERECHA: Red, CPU, Temp, RAM, Disco, Volumen, Clima, Fecha
    template = "  %uptime%   <fc=#6272a4>|</fc>   <fc=#ff5555>󰚰</fc> %updates% } <fc=#6272a4>%UnsafeStdinReader%</fc> { <fc=#ff79c6>󰤨 Red</fc> %net%   <fc=#6272a4>|</fc>   %cpu%   <fc=#6272a4>|</fc>   %coretemp%   <fc=#6272a4>|</fc>   %memory%   <fc=#6272a4>|</fc>   %disku%   <fc=#6272a4>|</fc>   <fc=#50fa7b>󰕾 Vol</fc> %vol%   <fc=#6272a4>|</fc>   %MMMX%   <fc=#6272a4>|</fc>   %date% "
}
