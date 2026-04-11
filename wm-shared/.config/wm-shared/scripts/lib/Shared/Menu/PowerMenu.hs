module Shared.Menu.PowerMenu (powerMenu) where

import XMonad
import XMonad.Prompt (XPConfig)
import System.Exit (exitWith, ExitCode(ExitSuccess))

import Shared.Menu.Prompt (promptConfig, runStaticPromptMenu)

powerOptions :: [(String, X ())]
powerOptions =
    [ ("1. Apagar (Shutdown)", spawn "systemctl poweroff")
    , ("2. Reiniciar (Reboot)", spawn "systemctl reboot")
    , ("3. Suspender (Suspend)", spawn "systemctl suspend")
    , ("4. Cerrar Sesión (Logout)", io (exitWith ExitSuccess))
    ]

powerXPConfig :: XPConfig
powerXPConfig = promptConfig "#ff79c6" "#282a36" "#bd93f9"

powerMenu :: X ()
powerMenu = runStaticPromptMenu " Energía (Escoge o escribe): " powerXPConfig powerOptions id
