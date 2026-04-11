module Standalone.Multimedia
    ( runAudioMenu
    , runMultimediaMenu
    , runVolumeCommand
    , volumeCommandUsage
    ) where

import Control.Monad (void)
import Data.Char (isDigit)
import System.Process (readProcess, spawnCommand)
import Text.Printf (printf)

import Standalone.Command (NamedCommand, namedCommand, parseNamedCommand, usageForCommands)
import Standalone.Menu (MenuSpec (..), menuEntry, runMenuSpec)
import StandaloneUtils (spawnCommand_)

data AudioCommand
    = VolumeUp
    | VolumeDown
    | ToggleMute
    | ToggleMic

data AudioMenuConfig = AudioMenuConfig
    { audioMenuId :: String
    , audioPrompt :: String
    , audioBackAction :: Maybe (String, IO ())
    , audioIncludeMic :: Bool
    , audioIncludePavucontrol :: Bool
    }

syncId :: String
syncId = "string:x-canonical-private-synchronous:sys-notify"

iconAudio, iconBright, iconMedia, iconNight, iconBack :: String
iconAudio  = "\xf04c3"
iconBright = "\xf00e0"
iconMedia  = "\xf075a"
iconNight  = "\xf0594"
iconBack   = "\xf006e"

runMultimediaMenu :: IO ()
runMultimediaMenu = multimediaMainMenu

runAudioMenu :: IO ()
runAudioMenu =
    audioMenuWithConfig $
        AudioMenuConfig
            { audioMenuId = "wm-shared-audio-menu"
            , audioPrompt = "Audio"
            , audioBackAction = Nothing
            , audioIncludeMic = True
            , audioIncludePavucontrol = True
            }

volumeCommands :: [NamedCommand (IO ())]
volumeCommands =
    [ namedCommand "menu" runAudioMenu
    , namedCommand "up" (executeAudioCommand VolumeUp)
    , namedCommand "down" (executeAudioCommand VolumeDown)
    , namedCommand "mute" (executeAudioCommand ToggleMute)
    , namedCommand "mic" (executeAudioCommand ToggleMic)
    ]

runVolumeCommand :: String -> IO Bool
runVolumeCommand command =
    case parseNamedCommand volumeCommands command of
        Just action -> action >> pure True
        Nothing -> pure False

volumeCommandUsage :: String
volumeCommandUsage = usageForCommands "volume.hs" volumeCommands

multimediaMainMenu :: IO ()
multimediaMainMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "hypr-multimedia-main"
            , menuSpecPrompt = "Multimedia"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry (iconAudio ++ " Audio") audioMenuFromMultimedia
                , menuEntry (iconBright ++ " Brillo") brightnessMenu
                , menuEntry (iconMedia ++ " Medios") mediaMenu
                , menuEntry (iconNight ++ " Modo Nocturno") nightMenu
                ]
            }

audioMenuFromMultimedia :: IO ()
audioMenuFromMultimedia =
    audioMenuWithConfig $
        AudioMenuConfig
            { audioMenuId = "hypr-multimedia-audio"
            , audioPrompt = "Control de Audio"
            , audioBackAction = Just (iconBack ++ " Volver", multimediaMainMenu)
            , audioIncludeMic = False
            , audioIncludePavucontrol = False
            }

audioMenuWithConfig :: AudioMenuConfig -> IO ()
audioMenuWithConfig config =
    runMenuSpec $
        MenuSpec
            { menuSpecId = audioMenuId config
            , menuSpecPrompt = audioPrompt config
            , menuSpecArgs = ["-i"]
            , menuSpecEntries = options
            }
  where
    reopen action = action >> audioMenuWithConfig config
    options =
        [ menuEntry "Subir Volumen (+5%)" (reopen (executeAudioCommand VolumeUp))
        , menuEntry "Bajar Volumen (-5%)" (reopen (executeAudioCommand VolumeDown))
        , menuEntry "Silenciar / Desilenciar" (reopen (executeAudioCommand ToggleMute))
        ]
            ++ micOption
            ++ pavucontrolOption
            ++ backOption

    micOption =
        if audioIncludeMic config
            then [menuEntry "Micrófono Mute Toggle" (reopen (executeAudioCommand ToggleMic))]
            else []

    pavucontrolOption =
        if audioIncludePavucontrol config
            then [menuEntry "Abrir Pavucontrol" (spawnCommand_ "pavucontrol")]
            else []

    backOption =
        case audioBackAction config of
            Just (label, action) -> [menuEntry label action]
            Nothing -> []

