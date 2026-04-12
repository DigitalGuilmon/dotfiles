#!/usr/bin/env -S sh -c 'script_dir=$(dirname "$1"); exec runhaskell -i"$script_dir" -i"$script_dir/.." "$1" "$@"' sh
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcessWithExitCode, spawnCommand, spawnProcess)
import System.Exit (exitSuccess, ExitCode(..))
import Control.Monad (unless, void)
import System.Directory (getHomeDirectory, doesDirectoryExist, createDirectoryIfMissing)
import Control.Exception (catch, IOException)
import Data.List (sort)
import Data.Time (getCurrentTime, formatTime, defaultTimeLocale)

import StandaloneUtils (notifySend, rofiHelperPath, rofiLines, rofiSelection, rofiThemePath)

-- Iconos (Nerd Fonts)
iconClip    = "\xf014c"
iconProject = "\xf14de"
iconEmoji   = "\xf0785"
iconNote    = "\xf044"  
iconWeb     = "\xf0ac"  
iconTimer   = "\xf017"  
iconBack    = "\xf006e"

-- ==========================================
-- SISTEMA DE NOTIFICACIONES SEGURO (UX & Anti-Inyección)
-- ==========================================
notify :: String -> String -> String -> IO ()
notify urgency title message = 
    catch (void $ spawnProcess "notify-send" ["-u", urgency, "-a", "Hyprland Menu", title, message]) handleErr
  where
    handleErr :: IOException -> IO ()
    handleErr _ = return () 

type MenuOption = (String, IO ())

runMenu :: String -> String -> [MenuOption] -> IO ()
runMenu menuId prompt options = do
    selection <- rofiLines menuId prompt ["-i"] (map fst options)
    case lookup selection options of
        Just action -> action
        Nothing     -> exitSuccess 

-- ==========================================
-- MENÚ PRINCIPAL
-- ==========================================
main :: IO ()
main = mainMenu

mainMenu :: IO ()
mainMenu = runMenu "hypr-productivity-main" "Productividad"
    [ (iconProject ++ " Proyectos (dev)",  projectsMenu)
    , (iconNote    ++ " Notas Rápidas",    notesMenu)
    , (iconTimer   ++ " Temporizadores",   timerMenu)
    , (iconWeb     ++ " Búsqueda Web",     webSearchMenu)
    , (iconClip    ++ " Portapapeles",     clipboardMenu)
    , (iconEmoji   ++ " Emojis",           emojiMenu)
    ]

-- ==========================================
-- ACCIONES
-- ==========================================

clipboardMenu :: IO ()
clipboardMenu = do
    theme <- rofiThemePath
    helper <- rofiHelperPath
    safeSpawn $
        "cliphist list | " ++ helper
            ++ " --menu-id 'hypr-productivity-clipboard' --prompt 'Portapapeles' --theme "
            ++ theme ++ " -- -i | cliphist decode | wl-copy"
    exitSuccess

emojiMenu :: IO ()
emojiMenu = do
    theme <- rofiThemePath
    safeSpawn $ "rofi -show emoji -theme " ++ theme
    exitSuccess

-- ==========================================
-- 1. NOTAS RÁPIDAS
-- ==========================================
notesMenu :: IO ()
notesMenu = do
    input <- rofiSelection "hypr-productivity-notes-input" "Añadir al Inbox (Vault)" ["-i"] ""
    unless (null input) $ do
        home <- getHomeDirectory
        let vaultDir = home ++ "/dev/vault/notes"
        let inboxPath = vaultDir ++ "/Inbox.md"
        
        createDirectoryIfMissing True vaultDir
        
        now <- getCurrentTime
        let timestamp = formatTime defaultTimeLocale "%Y-%m-%d %H:%M" now
        
        let saveAction = appendFile inboxPath ("- [" ++ timestamp ++ "] " ++ input ++ "\n")
        catch saveAction (\e -> do
            let _ = e :: IOException
            notify "critical" "Error de Disco" ("No se pudo escribir en " ++ inboxPath))
        
        notify "normal" "Nota Guardada" input
    exitSuccess

-- ==========================================
-- 2. BÚSQUEDA WEB
-- ==========================================
webSearchMenu :: IO ()
webSearchMenu = do
    query <- rofiSelection "hypr-productivity-web-search" "Buscar en Web (DuckDuckGo)" ["-i"] ""
    unless (null query) $ do
        let urlQuery = map (\c -> if c == ' ' then '+' else c) query
        catch (void $ spawnProcess "xdg-open" ["https://duckduckgo.com/?q=" ++ urlQuery]) 
              (\e -> let _ = e :: IOException in notify "critical" "Error" "No se pudo abrir el navegador")
    exitSuccess

-- ==========================================
-- 3. TEMPORIZADORES
-- ==========================================
timerMenu :: IO ()
timerMenu = runMenu "hypr-productivity-timer" "Temporizador"
    [ ("25 Minutos (Modo Enfoque)", startTimer 25)
    , ("15 Minutos (Breve)",        startTimer 15)
    , ("05 Minutos (Descanso)",      startTimer 5)
    , (iconBack ++ " Volver",        mainMenu)
    ]

startTimer :: Int -> IO ()
startTimer mins = do
    let seconds = mins * 60
    notify "normal" "Temporizador Iniciado" ("Te avisaré en " ++ show mins ++ " minutos.")
    safeSpawn $ "bash -c 'sleep " ++ show seconds ++ " && notify-send -u critical -a Pomodoro \"¡Tiempo Terminado!\" \"Han pasado " ++ show mins ++ " minutos.\"' &"
    exitSuccess

-- ==========================================
-- 4. PROYECTOS
-- ==========================================
projectsMenu :: IO ()
projectsMenu = do
    home <- getHomeDirectory
    let devDir = home ++ "/dev"
    
    dirExists <- doesDirectoryExist devDir
    if not dirExists
        then do
            notify "critical" "Directorio no encontrado" ("No se encontró la carpeta: " ++ devDir)
            mainMenu
        else do
            projectsRaw <- safeReadProcess "find" [devDir, "-mindepth", "1", "-maxdepth", "2", "-type", "d", "-printf", "%P\n"] ""
            let projectsList = sort (lines projectsRaw)
            
            if null projectsList
                then do
                    notify "normal" "Proyectos" "No se encontraron carpetas en ~/dev"
                    mainMenu
                else do
                     let projectOptions = map (\folder -> (folder, openProject devDir folder)) projectsList
                                          ++ [(iconBack ++ " Volver", mainMenu)]
                     runMenu "hypr-productivity-projects" "Abrir Proyecto" projectOptions

openProject :: String -> String -> IO ()
openProject baseDir folder = do
    safeSpawn $ "ghostty --working-directory=" ++ baseDir ++ "/" ++ folder ++ " -e lvim"
    exitSuccess

safeSpawn :: String -> IO ()
safeSpawn cmd = catch (void $ spawnCommand cmd) handler
  where
    handler :: IOException -> IO ()
    handler _ = notify "critical" "Error de Ejecución" ("Fallo al ejecutar comando en Bash.")

safeReadProcess :: String -> [String] -> String -> IO String
safeReadProcess cmd args input = catch runCmd handler
  where
    runCmd = do
        (exitCode, out, _) <- readProcessWithExitCode cmd args input
        case exitCode of
            ExitSuccess   -> return out
            ExitFailure _ -> return ""
    handler :: IOException -> IO String
    handler _ = return ""
