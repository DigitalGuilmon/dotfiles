module Scripts.Productivity.ProjectManager (projectMenu) where

import XMonad
import XMonad.Prompt
import XMonad.Prompt.FuzzyMatch (fuzzyMatch)

data ProjectPrompt = ProjectPrompt

instance XPrompt ProjectPrompt where
    showXPrompt ProjectPrompt = " Proyecto: "
    commandToComplete _ c = c
    nextCompletion _ = getNextCompletion

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
projectXPConfig = def
    { font              = "xft:JetBrainsMono Nerd Font:size=11"
    , bgColor           = "#282a36"
    , fgColor           = "#f8f8f2"
    , bgHLight          = "#8be9fd"
    , fgHLight          = "#282a36"
    , borderColor       = "#8be9fd"
    , promptBorderWidth = 2
    , position          = CenteredAt 0.5 0.5
    , height            = 50
    , alwaysHighlight   = True
    , searchPredicate   = fuzzyMatch
    }

-- Abre una terminal en el directorio del proyecto y lanza LunarVim
projectMenu :: X ()
projectMenu = mkXPrompt ProjectPrompt projectXPConfig
    (mkComplFunFromList' projectXPConfig (map fst projectList))
    (\selection -> case lookup selection projectList of
        Just path -> spawn $ "ghostty --working-directory=\"" ++ path ++ "\" -e lvim \"" ++ path ++ "\""
        Nothing   -> return ()
    )
