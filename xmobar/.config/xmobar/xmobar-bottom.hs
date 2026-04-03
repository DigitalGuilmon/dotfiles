-- Archivo: xmobar/.config/xmobar/xmobar-bottom.hs

Config {
    font = "xft:JetBrainsMono Nerd Font:weight=bold:pixelsize=16:antialias=true:hinting=true",
    additionalFonts = ["xft:JetBrainsMono Nerd Font:pixelsize=20:antialias=true:hinting=true"],
    bgColor = "#282a36",
    fgColor = "#f8f8f2",
    position = BottomSize L 100 36,
    lowerOnStart = True,
    hideOnStart = False,
    allDesktops = True,
    persistent = True,
    
    commands = [
        Run CommandReader "~/.config/xmobar/scripts/cava.sh" "cava",
        Run Date "<fc=#8be9fd></fc> %d %b - %H:%M" "date" 10,
        Run UnsafeStdinReader
    ],
    
    sepChar = "%",
    alignSep = "}{",
    
    -- Estructura: Workspaces }{ Cava }{ Fecha
    template = " %UnsafeStdinReader% }{ <fc=#bd93f9>%cava%</fc> }{ %date% "
}
