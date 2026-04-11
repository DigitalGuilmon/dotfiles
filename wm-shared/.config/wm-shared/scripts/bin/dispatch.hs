#!/usr/bin/env sh
#if 0
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
script_root="$script_dir"
while [ ! -d "$script_root/lib" ] && [ "$script_root" != "/" ]; do
    script_root=$(dirname "$script_root")
done
exec runhaskell -XCPP -i"$script_root/lib" "$0" "$@"
#endif

import System.Environment (getArgs)

import Standalone.Command (NamedCommand, namedCommand, parseNamedCommand, usageForCommands)
import Standalone.Environment
    ( runAppearanceMenu
    , runBluetoothMenu
    , runFilesMenu
    , runScratchpadMenu
    , runSessionMenu
    , runWorkspaceMenu
    )
import Standalone.Multimedia (runMultimediaMenu)
import Standalone.NotificationCenter (runNotificationCenter)
import Standalone.Productivity
    ( runClipboardMenu
    , runEmojiPicker
    , runProductivityMenu
    , runProjectsMenu
    , runTimerMenu
    )
import Standalone.SystemInfo (runSystemInfoMenu)

data DispatchCommand
    = DispatchMultimediaMenu
    | DispatchNotifications
    | DispatchProductivityMenu
    | DispatchProjectsMenu
    | DispatchEmojiPicker
    | DispatchTimerMenu
    | DispatchSystemInfo
    | DispatchClipboardMenu
    | DispatchWorkspaceMenu
    | DispatchScratchpadMenu
    | DispatchSessionMenu
    | DispatchFilesMenu
    | DispatchBluetoothMenu
    | DispatchAppearanceMenu

dispatchCommands :: [NamedCommand DispatchCommand]
dispatchCommands =
    [ namedCommand "multimedia-menu" DispatchMultimediaMenu
    , namedCommand "notifications" DispatchNotifications
    , namedCommand "productivity-menu" DispatchProductivityMenu
    , namedCommand "projects-menu" DispatchProjectsMenu
    , namedCommand "emoji-picker" DispatchEmojiPicker
    , namedCommand "timer-menu" DispatchTimerMenu
    , namedCommand "system-info" DispatchSystemInfo
    , namedCommand "clipboard-menu" DispatchClipboardMenu
    , namedCommand "workspace-menu" DispatchWorkspaceMenu
    , namedCommand "scratchpad-menu" DispatchScratchpadMenu
    , namedCommand "session-menu" DispatchSessionMenu
    , namedCommand "files-menu" DispatchFilesMenu
    , namedCommand "bluetooth-menu" DispatchBluetoothMenu
    , namedCommand "appearance-menu" DispatchAppearanceMenu
    ]

runDispatchCommand :: DispatchCommand -> IO ()
runDispatchCommand command =
    case command of
        DispatchMultimediaMenu -> runMultimediaMenu
        DispatchNotifications -> runNotificationCenter
        DispatchProductivityMenu -> runProductivityMenu
        DispatchProjectsMenu -> runProjectsMenu
        DispatchEmojiPicker -> runEmojiPicker
        DispatchTimerMenu -> runTimerMenu
        DispatchSystemInfo -> runSystemInfoMenu
        DispatchClipboardMenu -> runClipboardMenu
        DispatchWorkspaceMenu -> runWorkspaceMenu
        DispatchScratchpadMenu -> runScratchpadMenu
        DispatchSessionMenu -> runSessionMenu
        DispatchFilesMenu -> runFilesMenu
        DispatchBluetoothMenu -> runBluetoothMenu
        DispatchAppearanceMenu -> runAppearanceMenu

main :: IO ()
main = do
    args <- getArgs
    case args of
        [commandName] ->
            case parseNamedCommand dispatchCommands commandName of
                Just command -> runDispatchCommand command
                Nothing -> putStrLn dispatchUsage
        _ -> putStrLn dispatchUsage
  where
    dispatchUsage = usageForCommands "dispatch.hs" dispatchCommands
