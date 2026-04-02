module Scripts.PowerMenu (powerMenu) where

import XMonad
import XMonad.Prompt
import XMonad.Prompt.FuzzyMatch (fuzzyMatch) -- ¡Añadido!
import System.Exit (exitWith, ExitCode(ExitSuccess))

data PowerPrompt = PowerPrompt

instance XPrompt PowerPrompt where
    showXPrompt PowerPrompt = " Energía (Escoge o escribe): "
    commandToComplete _ c = c
    nextCompletion _ = getNextCompletion

powerOptions :: [(String, X ())]
powerOptions =
    [ ("1. Apagar (Shutdown)", spawn "systemctl poweroff")
    , ("2. Reiniciar (Reboot)", spawn "systemctl reboot")
    , ("3. Suspender (Suspend)", spawn "systemctl suspend")
    , ("4. Cerrar Sesión (Logout)", io (exitWith ExitSuccess))
    ]

powerXPConfig :: XPConfig
powerXPConfig = def
    { font              = "xft:JetBrainsMono Nerd Font:size=11"
    , bgColor           = "#282a36" 
    , fgColor           = "#f8f8f2" 
    , bgHLight          = "#ff79c6" 
    , fgHLight          = "#282a36" 
    , borderColor       = "#bd93f9" 
    , promptBorderWidth = 2
    , position          = CenteredAt 0.5 0.5 
    , height            = 50
    , alwaysHighlight   = True
    , searchPredicate   = fuzzyMatch 
    }

powerMenu :: X ()
powerMenu = mkXPrompt PowerPrompt powerXPConfig 
    (mkComplFunFromList' powerXPConfig (map fst powerOptions))
    (\selection -> case lookup selection powerOptions of
        Just action -> action
        Nothing     -> return () 
    )
