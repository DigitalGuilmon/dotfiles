Config { 
    font = "xft:JetBrainsMono Nerd Font:weight=bold:pixelsize=16:antialias=true:hinting=true",
    additionalFonts = ["xft:JetBrainsMono Nerd Font:pixelsize=20:antialias=true:hinting=true"],
    bgColor = "#282a36",
    fgColor = "#f8f8f2",
    position = TopSize L 100 36,
    lowerOnStart = False,
    hideOnStart = False,
    allDesktops = True,
    persistent = True,
    
    commands = [ 
        -- DynNetwork ahora auto-escala la unidad (MB, KB, B) con "-S True"
        Run DynNetwork ["-t", "<fc=#ff79c6>󰤨 </fc> <rx>", "-S", "True"] 20,
        Run Cpu ["-t", "<fc=#bd93f9>󰒼 CPU</fc> <total>%"] 20,
        Run Memory ["-t", "<fc=#50fa7b>󰍛 RAM</fc> <usedratio>%"] 20,
        Run DiskU [("/", "<fc=#f1fa8c>󰋊</fc> <free>")] [] 600,
        Run Com "bash" ["-c", "checkupdates 2>/dev/null | wc -l || echo 0"] "updates" 36000,
        Run UnsafeStdinReader
    ],
    
    sepChar = "%",
    alignSep = "}{",
    
    -- Izquierda: Layout } Centro: (Vacío) { Derecha: Módulos del sistema
    template = " %UnsafeStdinReader% } { %dynnetwork% <fc=#6272a4>|</fc> %cpu% <fc=#6272a4>|</fc> %memory% <fc=#6272a4>|</fc> %disku% <fc=#6272a4>|</fc> <fc=#ff5555>󰚰</fc> %updates% "
}
