module Scripts.Multimedia.Screenshot (screenshot) where

import XMonad
import XMonad.Util.Run (runProcessWithInput)
import Variables (myThemeAbs)

-- Función principal que llamarás desde tus Keys
screenshot :: X ()
screenshot = do
    theme <- myThemeAbs
    let rofiCmd = "rofi"
    let rofiArgs = ["-dmenu", "-p", "Screenshot:", "-theme", theme, "-i"]
    let options = "Full Screen\nArea Selection\nActive Window"
    
    -- Ejecutamos rofi y capturamos la selección del usuario
    selection <- runProcessWithInput rofiCmd rofiArgs options
    
    -- Limpiamos posibles saltos de línea
    let res = filter (/= '\n') selection
    
    -- Ejecutamos el comando correspondiente según la opción
    case res of
        "Full Screen"    -> spawn "mkdir -p ~/Pictures/Screenshots && maim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png && notify-send '📷 Captura' 'Pantalla completa guardada' || notify-send '❌ Captura' 'Error al capturar pantalla'"
        "Area Selection" -> spawn "mkdir -p ~/Pictures/Screenshots && maim -s ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png && notify-send '📷 Captura' 'Área guardada' || notify-send '📷 Captura' 'Selección cancelada'"
        "Active Window"  -> spawn "mkdir -p ~/Pictures/Screenshots && maim -i $(xdotool getactivewindow) ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png && notify-send '📷 Captura' 'Ventana guardada' || notify-send '❌ Captura' 'Error al capturar ventana'"
        _                -> return ()
