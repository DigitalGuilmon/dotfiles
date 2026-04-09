module Scripts.AudioControl (audioMenu) where

import XMonad
import XMonad.Prompt
import XMonad.Prompt.FuzzyMatch (fuzzyMatch)

data AudioPrompt = AudioPrompt

instance XPrompt AudioPrompt where
    showXPrompt AudioPrompt = " Audio: "
    commandToComplete _ c = c
    nextCompletion _ = getNextCompletion

audioOptions :: [(String, X ())]
audioOptions =
    [ ("1. Volumen +10%",           spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+ && notify-send '🔊 Volumen' \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@)\"")
    , ("2. Volumen -10%",           spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%- && notify-send '🔉 Volumen' \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@)\"")
    , ("3. Silenciar/Desilenciar",  spawn "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && notify-send '🔇 Mute' 'Toggle mute'")
    , ("4. Micrófono Mute Toggle",  spawn "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && notify-send '🎤 Mic' 'Toggle mic mute'")
    , ("5. Abrir Pavucontrol",      spawn "pavucontrol")
    , ("6. Salida: Altavoces",      spawn "wpctl set-default $(pw-dump | jq -r '.[] | select(.info.props[\"node.description\"] | test(\"Speaker|Altavoz\"; \"i\")) | .id' | head -1) && notify-send '🔈 Audio' 'Altavoces seleccionados'")
    , ("7. Salida: Auriculares",    spawn "wpctl set-default $(pw-dump | jq -r '.[] | select(.info.props[\"node.description\"] | test(\"Headphone|Auricular\"; \"i\")) | .id' | head -1) && notify-send '🎧 Audio' 'Auriculares seleccionados'")
    ]

audioXPConfig :: XPConfig
audioXPConfig = def
    { font              = "xft:JetBrainsMono Nerd Font:size=11"
    , bgColor           = "#282a36"
    , fgColor           = "#f8f8f2"
    , bgHLight          = "#f1fa8c"
    , fgHLight          = "#282a36"
    , borderColor       = "#f1fa8c"
    , promptBorderWidth = 2
    , position          = CenteredAt 0.5 0.5
    , height            = 50
    , alwaysHighlight   = True
    , searchPredicate   = fuzzyMatch
    }

-- Menú interactivo de control de audio
audioMenu :: X ()
audioMenu = mkXPrompt AudioPrompt audioXPConfig
    (mkComplFunFromList' audioXPConfig (map fst audioOptions))
    (\selection -> case lookup selection audioOptions of
        Just action -> action
        Nothing     -> return ()
    )
