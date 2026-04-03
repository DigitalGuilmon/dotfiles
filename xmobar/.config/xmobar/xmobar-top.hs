import Xmobar

main :: IO ()
main = xmobar $ defaultConfig { 
    font = "xft:JetBrainsMono Nerd Font:weight=bold:pixelsize=16:antialias=true:hinting=true",
    additionalFonts = ["xft:JetBrainsMono Nerd Font:pixelsize=20:antialias=true:hinting=true"],
    bgColor = "#282a36",
    fgColor = "#f8f8f2",
    position = TopSize L 100 36,
    lowerOnStart = True,
    hideOnStart = False,
    allDesktops = True,
    persistent = True,
    
    commands = [ 
        Run $ DynNetwork ["-t", "<fc=#ff79c6>\xf0928 </fc> <rx> KB/s"] 20,
        Run $ Cpu ["-t", "<fc=#bd93f9>\xf04bc CPU</fc> <total>%"] 20,
        Run $ Memory ["-t", "<fc=#50fa7b>\xf035b RAM</fc> <usedratio>%"] 20,
        Run $ DiskU [("/", "<fc=#f1fa8c>\xf02ca</fc> <free>")] [] 600,
        Run $ Com "bash" ["-c", "checkupdates 2>/dev/null | wc -l || echo 0"] "updates" 36000,
        Run UnsafeStdinReader
    ],
    
    sepChar = "%",
    alignSep = "}{",
    
    template = " }{ %UnsafeStdinReader% }{ %dynnetwork% <fc=#6272a4>|</fc> %cpu% <fc=#6272a4>|</fc> %memory% <fc=#6272a4>|</fc> %disku% <fc=#6272a4>|</fc> <fc=#ff5555>\xf06b0</fc> %updates% "
}
