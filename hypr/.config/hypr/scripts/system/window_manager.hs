#!/usr/bin/env runhaskell

import System.Process (readProcessWithExitCode, spawnProcess)
import System.Exit (ExitCode(ExitSuccess))
import Data.List (intercalate)

main :: IO ()
main = do
    -- Usamos emojis estándar para evitar errores de compilación GHC
    let options = [ "❌ Cerrar Todo (Global)"
                  , "🧹 Cerrar Workspace Actual"
                  , "🌐 Cerrar Google Chrome"
                  , "🦁 Cerrar Brave Browser"
                  , "💻 Cerrar todas las Terminales"
                  ]
        inputStr = intercalate "\n" options

    -- Ejecutamos rofi con los mismos ajustes de tus otros scripts
    (exitCode, out, _) <- readProcessWithExitCode "rofi" 
        [ "-dmenu"
        , "-i"
        , "-p", "🪟 Ventanas"
        , "-l", show (length options)
        , "-theme-str", "window { width: 400px; }" 
        ] 
        inputStr

    if exitCode == ExitSuccess
        then do
            let selection = filter (/= '\n') out
            case selection of
                "❌ Cerrar Todo (Global)"       -> runCmd "hyprctl clients -j | jq -r '.[].address' | xargs -I {} hyprctl dispatch closewindow address:{}"
                "🧹 Cerrar Workspace Actual"    -> runCmd "hyprctl clients -j | jq -r \".[] | select(.workspace.id == $(hyprctl activeworkspace -j | jq '.id')) | .address\" | xargs -I {} hyprctl dispatch closewindow address:{}"
                "🌐 Cerrar Google Chrome"      -> runCmd "hyprctl clients -j | jq -r '.[] | select(.class == \"google-chrome\") | .address' | xargs -I {} hyprctl dispatch closewindow address:{}"
                "🦁 Cerrar Brave Browser"      -> runCmd "hyprctl clients -j | jq -r '.[] | select(.class == \"brave-browser\") | .address' | xargs -I {} hyprctl dispatch closewindow address:{}"
                "💻 Cerrar todas las Terminales" -> runCmd "hyprctl clients -j | jq -r '.[] | select(.class == \"com.mitchellh.ghostty\") | .address' | xargs -I {} hyprctl dispatch closewindow address:{}"
                _                              -> return ()
        else
            return ()

-- Función para ejecutar comandos de shell de forma segura
runCmd :: String -> IO ()
runCmd cmd = do
    _ <- spawnProcess "sh" ["-c", cmd]
    return ()
