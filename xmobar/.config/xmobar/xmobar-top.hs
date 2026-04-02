Config { 
    -- Apariencia general (Paleta Dracula)
    font = "xft:JetBrainsMono Nerd Font:weight=bold:pixelsize=16:antialias=true:hinting=true",
    additionalFonts = ["xft:JetBrainsMono Nerd Font:pixelsize=20:antialias=true:hinting=true"],
    bgColor = "#282a36",
    fgColor = "#f8f8f2",
    
    -- Posicionamiento
    position = TopSize L 100 36,
    lowerOnStart = True,
    hideOnStart = False,
    allDesktops = True,
    persistent = True,
    
    -- Módulos optimizados
    commands = [ 
        -- RED: DynNetwork detecta automáticamente la interfaz activa
        Run DynNetwork ["-t", "<fc=#ff79c6>󰤨 </fc><rx> KB/s", "-L", "10", "-H", "100", "--normal", "#f1fa8c", "--high", "#ff5555"] 20,

        -- CPU
        Run Cpu ["-t", "<fc=#bd93f9> CPU</fc> <total>%", "-H", "50", "-h", "#ff5555"] 20,
        
        -- TEMPERATURA CPU (Activado por defecto)
        Run CoreTemp ["-t", "<fc=#ffb86c></fc> <core0>°C", "-L", "40", "-H", "75", "-l", "#50fa7b", "-n", "#f1fa8c", "-h", "#ff5555"] 50,

        -- RAM
        Run Memory ["-t", "<fc=#50fa7b>󰍛 RAM</fc> <usedratio>%"] 20,
        
        -- DISCO RAÍZ
        Run DiskU [("/", "<fc=#f1fa8c>󰋊</fc> <free>")] [] 600,

        -- ACTUALIZACIONES: Se mantiene el comando pero con un intervalo más largo
        Run Com "bash" ["-c", "checkupdates 2>/dev/null | wc -l || echo 0"] "updates" 36000,

        -- VOLUMEN: Script optimizado para Pipewire
        Run Com "bash" ["-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}' | cut -d'.' -f1"] "vol" 5,

        -- FECHA Y HORA
        Run Date "<fc=#8be9fd></fc> %d %b - %H:%M" "date" 10,
        
        -- Lector para los Workspaces desde XMonad
        Run UnsafeStdinReader
    ],
    
    sepChar = "%",
    alignSep = "}{",
    
    -- Plantilla mejorada (Usando %dynnetwork%)
    template = " %UnsafeStdinReader% } <fc=#ff5555>󰚰</fc> %updates%  <fc=#6272a4>|</fc>  %cpu%  <fc=#6272a4>|</fc>  %coretemp% { <fc=#ff79c6>󰤨 </fc>%dynnetwork%  <fc=#6272a4>|</fc>  %memory%  <fc=#6272a4>|</fc>  <fc=#50fa7b>󰕾</fc> %vol%%  <fc=#6272a4>|</fc>  %date% "
}
