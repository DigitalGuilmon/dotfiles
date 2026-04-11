module Shared.Menu.Prompt
    ( promptConfig
    , runStaticPromptMenu
    ) where

import XMonad (X)
import XMonad.Prompt
import XMonad.Prompt.FuzzyMatch (fuzzyMatch)

data StaticPrompt = StaticPrompt String

instance XPrompt StaticPrompt where
    showXPrompt (StaticPrompt promptLabel) = promptLabel
    commandToComplete _ command = command
    nextCompletion _ = getNextCompletion

promptConfig :: String -> String -> String -> XPConfig
promptConfig bgHighlight fgHighlight border = def
    { font              = "xft:JetBrainsMono Nerd Font:size=11"
    , bgColor           = "#282a36"
    , fgColor           = "#f8f8f2"
    , bgHLight          = bgHighlight
    , fgHLight          = fgHighlight
    , borderColor       = border
    , promptBorderWidth = 2
    , position          = CenteredAt 0.5 0.5
    , height            = 50
    , alwaysHighlight   = True
    , searchPredicate   = fuzzyMatch
    }

runStaticPromptMenu :: String -> XPConfig -> [(String, a)] -> (a -> X ()) -> X ()
runStaticPromptMenu promptLabel config options onSelect =
    mkXPrompt (StaticPrompt promptLabel) config
        (mkComplFunFromList' config (map fst options))
        (\selection -> maybe (pure ()) onSelect (lookup selection options))
