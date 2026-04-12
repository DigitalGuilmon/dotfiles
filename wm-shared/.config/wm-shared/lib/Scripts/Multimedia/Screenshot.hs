module Scripts.Multimedia.Screenshot (screenshot) where

import XMonad
import Scripts.Utils (rofiSelect)

-- Función principal que llamarás desde tus Keys
screenshot :: X ()
screenshot = do
    let options = "Full Screen\nArea Selection\nActive Window"

    res <- rofiSelect "xmonad-screenshot" "Screenshot:" ["-i"] options

    -- Ejecutamos el comando correspondiente según la opción
    case res of
        "Full Screen"    -> spawn "mkdir -p ~/Pictures/Screenshots && maim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png && notify-send '📷 Captura' 'Pantalla completa guardada' || notify-send '❌ Captura' 'Error al capturar pantalla'"
        "Area Selection" -> spawn "mkdir -p ~/Pictures/Screenshots && maim -s ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png && notify-send '📷 Captura' 'Área guardada' || notify-send '📷 Captura' 'Selección cancelada'"
        "Active Window"  -> spawn "mkdir -p ~/Pictures/Screenshots && maim -i $(xdotool getactivewindow) ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png && notify-send '📷 Captura' 'Ventana guardada' || notify-send '❌ Captura' 'Error al capturar ventana'"
        _                -> return ()
