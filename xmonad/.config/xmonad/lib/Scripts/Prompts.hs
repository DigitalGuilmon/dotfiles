module Scripts.Prompts where

import XMonad
import XMonad.Prompt
import XMonad.Actions.Search

-- Configuración visual del prompt para que coincida con tu tema Dracula
myXPConfig :: XPConfig
myXPConfig = def 
    { font = "xft:JetBrainsMono Nerd Font:pixelsize=14"
    , bgColor           = "#282a36"
    , fgColor           = "#f8f8f2"
    , bgHLight          = "#bd93f9"
    , fgHLight          = "#282a36"
    , borderColor       = "#6272a4"
    , promptBorderWidth = 2
    , position          = Top
    , height            = 36
    }

-- Función para buscar en Google
searchGoogle :: X ()
searchGoogle = promptSearch myXPConfig google

-- Función para buscar en YouTube
searchYouTube :: X ()
searchYouTube = promptSearch myXPConfig youtube
