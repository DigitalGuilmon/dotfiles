#!/usr/bin/env runhaskell

import Data.Char (isSpace)
import Data.List (dropWhileEnd, find, isPrefixOf)
import System.Directory (getHomeDirectory)
import System.Exit (ExitCode (ExitSuccess), exitSuccess)
import System.Process (readProcessWithExitCode, spawnProcess)

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
    home <- getHomeDirectory
    currentLayout <- getCurrentLayout
    selection <- rofi (home ++ "/.config/rofi/themes/modern.rasi") "hypr-layout-menu" ("Tiling (" ++ currentLayout ++ ")") (unlines (map layoutLabel layoutOptions))
    case find ((== selection) . layoutLabel) layoutOptions of
        Just option -> setLayout option
        Nothing -> exitSuccess

rofi :: String -> String -> String -> String -> IO String
rofi theme menuId prompt options = do
    home <- getHomeDirectory
    let helper = home ++ "/.config/rofi/scripts/frequent-menu.py"
    (exitCode, out, _) <- readProcessWithExitCode helper
        [ "--menu-id", menuId
        , "--prompt", prompt
        , "--theme", theme
        , "--", "-i"
        ]
        options
    if exitCode == ExitSuccess
        then return (trim out)
        else return ""

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

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace
