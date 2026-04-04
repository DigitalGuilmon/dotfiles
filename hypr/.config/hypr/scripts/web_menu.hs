#!/usr/bin/env runhaskell

import System.Process (readProcessWithExitCode, spawnProcess)
import System.Exit (ExitCode(ExitSuccess))
import Data.List (intercalate)

main :: IO ()
main = do
    -- Definimos la lista de sitios con sus respectivos emojis
    let options = [ "📺 YouTube"
                  , "🐦 X (Twitter)"
                  , "👽 Reddit"
                  , "🟢 WhatsApp"
                  , "🐙 GitHub"
                  , "📘 Facebook"
                  , "🏔️  ArchWiki"
                  , "🔗 LinkedIn"
                  ]
        inputStr = intercalate "\n" options

    -- Ejecutamos rofi en modo dmenu con ajustes para tu pantalla 2K y escalado 1.6
    (exitCode, out, _) <- readProcessWithExitCode "rofi" 
        [ "-dmenu"
        , "-i"                      -- Búsqueda insensible a mayúsculas
        , "-p", "🌐 Ir a"           -- Texto del prompt
        , "-l", show (length options)
        -- Ajustamos el ancho a 350px para compensar el escalado de 1.6
        , "-theme-str", "window { width: 350px; }" 
        ] 
        inputStr

    -- Si el usuario seleccionó una opción, abrimos la URL correspondiente
    if exitCode == ExitSuccess
        then do
            let selection = filter (/= '\n') out
            case selection of
                "📺 YouTube"     -> openInNewWindow "https://www.youtube.com"
                "🐦 X (Twitter)"  -> openInNewWindow "https://x.com"
                "👽 Reddit"      -> openInNewWindow "https://www.reddit.com"
                "🟢 WhatsApp"    -> openInNewWindow "https://web.whatsapp.com"
                "🐙 GitHub"      -> openInNewWindow "https://github.com"
                "📘 Facebook"    -> openInNewWindow "https://www.facebook.com"
                "🏔️  ArchWiki"    -> openInNewWindow "https://wiki.archlinux.org"
                "🔗 LinkedIn"    -> openInNewWindow "https://www.linkedin.com"
                _                -> return ()
        else
            return ()

-- Función para abrir la URL en una NUEVA VENTANA de Brave
openInNewWindow :: String -> IO ()
openInNewWindow url = do
    _ <- spawnProcess "brave" ["--new-window", url]
    return ()
