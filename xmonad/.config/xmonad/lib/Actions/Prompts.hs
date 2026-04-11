module Actions.Prompts
    ( runShell
    , searchGoogle
    , searchMan
    , searchYouTube
    ) where

import XMonad
import qualified XMonad.Actions.Search as Search
import XMonad.Prompt
import XMonad.Prompt.FuzzyMatch (fuzzyMatch)
import XMonad.Prompt.Man (manPrompt)
import XMonad.Prompt.Shell (shellPrompt)

myPromptConfig :: XPConfig
myPromptConfig =
    def
        { font = "xft:JetBrainsMono Nerd Font:size=11"
        , bgColor = "#282a36"
        , fgColor = "#f8f8f2"
        , bgHLight = "#ff79c6"
        , fgHLight = "#282a36"
        , borderColor = "#50fa7b"
        , promptBorderWidth = 2
        , position = CenteredAt 0.5 0.5
        , height = 50
        , alwaysHighlight = True
        , searchPredicate = fuzzyMatch
        }

searchGoogle :: X ()
searchGoogle = Search.promptSearch myPromptConfig Search.google

searchYouTube :: X ()
searchYouTube = Search.promptSearch myPromptConfig Search.youtube

searchMan :: X ()
searchMan = manPrompt myPromptConfig

runShell :: X ()
runShell = shellPrompt myPromptConfig
