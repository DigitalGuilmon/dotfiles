module Keys.Multimedia where

import XMonad

multimediaKeys :: [(String, X ())]
multimediaKeys =
    [ ("<XF86AudioRaiseVolume>", spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")
    , ("<XF86AudioLowerVolume>", spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
    , ("<XF86AudioMute>",        spawn "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
    , ("<XF86MonBrightnessUp>",  spawn "brightnessctl set +5%")
    , ("<XF86MonBrightnessDown>",spawn "brightnessctl set 5%-")
    ]
