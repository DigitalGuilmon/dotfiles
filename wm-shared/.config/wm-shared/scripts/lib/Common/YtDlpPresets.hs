module Common.YtDlpPresets
    ( YtDlpPreset (..)
    , ytDlpPreset
    , ytDlpPresets
    ) where

data YtDlpPreset = YtDlpPreset
    { ytDlpPresetLabel :: String
    , ytDlpPresetDirectory :: FilePath
    , ytDlpPresetArgs :: [String]
    }

ytDlpPreset :: String -> FilePath -> [String] -> YtDlpPreset
ytDlpPreset = YtDlpPreset

ytDlpPresets :: [YtDlpPreset]
ytDlpPresets =
    [ ytDlpPreset
        "🎬 Video MP4 (1080p)"
        "video"
        [ "-f", "bv*[height<=1080]+ba/b[height<=1080]/b"
        , "--merge-output-format", "mp4"
        ]
    , ytDlpPreset
        "🎬 Video MP4 + subtitulos"
        "video"
        [ "-f", "bv*[height<=1080]+ba/b[height<=1080]/b"
        , "--merge-output-format", "mp4"
        , "--write-auto-sub"
        , "--sub-langs", "es.*,en.*"
        , "--embed-subs"
        ]
    , ytDlpPreset
        "🎵 Audio MP3"
        "audio"
        [ "-x"
        , "--audio-format", "mp3"
        , "--audio-quality", "0"
        ]
    , ytDlpPreset
        "🎧 Audio Opus"
        "audio"
        [ "-x"
        , "--audio-format", "opus"
        ]
    , ytDlpPreset
        "📝 Solo subtitulos"
        "subs"
        [ "--skip-download"
        , "--write-auto-sub"
        , "--sub-langs", "es.*,en.*"
        , "--convert-subs", "srt"
        ]
    ]
