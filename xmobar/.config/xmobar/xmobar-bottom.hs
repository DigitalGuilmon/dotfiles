Config {
    -- Apariencia general
    font = "xft:JetBrainsMono Nerd Font:weight=bold:pixelsize=16:antialias=true:hinting=true",
    additionalFonts = ["xft:JetBrainsMono Nerd Font:pixelsize=20:antialias=true:hinting=true"],
    bgColor = "#282a36",
    fgColor = "#f8f8f2",
    
    -- Posicionamiento (Abajo, 100% ancho, 36px de alto)
    position = BottomSize L 100 36,
    lowerOnStart = True,
    hideOnStart = False,
    allDesktops = True,
    persistent = True,
    
    -- Módulos
    commands = [
        -- Ejecuta tu script de cava
        Run CommandReader "~/.config/polybar/scripts/cava.sh" "cava",
        
        -- Lector para recibir los workspaces desde XMonad
        Run UnsafeStdinReader
    ],
    
    sepChar = "%",
    alignSep = "}{",
    
    -- Plantilla: Izquierda } Centro { Derecha
    -- Workspaces izquierda, cava al centro, derecha vacío
    template = " %UnsafeStdinReader% } <fc=#bd93f9>%cava%</fc> { "
}
