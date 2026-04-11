module Standalone.Productivity
    ( clearClipboardHistory
    , runClipboardMenu
    , runEmojiPicker
    , runProductivityMenu
    , runProjectsMenu
    , runTimerMenu
    ) where

import Control.Exception (IOException, try)
import Control.Monad (unless, void)
import Data.List (sort)
import System.Directory (createDirectoryIfMissing, doesDirectoryExist)
import System.Process (spawnProcess)

import Standalone.Menu (MenuSpec (..), menuEntry, runMenuSpec, selectMenuSpec)
import Standalone.Runtime
    ( isWaylandSession
    , notify
    , openUrl
    , readProcessSafe
    , requireHomeDirectory
    , spawnCommandSafe
    )
import StandaloneUtils
    ( currentTimestamp
    , rofiHelperPath
    , rofiSelection
    , rofiThemePath
    , shellEscape
    )

iconClip, iconProject, iconEmoji, iconNote, iconWeb, iconTimer, iconBack :: String
iconClip    = "\xf014c"
iconProject = "\xf14de"
iconEmoji   = "\xf0785"
iconNote    = "\xf044"
iconWeb     = "\xf0ac"
iconTimer   = "\xf017"
iconBack    = "\xf006e"

runProductivityMenu :: IO ()
runProductivityMenu = mainMenu

mainMenu :: IO ()
mainMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "wm-shared-productivity-main"
            , menuSpecPrompt = "Productividad"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry (iconProject ++ " Proyectos (dev)") runProjectsMenu
                , menuEntry (iconNote ++ " Notas Rapidas") notesMenu
                , menuEntry (iconTimer ++ " Temporizadores") runTimerMenu
                , menuEntry (iconWeb ++ " Busqueda Web") webSearchMenu
                , menuEntry (iconClip ++ " Portapapeles") clipboardMenu
                , menuEntry (iconEmoji ++ " Emojis") runEmojiPicker
                ]
            }

clipboardMenu :: IO ()
clipboardMenu = do
    wayland <- isWaylandSession
    theme <- rofiThemePath
    helper <- rofiHelperPath
    let themeArg = shellEscape theme
    if wayland
        then spawnCommandSafe $
            "cliphist list | " ++ helper
                ++ " --menu-id 'wm-shared-clipboard' --prompt 'Portapapeles' --theme "
                ++ themeArg
                ++ " -- -i | cliphist decode | wl-copy"
        else spawnCommandSafe $
            "rofi -modi 'clipboard:greenclip print' -show clipboard -run-command '{cmd}' -theme "
                ++ themeArg

runClipboardMenu :: IO ()
runClipboardMenu = clipboardMenu

clearClipboardHistory :: IO ()
clearClipboardHistory = do
    wayland <- isWaylandSession
    if wayland
        then spawnCommandSafe "cliphist wipe && notify-send '🧹 Clipboard' 'Historial limpiado'"
        else spawnCommandSafe "greenclip clear && notify-send '🧹 Clipboard' 'Historial limpiado'"

runEmojiPicker :: IO ()
runEmojiPicker = do
    theme <- rofiThemePath
    spawnCommandSafe ("rofi -show emoji -theme " ++ shellEscape theme)

notesMenu :: IO ()
notesMenu = do
    input <- rofiSelection "wm-shared-productivity-notes-input" "Anadir al Inbox (Vault)" ["-i"] ""
    unless (null input) $ do
        requireHomeDirectory "Error de disco" "No se encontro la variable HOME." $ \homeDir -> do
            let vaultDir = homeDir ++ "/dev/vault/notes"
                inboxPath = vaultDir ++ "/Inbox.md"
            createDirectoryIfMissing True vaultDir
            timestamp <- currentTimestamp "%Y-%m-%d %H:%M" "sin-fecha"
            result <- try (appendFile inboxPath ("- [" ++ timestamp ++ "] " ++ input ++ "\n")) :: IO (Either IOException ())
            case result of
                Left _ -> notify "critical" "Error de disco" ("No se pudo escribir en " ++ inboxPath)
                Right _ -> notify "normal" "Nota guardada" input

