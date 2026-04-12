#!/usr/bin/env -S sh -c 'script_dir=$(dirname "$1"); exec runhaskell -i"$script_dir" -i"$script_dir/.." "$1" "$@"' sh

import System.Environment (getArgs)
import System.Exit (ExitCode(ExitSuccess))
import System.Process (readProcessWithExitCode, spawnProcess)
import Data.List (find, intercalate)

import StandaloneUtils (rofiLines)

data WindowEntry = WindowEntry
    { windowAddress :: String
    , windowWorkspace :: String
    , windowClass :: String
    , windowTitle :: String
    }

main :: IO ()
main = do
    args <- getArgs
    case args of
        ["--list"] -> pickWindow
        ["--close-all"] -> closeAllWindows
        _ -> showWindowActions

showWindowActions :: IO ()
showWindowActions = do
    let options = [ "🔎 Mostrar todas las ventanas"
                  , "❌ Cerrar Todo (Global)"
                  , "🧹 Cerrar Workspace Actual"
                  , "🌐 Cerrar Google Chrome"
                  , "🦁 Cerrar Brave Browser"
                  , "💻 Cerrar todas las Terminales"
                  , "📌 Anclar Ventana (Pin)"
                  , "🔀 Mover Ventana a Workspace"
                  ]
    selection <- rofiLines "hypr-window-actions" "🪟 Ventanas" ["-i", "-l", show (length options)] options
    case selection of
        "🔎 Mostrar todas las ventanas"   -> pickWindow
        "❌ Cerrar Todo (Global)"         -> closeAllWindows
        "🧹 Cerrar Workspace Actual"      -> runCmd "hyprctl clients -j | jq -r \".[] | select(.workspace.id == $(hyprctl activeworkspace -j | jq '.id')) | .address\" | xargs -r -I {} hyprctl dispatch closewindow address:{}"
        "🌐 Cerrar Google Chrome"         -> runCmd "hyprctl clients -j | jq -r '.[] | select(.class == \"google-chrome\") | .address' | xargs -r -I {} hyprctl dispatch closewindow address:{}"
        "🦁 Cerrar Brave Browser"         -> runCmd "hyprctl clients -j | jq -r '.[] | select(.class == \"brave-browser\") | .address' | xargs -r -I {} hyprctl dispatch closewindow address:{}"
        "💻 Cerrar todas las Terminales" -> runCmd "hyprctl clients -j | jq -r '.[] | select(.class == \"com.mitchellh.ghostty\") | .address' | xargs -r -I {} hyprctl dispatch closewindow address:{}"
        "📌 Anclar Ventana (Pin)"         -> runCmd "hyprctl dispatch pin"
        "🔀 Mover Ventana a Workspace"    -> moveToWorkspace
        _                                 -> return ()

pickWindow :: IO ()
pickWindow = do
    windows <- getWindows
    let labels = if null windows
            then ["No hay ventanas abiertas"]
            else map formatWindowLabel windows

    selectedLabel <- rofiLines "hypr-window-list" "Todas las ventanas" ["-i", "-l", show (min 12 (length labels))] labels
    if not (null windows) && not (null selectedLabel)
        then do
            case find ((== selectedLabel) . formatWindowLabel) windows of
                Just entry -> focusWindow (windowAddress entry)
                Nothing    -> return ()
        else
            return ()

getWindows :: IO [WindowEntry]
getWindows = do
    let cmd = "hyprctl clients -j | jq -r 'sort_by(.workspace.id, .class, .title) | .[] | [.address, (.workspace.name // (.workspace.id | tostring)), (.class // \"Sin clase\"), (.title // \"Sin titulo\")] | @tsv'"
    (exitCode, out, _) <- readProcessWithExitCode "sh" ["-c", cmd] ""
    if exitCode == ExitSuccess
        then return $ mapMaybeWindow (lines out)
        else return []

mapMaybeWindow :: [String] -> [WindowEntry]
mapMaybeWindow = foldr collect []
  where
    collect line acc =
        case splitOn '\t' line of
            (address:workspaceName:className:titleParts) ->
                WindowEntry address workspaceName className (joinTitle titleParts) : acc
            _ -> acc

formatWindowLabel :: WindowEntry -> String
formatWindowLabel entry =
    "WS " ++ windowWorkspace entry
        ++ " | " ++ windowClass entry
        ++ " | " ++ fallback "Sin titulo" (sanitize (windowTitle entry))

focusWindow :: String -> IO ()
focusWindow address = runCmd $ "hyprctl dispatch focuswindow address:" ++ address

closeAllWindows :: IO ()
closeAllWindows = runCmd "hyprctl clients -j | jq -r '.[].address' | xargs -r -I {} hyprctl dispatch closewindow address:{}"

sanitize :: String -> String
sanitize = map replaceTab
  where
    replaceTab '\t' = ' '
    replaceTab c = c

fallback :: String -> String -> String
fallback def value =
    if null value
        then def
        else value

joinTitle :: [String] -> String
joinTitle = intercalate "\t"

splitOn :: Char -> String -> [String]
splitOn delimiter input =
    case break (== delimiter) input of
        (chunk, []) -> [chunk]
        (chunk, _:rest) -> chunk : splitOn delimiter rest

moveToWorkspace :: IO ()
moveToWorkspace = do
    let wsOptions = map (\n -> show n ++ " - Workspace " ++ show n) ([1..9] :: [Int])
    selected <- rofiLines "hypr-window-move-workspace" "Mover a Workspace" ["-i"] wsOptions
    if not (null selected)
        then do
            let ws = takeWhile (/= ' ') selected
            runCmd $ "hyprctl dispatch movetoworkspace " ++ ws
        else return ()

runCmd :: String -> IO ()
runCmd cmd = do
    _ <- spawnProcess "sh" ["-c", cmd]
    return ()
