#!/usr/bin/env runhaskell

import System.Process (readProcessWithExitCode, spawnProcess)
import System.Exit (ExitCode(ExitSuccess))
import Data.List (intercalate)

main :: IO ()
main = do
    -- Definimos las opciones
    let options = ["✨ Gemini", "🧠 Claude", "✖️ Grok", "💬 ChatGPT"]
        inputStr = intercalate "\n" options

    -- Ejecutamos rofi en modo dmenu e inyectamos un ancho pequeño para tu pantalla 2K
    (exitCode, out, _) <- readProcessWithExitCode "rofi" 
        [ "-dmenu"
        , "-i"                      -- Búsqueda insensible a mayúsculas
        , "-p", "🤖 AI"             -- Prompt corto
        , "-l", show (length options)
        -- Ajustamos el ancho a 300px para que se vea fino con escalado 1.6
        , "-theme-str", "window { width: 300px; }" 
        ] 
        inputStr

    -- Verificamos la selección
    if exitCode == ExitSuccess
        then do
            let selection = filter (/= '\n') out
            case selection of
                "✨ Gemini"   -> openUrl "https://gemini.google.com"
                "🧠 Claude"   -> openUrl "https://claude.ai"
                "✖️ Grok"     -> openUrl "https://x.com/i/grok"
                "💬 ChatGPT"  -> openUrl "https://chatgpt.com"
                _             -> return ()
        else
            return ()

-- Función para abrir en Brave
openUrl :: String -> IO ()
openUrl url = do
    _ <- spawnProcess "brave" ["--new-tab", url]
    return ()
