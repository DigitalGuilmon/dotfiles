#!/usr/bin/env sh
#if 0
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
script_root="$script_dir"
while [ ! -d "$script_root/lib" ] && [ "$script_root" != "/" ]; do
    script_root=$(dirname "$script_root")
done
exec runhaskell -XCPP -i"$script_root/lib" "$0" "$@"
#endif

import Data.Char (toLower)
import Data.List (isInfixOf)
import Data.Maybe (fromMaybe)
import System.Directory (createDirectoryIfMissing, findExecutable)
import System.Environment (lookupEnv)
import System.FilePath ((</>))

import Common.Text (shellEscape, trimWhitespace)
import Common.YtDlpPresets (YtDlpPreset (..), ytDlpPresets)
import Standalone.Menu (MenuSpec (..), menuEntry, selectMenuSpec)
import Standalone.Runtime (notify, requireHomeDirectory, spawnCommandSafe)
import StandaloneUtils (rofiInput)

main :: IO ()
main = do
    url <- fmap trimWhitespace (rofiInput "wm-shared-yt-dlp-url" "YT URL" ["-i"] "")
    if null url
        then notify "normal" "YT-DLP" "No se ingreso ninguna URL."
        else
            if not (isYouTubeUrl url)
                then notify "critical" "YT-DLP" "La URL debe ser de YouTube."
                else do
                    ytDlpBinary <- findExecutable "yt-dlp"
                    case ytDlpBinary of
                        Nothing -> notify "critical" "YT-DLP" "yt-dlp no esta instalado."
                        Just _ -> do
                            selected <- selectMenuSpec ytDlpMenu
                            case selected of
                                Nothing -> pure ()
                                Just preset -> launchPreset preset url

ytDlpMenu :: MenuSpec YtDlpPreset
ytDlpMenu =
    MenuSpec
        { menuSpecId = "wm-shared-yt-dlp-options"
        , menuSpecPrompt = "YT-DLP"
        , menuSpecArgs = ["-i", "-l", show (length ytDlpPresets)]
        , menuSpecEntries = map (\preset -> menuEntry (ytDlpPresetLabel preset) preset) ytDlpPresets
        }

isYouTubeUrl :: String -> Bool
isYouTubeUrl url =
    let lowered = map toLower url
    in ("youtube.com" `isInfixOf` lowered || "youtu.be" `isInfixOf` lowered)
        && ("http://" `isInfixOf` lowered || "https://" `isInfixOf` lowered)

launchPreset :: YtDlpPreset -> String -> IO ()
launchPreset preset url =
    requireHomeDirectory
        "YT-DLP"
        "No se pudo resolver HOME para la descarga."
        (\homeDir -> do
            let targetDir = homeDir </> "Downloads" </> "yt-dlp" </> ytDlpPresetDirectory preset
            createDirectoryIfMissing True targetDir
            terminal <- resolveTerminal
            case terminal of
                Nothing -> notify "critical" "YT-DLP" "No se encontro una terminal compatible."
                Just terminalCommand -> do
                    notify "low" "YT-DLP" ("Descarga iniciada: " ++ ytDlpPresetLabel preset)
                    spawnCommandSafe (terminalLaunchCommand terminalCommand targetDir preset url)
        )

resolveTerminal :: IO (Maybe String)
resolveTerminal = do
    envTerminal <- lookupEnv "TERMINAL"
    case envTerminal of
        Just terminal -> pure (Just terminal)
        Nothing -> do
            ghostty <- findExecutable "ghostty"
            case ghostty of
                Just _ -> pure (Just "ghostty")
                Nothing -> do
                    fallback <- findExecutable "x-terminal-emulator"
                    pure (fmap (const "x-terminal-emulator") fallback)

terminalLaunchCommand :: String -> FilePath -> YtDlpPreset -> String -> String
terminalLaunchCommand terminalCommand targetDir preset url =
    terminalCommand
        ++ " -e sh -lc "
        ++ shellEscape shellCommand
  where
    shellCommand =
        unlines
            [ "mkdir -p " ++ shellEscape targetDir
            , "cd " ++ shellEscape targetDir
            , "yt-dlp --newline --no-mtime --embed-metadata --restrict-filenames "
                ++ unwords (map shellEscape (ytDlpPresetArgs preset))
                ++ " "
                ++ shellEscape url
            , "status=$?"
            , "if [ \"$status\" -eq 0 ]; then"
            , "  notify-send -u low -a wm-shared 'YT-DLP' 'Descarga completada.'"
            , "else"
            , "  notify-send -u critical -a wm-shared 'YT-DLP' 'La descarga fallo.'"
            , "fi"
            , "printf '\\nPresiona Enter para cerrar...'"
            , "read _"
            ]
