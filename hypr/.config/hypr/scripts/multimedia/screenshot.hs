#!/usr/bin/env runhaskell

import System.Process (readProcessWithExitCode, callProcess, callCommand, spawnProcess)
import System.Exit (ExitCode(ExitSuccess))
import System.Directory (createDirectoryIfMissing, getHomeDirectory)
import Data.List (intercalate)
import Data.Time.Clock (getCurrentTime)
import Data.Time.Format (formatTime, defaultTimeLocale)

main :: IO ()
main = do
    home <- getHomeDirectory
    let dir = home ++ "/Pictures/Screenshots"
        theme = home ++ "/.config/rofi/themes/modern.rasi"
    createDirectoryIfMissing True dir

    now <- getCurrentTime
    let timeStr = formatTime defaultTimeLocale "%Y-%m-%d_%H-%M-%S" now
    let filepath = dir ++ "/Captura_" ++ timeStr ++ ".png"

    let options = [ "✂️  Seleccionar Área"
                  , "🖥️  Pantalla Completa"
                  , "⏱️  Retraso de 3s (Completa)"
                  , "🪟  Ventana Activa"
                  ]
        inputStr = intercalate "\n" options

    (exitCode, out, _) <- readProcessWithExitCode "rofi" 
        [ "-dmenu"
        , "-i"
        , "-p", "📸 Captura"
        , "-l", show (length options)
        , "-theme", theme
        ] 
        inputStr

    if exitCode == ExitSuccess
        then do
            let selection = filter (/= '\n') out
            takeScreenshot selection filepath
        else 
            return ()

takeScreenshot :: String -> String -> IO ()
takeScreenshot selection filepath = do
    case selection of
        "✂️  Seleccionar Área" -> do
            (exitSlurp, slurpOut, _) <- readProcessWithExitCode "slurp" [] ""
            if exitSlurp == ExitSuccess
                then do
                    let region = filter (/= '\n') slurpOut
                    processCapture ["-g", region, filepath] filepath
                else return () 

        "🖥️  Pantalla Completa" -> do
            processCapture [filepath] filepath

        "⏱️  Retraso de 3s (Completa)" -> do
            callProcess "sleep" ["3"]
            processCapture [filepath] filepath

        "🪟  Ventana Activa" -> do
            (exitGeom, geomOut, _) <- readProcessWithExitCode "sh" 
                ["-c", "hyprctl activewindow -j | jq -r '\"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"'"] ""
            if exitGeom == ExitSuccess
                then do
                    let region = filter (/= '\n') geomOut
                    processCapture ["-g", region, filepath] filepath
                else return ()

        _ -> return ()

processCapture :: [String] -> String -> IO ()
processCapture grimArgs filepath = do
    callProcess "grim" grimArgs
    callCommand $ "wl-copy < " ++ filepath
    callProcess "notify-send" 
        [ "-a", "Screenshot"
        , "-i", filepath
        , "✨ Captura Exitosa"
        , "Guardada en Imágenes y copiada al portapapeles."
        ]
    _ <- spawnProcess "swappy" ["-f", filepath]
    return ()
