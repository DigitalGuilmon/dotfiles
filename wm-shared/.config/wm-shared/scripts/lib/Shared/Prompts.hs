module Shared.Prompts 
    ( searchGoogle
    , searchYouTube
    , searchMan
    , runShell
    ) where

import XMonad
import XMonad.Prompt
import qualified XMonad.Actions.Search as S   -- ¡Corregido! (Era Actions, no Prompt)
import XMonad.Prompt.Man (manPrompt)
import XMonad.Prompt.Shell (shellPrompt)

import Shared.Menu.Prompt (promptConfig)

-- Configuración visual unificada para todos tus Prompts (Estética Drácula)
myPromptConfig :: XPConfig
myPromptConfig = promptConfig "#ff79c6" "#282a36" "#50fa7b"

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
