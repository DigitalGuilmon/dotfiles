module Scripts.System.GridMenu where

import XMonad
import XMonad.Actions.GridSelect

-- Configuración de color para el Grid (Tema Dracula)
myGridConfig :: GSConfig Window
myGridConfig = def
    { gs_cellheight  = 50
    , gs_cellwidth   = 250
    , gs_cellpadding = 10
    , gs_font        = "xft:JetBrainsMono Nerd Font:weight=bold:pixelsize=14"
    , gs_colorizer   = colorizer
    }
  where
    colorizer _ True  = return ("#bd93f9", "#282a36") -- Enfocado
    colorizer _ False = return ("#282a36", "#f8f8f2") -- No enfocado

-- Lanza el menú para ir a una ventana
gridGoToWindow :: X ()
gridGoToWindow = goToSelected myGridConfig
