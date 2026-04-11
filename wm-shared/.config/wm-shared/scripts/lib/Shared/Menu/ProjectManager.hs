module Shared.Menu.ProjectManager (projectMenu) where

import XMonad
import XMonad.Prompt (XPConfig)

import Shared.Menu.Prompt (promptConfig, runStaticPromptMenu)

-- Lista de proyectos: (nombre visible, ruta absoluta)
-- Personaliza esta lista con tus propios proyectos.
projectList :: [(String, String)]
projectList =
    [ ("Dotfiles",       "$HOME/dotfiles")
    , ("XMonad Config",  "$HOME/.config/xmonad")
    , ("Xmobar Config",  "$HOME/.config/xmobar")
    , ("LunarVim Config","$HOME/.config/lvim")
    , ("Proyecto 1",     "$HOME/Projects/project1")
    , ("Proyecto 2",     "$HOME/Projects/project2")
    , ("Trabajo",        "$HOME/Work")
    ]

projectXPConfig :: XPConfig
projectXPConfig = promptConfig "#8be9fd" "#282a36" "#8be9fd"

-- Abre una terminal en el directorio del proyecto y lanza LunarVim
projectMenu :: X ()
projectMenu = runStaticPromptMenu " Proyecto: " projectXPConfig projectList openProject
  where
    openProject path = spawn $ "ghostty --working-directory=\"" ++ path ++ "\" -e lvim \"" ++ path ++ "\""