webSearchMenu :: IO ()
webSearchMenu = do
    query <- rofiSelection "wm-shared-productivity-web-search" "Buscar en Web (DuckDuckGo)" ["-i"] ""
    unless (null query) $
        openUrl ("https://duckduckgo.com/?q=" ++ map replaceSpace query)
  where
    replaceSpace ' ' = '+'
    replaceSpace c = c

runTimerMenu :: IO ()
runTimerMenu = timerMenu

timerMenu :: IO ()
timerMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "wm-shared-productivity-timer"
            , menuSpecPrompt = "Temporizador"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry "25 Minutos (Modo enfoque)" (startTimer 25 "Pomodoro")
                , menuEntry "15 Minutos (Breve)" (startTimer 15 "Descanso")
                , menuEntry "05 Minutos (Descanso)" (startTimer 5 "Descanso")
                , menuEntry "10 Minutos" (startTimer 10 "Timer")
                , menuEntry "45 Minutos" (startTimer 45 "Timer")
                , menuEntry "60 Minutos" (startTimer 60 "Timer")
                , menuEntry "Personalizado" customTimer
                , menuEntry (iconBack ++ " Volver") mainMenu
                ]
            }

customTimer :: IO ()
customTimer = do
    res <- rofiSelection "wm-shared-productivity-timer-custom" "Minutos" ["-i"] ""
    case reads res :: [(Int, String)] of
        [(mins, "")] | mins > 0 -> startTimer mins "Timer personalizado"
        _ -> notify "normal" "Temporizador" "Entrada invalida. Usa un numero entero positivo."

startTimer :: Int -> String -> IO ()
startTimer mins label = do
    let seconds = mins * 60
        title = label ++ " iniciado"
        message = "Te avisare en " ++ show mins ++ " minutos."
        doneTitle = "⏰ " ++ label
        doneMessage = "Han pasado " ++ show mins ++ " minutos."
    notify "normal" title message
    spawnCommandSafe $
        "bash -c 'sleep "
            ++ show seconds
            ++ " && notify-send -u critical "
            ++ shellEscape doneTitle
            ++ " "
            ++ shellEscape doneMessage
            ++ "'"

runProjectsMenu :: IO ()
runProjectsMenu =
    requireHomeDirectory "Proyectos" "No se encontro la variable HOME." $ \homeDir -> do
        let devDir = homeDir ++ "/dev"
        dirExists <- doesDirectoryExist devDir
        if not dirExists
            then notify "critical" "Directorio no encontrado" ("No se encontro la carpeta: " ++ devDir)
            else do
                projectsRaw <- readProcessSafe "find" [devDir, "-mindepth", "1", "-maxdepth", "2", "-type", "d", "-printf", "%P\n"] ""
                let projectsList = sort (lines projectsRaw)
                if null projectsList
                    then notify "normal" "Proyectos" "No se encontraron carpetas en ~/dev"
                    else do
                        let spec =
                                MenuSpec
                                    { menuSpecId = "wm-shared-productivity-projects"
                                    , menuSpecPrompt = "Abrir proyecto"
                                    , menuSpecArgs = ["-i", "-l", show (min 15 (length projectsList + 1))]
                                    , menuSpecEntries =
                                        map (\folder -> menuEntry folder folder) projectsList
                                            ++ [menuEntry (iconBack ++ " Volver") ""]
                                    }
                        selected <- selectMenuSpec spec
                        case selected of
                            Just "" -> mainMenu
                            Just folder -> void $ spawnProcess "ghostty" ["--working-directory=" ++ devDir ++ "/" ++ folder, "-e", "lvim", devDir ++ "/" ++ folder]
                            Nothing -> pure ()
