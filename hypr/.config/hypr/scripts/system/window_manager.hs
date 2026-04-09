#!/usr/bin/env runhaskell

import System.Process (readProcessWithExitCode, spawnProcess)
import System.Exit (ExitCode(ExitSuccess))
import System.Directory (getHomeDirectory)
import Data.List (intercalate)

main :: IO ()
main = do
    home <- getHomeDirectory
    let theme = home ++ "/.config/rofi/themes/modern.rasi"

    let options = [ "❌ Cerrar Todo (Global)"
                  , "🧹 Cerrar Workspace Actual"
                  , "🌐 Cerrar Google Chrome"
                  , "🦁 Cerrar Brave Browser"
                  , "💻 Cerrar todas las Terminales"
                  , "📌 Anclar Ventana (Pin)"
                  , "🔀 Mover Ventana a Workspace"
                  ]
        inputStr = intercalate "\n" options

    (exitCode, out, _) <- readProcessWithExitCode "rofi" 
        [ "-dmenu"
        , "-i"
        , "-p", "🪟 Ventanas"
        , "-l", show (length options)
        , "-theme", theme
        ] 
        inputStr

    if exitCode == ExitSuccess
        then do
            let selection = filter (/= '\n') out
            case selection of
                "❌ Cerrar Todo (Global)"        -> runCmd "hyprctl clients -j | jq -r '.[].address' | xargs -I {} hyprctl dispatch closewindow address:{}"
                "🧹 Cerrar Workspace Actual"     -> runCmd "hyprctl clients -j | jq -r \".[] | select(.workspace.id == $(hyprctl activeworkspace -j | jq '.id')) | .address\" | xargs -I {} hyprctl dispatch closewindow address:{}"
                "🌐 Cerrar Google Chrome"        -> runCmd "hyprctl clients -j | jq -r '.[] | select(.class == \"google-chrome\") | .address' | xargs -I {} hyprctl dispatch closewindow address:{}"
                "🦁 Cerrar Brave Browser"        -> runCmd "hyprctl clients -j | jq -r '.[] | select(.class == \"brave-browser\") | .address' | xargs -I {} hyprctl dispatch closewindow address:{}"
                "💻 Cerrar todas las Terminales"  -> runCmd "hyprctl clients -j | jq -r '.[] | select(.class == \"com.mitchellh.ghostty\") | .address' | xargs -I {} hyprctl dispatch closewindow address:{}"
                "📌 Anclar Ventana (Pin)"        -> runCmd "hyprctl dispatch pin"
                "🔀 Mover Ventana a Workspace"   -> moveToWorkspace theme
                _                                -> return ()
        else
            return ()

moveToWorkspace :: String -> IO ()
moveToWorkspace theme = do
    let wsOptions = intercalate "\n" $ map (\n -> show n ++ " - Workspace " ++ show n) ([1..9] :: [Int])
    (exitCode, out, _) <- readProcessWithExitCode "rofi"
        [ "-dmenu", "-i", "-p", "Mover a Workspace", "-theme", theme ]
        wsOptions
    if exitCode == ExitSuccess
        then do
            let ws = takeWhile (/= ' ') $ filter (/= '\n') out
            runCmd $ "hyprctl dispatch movetoworkspace " ++ ws
        else return ()

runCmd :: String -> IO ()
runCmd cmd = do
    _ <- spawnProcess "sh" ["-c", cmd]
    return ()
