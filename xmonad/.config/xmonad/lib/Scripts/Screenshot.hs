module Scripts.Screenshot (screenshot) where

import XMonad
import XMonad.Util.Run (runProcessWithInput)
import Variables (myTheme)

-- Función principal que llamarás desde tus Keys
screenshot :: X ()
screenshot = do
    let rofiCmd = "rofi"
    let rofiArgs = ["-dmenu", "-p", "Screenshot:", "-theme", myTheme, "-i"]
    let options = "Full Screen\nArea Selection\nActive Window"
    
    -- Ejecutamos rofi y capturamos la selección del usuario
    selection <- runProcessWithInput rofiCmd rofiArgs options
    
    -- Limpiamos posibles saltos de línea
    let res = filter (/= '\n') selection
    
    -- Ejecutamos el comando correspondiente según la opción
    case res of
        "Full Screen"    -> spawn "maim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png && notify-send '📷 Captura' 'Pantalla completa guardada'"
        "Area Selection" -> spawn "maim -s ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png && notify-send '📷 Captura' 'Área guardada'"
        "Active Window"  -> spawn "maim -i $(xdotool getactivewindow) ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png && notify-send '📷 Captura' 'Ventana guardada'"
        _                -> return ()
