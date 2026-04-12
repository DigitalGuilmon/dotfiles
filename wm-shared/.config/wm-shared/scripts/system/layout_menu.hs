#!/usr/bin/env -S sh -c 'script_dir=$(dirname "$1"); exec runhaskell -i"$script_dir" -i"$script_dir/.." "$1" "$@"' sh

import Data.List (find, isPrefixOf)
import System.Exit (ExitCode (ExitSuccess), exitSuccess)
import System.Process (readProcessWithExitCode, spawnProcess)

import StandaloneUtils (rofiLines, trim)

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
    selection <- rofiLines "hypr-layout-menu" ("Tiling (" ++ currentLayout ++ ")") ["-i"] (map layoutLabel layoutOptions)
    case find ((== selection) . layoutLabel) layoutOptions of
        Just option -> setLayout option
        Nothing -> exitSuccess

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
