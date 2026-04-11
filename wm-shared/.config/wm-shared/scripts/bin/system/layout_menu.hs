#!/usr/bin/env sh
#if 0
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
script_root="$script_dir"
while [ ! -d "$script_root/lib" ] && [ "$script_root" != "/" ]; do
    script_root=$(dirname "$script_root")
done
exec runhaskell -XCPP -i"$script_root/lib" "$0" "$@"
#endif

import Data.List (find, isPrefixOf)
import System.Exit (ExitCode (ExitSuccess), exitSuccess)
import System.Process (readProcessWithExitCode, spawnProcess)

import StandaloneUtils (selectOption, trim)

data LayoutOption = LayoutOption
    { layoutName :: String
    , layoutLabel :: String
    }

layoutOptions :: [LayoutOption]
layoutOptions =
    [ LayoutOption "dwindle" "🌀 Dwindle"
    , LayoutOption "master" "📐 Master"
    ]

main :: IO ()
main = do
    currentLayout <- getCurrentLayout
    selected <- selectOption "hypr-layout-menu" ("Tiling (" ++ currentLayout ++ ")") ["-i"]
        (map (\option -> (layoutLabel option, option)) layoutOptions)
    maybe exitSuccess setLayout selected

getCurrentLayout :: IO String
getCurrentLayout = do
    (exitCode, out, _) <- readProcessWithExitCode "hyprctl" ["getoption", "general:layout"] ""
    if exitCode == ExitSuccess
        then return (parseLayout out)
        else return "desconocido"

parseLayout :: String -> String
parseLayout output =
    case find ("str:" `isPrefixOf`) (map trim (lines output)) of
        Just line ->
            let value = trim (drop (length ("str:" :: String)) line)
            in if null value then "desconocido" else value
        Nothing -> "desconocido"

setLayout :: LayoutOption -> IO ()
setLayout option = do
    _ <- spawnProcess "hyprctl" ["keyword", "general:layout", layoutName option]
    _ <- spawnProcess "notify-send" ["-a", "Hyprland", "Tiling actualizado", layoutName option]
    exitSuccess
