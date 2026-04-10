module Scripts.System.Prompts 
    ( searchGoogle
    , searchYouTube
    , searchMan
    , runShell
    ) where

import XMonad
import XMonad.Prompt
import XMonad.Prompt.FuzzyMatch (fuzzyMatch)  -- ¡Añadido!
import qualified XMonad.Actions.Search as S   -- ¡Corregido! (Era Actions, no Prompt)
import XMonad.Prompt.Man (manPrompt)
import XMonad.Prompt.Shell (shellPrompt)

-- Configuración visual unificada para todos tus Prompts (Estética Drácula)
myPromptConfig :: XPConfig
myPromptConfig = def
    { font              = "xft:JetBrainsMono Nerd Font:size=11"
    , bgColor           = "#282a36" 
    , fgColor           = "#f8f8f2" 
    , bgHLight          = "#ff79c6" 
    , fgHLight          = "#282a36" 
    , borderColor       = "#50fa7b" 
    , promptBorderWidth = 2
    , position          = CenteredAt 0.5 0.5 
    , height            = 50
    , alwaysHighlight   = True
    , searchPredicate   = fuzzyMatch 
    }

-- ==========================================
-- BÚSQUEDAS EN INTERNET
-- ==========================================
searchGoogle :: X ()
searchGoogle = S.promptSearch myPromptConfig S.google

searchYouTube :: X ()
searchYouTube = S.promptSearch myPromptConfig S.youtube

-- ==========================================
-- HERRAMIENTAS DE SISTEMA Y DESARROLLO
-- ==========================================
searchMan :: X ()
searchMan = manPrompt myPromptConfig

runShell :: X ()
runShell = shellPrompt myPromptConfig
