#!/usr/bin/env -S sh -c 'script_dir=$(dirname "$1"); exec runhaskell -i"$script_dir" -i"$script_dir/.." "$1" "$@"' sh

import Control.Monad (void, when)
import Data.List (intercalate)
import System.Directory (createDirectoryIfMissing, findExecutable, getHomeDirectory)
import System.Environment (lookupEnv)
import System.Exit (ExitCode (ExitSuccess))
import System.Process (callCommand, callProcess, readProcessWithExitCode, spawnProcess)

import StandaloneUtils (rofiLines, shellEscape, trim)

main :: IO ()
main = do
    home <- getHomeDirectory
    let dir = home ++ "/Pictures/Screenshots"
    createDirectoryIfMissing True dir

    timestamp <- currentTimestamp
    let filepath = dir ++ "/Captura_" ++ timestamp ++ ".png"
        options =
            [ "Seleccionar Area"
            , "Pantalla Completa"
            , "Retraso de 3s (Completa)"
            , "Ventana Activa"
            ]

    selection <- rofiLines "wm-shared-screenshot" "Captura" ["-i", "-l", show (length options)] options
    when (not (null selection)) $ takeScreenshot selection filepath

takeScreenshot :: String -> FilePath -> IO ()
takeScreenshot selection filepath = do
    wayland <- isWaylandSession
    captured <- case selection of
        "Seleccionar Area" ->
            if wayland
                then captureWaylandRegion filepath
                else captureX11Selection filepath
        "Pantalla Completa" ->
            if wayland
                then captureWaylandFull filepath
                else captureX11Full filepath
        "Retraso de 3s (Completa)" -> do
            callProcess "sleep" ["3"]
            if wayland
                then captureWaylandFull filepath
                else captureX11Full filepath
        "Ventana Activa" ->
            if wayland
                then captureWaylandActiveWindow filepath
                else captureX11ActiveWindow filepath
        _ -> pure False

    if captured
        then postCapture wayland filepath
        else notify "Captura" "No se pudo completar la captura."

isWaylandSession :: IO Bool
isWaylandSession = do
    sessionType <- lookupEnv "XDG_SESSION_TYPE"
    waylandDisplay <- lookupEnv "WAYLAND_DISPLAY"
    pure (sessionType == Just "wayland" || maybe False (not . null) waylandDisplay)

captureWaylandRegion :: FilePath -> IO Bool
captureWaylandRegion filepath = do
    (exitCode, region, _) <- readProcessWithExitCode "slurp" [] ""
    if exitCode == ExitSuccess && not (null (trim region))
        then runCommand "grim" ["-g", trim region, filepath]
        else pure False

captureWaylandFull :: FilePath -> IO Bool
captureWaylandFull filepath = runCommand "grim" [filepath]

captureWaylandActiveWindow :: FilePath -> IO Bool
captureWaylandActiveWindow filepath = do
    hyprctl <- findExecutable "hyprctl"
    jq <- findExecutable "jq"
    case (hyprctl, jq) of
        (Just _, Just _) -> do
            (exitCode, region, _) <- readProcessWithExitCode "sh"
                [ "-c"
                , "hyprctl activewindow -j | jq -r '\"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"'"
                ]
                ""
            if exitCode == ExitSuccess && not (null (trim region))
                then runCommand "grim" ["-g", trim region, filepath]
                else pure False
        _ -> pure False

captureX11Selection :: FilePath -> IO Bool
captureX11Selection filepath = runCommand "maim" ["-s", filepath]

captureX11Full :: FilePath -> IO Bool
captureX11Full filepath = runCommand "maim" [filepath]

captureX11ActiveWindow :: FilePath -> IO Bool
captureX11ActiveWindow filepath = do
    (exitCode, windowId, _) <- readProcessWithExitCode "xdotool" ["getactivewindow"] ""
    if exitCode == ExitSuccess && not (null (trim windowId))
        then runCommand "maim" ["-i", trim windowId, filepath]
        else pure False

postCapture :: Bool -> FilePath -> IO ()
postCapture wayland filepath = do
    copied <- copyImage wayland filepath
    let message =
            if copied
                then "Guardada en Imagenes y copiada al portapapeles."
                else "Guardada en Imagenes."
    callProcess "notify-send"
        [ "-a", "Screenshot"
        , "-i", filepath
        , "Captura exitosa"
        , message
        ]
    when wayland $ do
        swappy <- findExecutable "swappy"
        case swappy of
            Just _ -> void $ spawnProcess "swappy" ["-f", filepath]
            Nothing -> pure ()

copyImage :: Bool -> FilePath -> IO Bool
copyImage wayland filepath
    | wayland = do
        wlCopy <- findExecutable "wl-copy"
        case wlCopy of
            Just _ -> runShellCommand ("wl-copy < " ++ shellEscape filepath)
            Nothing -> pure False
    | otherwise = do
        xclip <- findExecutable "xclip"
        case xclip of
            Just _ -> runCommand "xclip" ["-selection", "clipboard", "-t", "image/png", "-i", filepath]
            Nothing -> pure False

runCommand :: FilePath -> [String] -> IO Bool
runCommand command args = do
    (exitCode, _, _) <- readProcessWithExitCode command args ""
    pure (exitCode == ExitSuccess)

runShellCommand :: String -> IO Bool
runShellCommand command = do
    (exitCode, _, _) <- readProcessWithExitCode "sh" ["-c", command] ""
    pure (exitCode == ExitSuccess)

currentTimestamp :: IO String
currentTimestamp = do
    (exitCode, out, _) <- readProcessWithExitCode "date" ["+%Y-%m-%d_%H-%M-%S"] ""
    pure $
        if exitCode == ExitSuccess
            then trim out
            else "captura"

notify :: String -> String -> IO ()
notify title msg = callProcess "notify-send" [title, msg]
