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

import Standalone.Multimedia (runAudioMenu, runVolumeCommand, volumeCommandUsage)

main :: IO ()
main = do
    args <- getArgs
    case args of
        [] -> runAudioMenu
        [command] -> do
            handled <- runVolumeCommand command
            if handled
                then pure ()
                else putStrLn volumeCommandUsage
        _ -> putStrLn volumeCommandUsage
