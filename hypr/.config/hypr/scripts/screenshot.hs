#!/usr/bin/env runhaskell

import System.Process (readProcessWithExitCode, callProcess, callCommand, spawnProcess)
import System.Exit (ExitCode(ExitSuccess))
import System.Directory (createDirectoryIfMissing, getHomeDirectory)
import Data.List (intercalate)
import Data.Time.Clock (getCurrentTime)
import Data.Time.Format (formatTime, defaultTimeLocale)

main :: IO ()
main = do
    -- 1. Preparar el directorio de guardado
    home <- getHomeDirectory
    let dir = home ++ "/Pictures/Screenshots"
    createDirectoryIfMissing True dir

    -- 2. Generar un nombre de archivo único con la fecha actual
    now <- getCurrentTime
    let timeStr = formatTime defaultTimeLocale "%Y-%m-%d_%H-%M-%S" now
    let filepath = dir ++ "/Captura_" ++ timeStr ++ ".png"

    -- 3. Opciones del menú interactivo
    let options = ["✂️  Seleccionar Área", "🖥️  Pantalla Completa", "⏱️  Retraso de 3s (Completa)"]
        inputStr = intercalate "\n" options

    -- 4. Ejecutamos rofi en modo dmenu con un ancho compacto para tu pantalla 2K (escalado 1.6)
    (exitCode, out, _) <- readProcessWithExitCode "rofi" 
        [ "-dmenu"
        , "-i"
        , "-p", "📸 Captura"
        , "-l", show (length options)
        -- Ancho ajustado a 350px para mejor legibilidad en tu monitor
        , "-theme-str", "window { width: 350px; }" 
        ] 
        inputStr

    if exitCode == ExitSuccess
        then do
            let selection = filter (/= '\n') out
            takeScreenshot selection filepath
        else 
            return () -- El usuario presionó ESC

-- Función que evalúa la selección y ejecuta la herramienta adecuada
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

        _ -> return ()

-- Función que toma la captura, notifica, copia y edita
processCapture :: [String] -> String -> IO ()
processCapture grimArgs filepath = do
    -- 1. Tomar la foto con grim
    callProcess "grim" grimArgs
    
    -- 2. Copiarla al portapapeles (wl-clipboard)
    callCommand $ "wl-copy < " ++ filepath
    
    -- 3. Enviar notificación a swaync con la miniatura
    callProcess "notify-send" 
        [ "-a", "Screenshot"
        , "-i", filepath
        , "✨ Captura Exitosa"
        , "Guardada en Imágenes y copiada al portapapeles."
        ]
        
    -- 4. Abrir swappy para editar
    _ <- spawnProcess "swappy" ["-f", filepath]
    return ()