brightnessMenu :: IO ()
brightnessMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "hypr-multimedia-brightness"
            , menuSpecPrompt = "Brillo"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry "Brillo +10%" (spawnCommand_ "brightnessctl set +10%" >> brightnessMenu)
                , menuEntry "Brillo -10%" (spawnCommand_ "brightnessctl set 10%-" >> brightnessMenu)
                , menuEntry "Máximo" (spawnCommand_ "brightnessctl set 100%" >> brightnessMenu)
                , menuEntry "Mínimo" (spawnCommand_ "brightnessctl set 5%" >> brightnessMenu)
                , menuEntry (iconBack ++ " Volver") multimediaMainMenu
                ]
            }

mediaMenu :: IO ()
mediaMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "hypr-multimedia-player"
            , menuSpecPrompt = "Reproductor"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry "Play/Pause" (spawnCommand_ "playerctl play-pause" >> mediaMenu)
                , menuEntry "Siguiente" (spawnCommand_ "playerctl next" >> mediaMenu)
                , menuEntry "Anterior" (spawnCommand_ "playerctl previous" >> mediaMenu)
                , menuEntry (iconBack ++ " Volver") multimediaMainMenu
                ]
            }

nightMenu :: IO ()
nightMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "hypr-multimedia-night"
            , menuSpecPrompt = "Luz Nocturna"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry "Activar Modo Noche" (spawnCommand_ "wlsunset -t 4500 -T 6500")
                , menuEntry "Desactivar Modo Noche" (void $ spawnCommand "pkill wlsunset")
                , menuEntry (iconBack ++ " Volver") multimediaMainMenu
                ]
            }

executeAudioCommand :: AudioCommand -> IO ()
executeAudioCommand command =
    case command of
        VolumeUp -> changeVolume "5%+"
        VolumeDown -> changeVolume "5%-"
        ToggleMute -> toggleMute
        ToggleMic -> toggleMic

changeVolume :: String -> IO ()
changeVolume delta = do
    void $ readProcess "wpctl" ["set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", delta] ""
    notifyVolume

toggleMute :: IO ()
toggleMute = do
    void $ spawnCommand "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    notifyVolume

toggleMic :: IO ()
toggleMic =
    void $
        spawnCommand
            "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && notify-send -e -h string:x-canonical-private-synchronous:sys-notify -i audio-input-microphone 'Micrófono' 'Toggle mute'"

notifyVolume :: IO ()
notifyVolume = do
    status <- readProcess "wpctl" ["get-volume", "@DEFAULT_AUDIO_SINK@"] ""
    let isMuted = "[MUTED]" `elem` words status
        volStr = filter (\c -> isDigit c || c == '.') status
        volPercent = case reads volStr :: [(Double, String)] of
            [(value, _)] -> round (value * 100) :: Int
            _ -> 0
        (icon, label) = getVolumeIconAndLabel isMuted volPercent
        notifyCmd =
            printf
                "notify-send -e -h %s -h int:value:%d -i %s '%s' '%d%%'"
                syncId
                volPercent
                icon
                label
                volPercent :: String
    void $ spawnCommand notifyCmd

getVolumeIconAndLabel :: Bool -> Int -> (String, String)
getVolumeIconAndLabel True _ = ("audio-volume-muted", "Silencio")
getVolumeIconAndLabel _ 0 = ("audio-volume-muted", "Silencio")
getVolumeIconAndLabel _ value
    | value < 33 = ("audio-volume-low", "Volumen")
    | value < 66 = ("audio-volume-medium", "Volumen")
    | otherwise = ("audio-volume-high", "Volumen")
