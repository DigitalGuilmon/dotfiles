#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcessWithExitCode, spawnCommand)
import System.Exit (exitSuccess, ExitCode(..))
import System.Directory (getHomeDirectory, createDirectoryIfMissing, doesFileExist)
import Control.Exception (catch, IOException)
import Control.Monad (void, unless, when)
import Data.Char (isSpace)
import Data.List (dropWhileEnd, isPrefixOf)
import Data.Time (getCurrentTime, formatTime, defaultTimeLocale)

-- ==========================================
-- ICONOS
-- ==========================================
icAdd     = "\xf0415"
icCheck   = "\xf0134"
icPending = "\xf0131"
icDelete  = "\xf01f0"
icBack    = "\xf006e"
icList    = "\xf03a"

-- ==========================================
-- HELPERS
-- ==========================================

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace

rofi :: String -> String -> IO String
rofi prompt opts = do
    home <- getHomeDirectory
    let theme = home ++ "/.config/rofi/themes/modern.rasi"
    (exitCode, out, _) <- catch (readProcessWithExitCode "rofi" ["-dmenu", "-i", "-p", prompt, "-theme", theme] opts)
                                (\(_ :: IOException) -> return (ExitFailure 1, "", ""))
    return $ trim out

notify :: String -> String -> IO ()
notify title msg = void $ spawnCommand $ "notify-send -u normal -a 'TODO Manager' '" ++ title ++ "' '" ++ msg ++ "'"

-- ==========================================
-- ARCHIVO DE TAREAS
-- ==========================================

getTodoPath :: IO FilePath
getTodoPath = do
    home <- getHomeDirectory
    let dir = home ++ "/.local/share/hypr-todo"
    createDirectoryIfMissing True dir
    return $ dir ++ "/tasks.txt"

readTasks :: IO [String]
readTasks = do
    path <- getTodoPath
    exists <- doesFileExist path
    if exists
        then do
            content <- catch (readFile path) (\(_ :: IOException) -> return "")
            let tasks = filter (not . null) $ lines content
            length tasks `seq` return tasks
        else return []

writeTasks :: [String] -> IO ()
writeTasks tasks = do
    path <- getTodoPath
    catch (writeFile path (unlines tasks)) (\(_ :: IOException) -> notify "Error" "No se pudo guardar las tareas")

-- ==========================================
-- LÓGICA PRINCIPAL
-- ==========================================

main :: IO ()
main = mainMenu

mainMenu :: IO ()
mainMenu = do
    tasks <- readTasks
    let pending   = filter ("[ ] " `isPrefixOf`) tasks
        completed = filter ("[x] " `isPrefixOf`) tasks
        stats     = show (length completed) ++ "/" ++ show (length tasks) ++ " completadas"

    let options = [ icAdd    ++ " Agregar Tarea"
                  , icList   ++ " Ver Pendientes (" ++ show (length pending) ++ ")"
                  , icCheck  ++ " Ver Completadas (" ++ show (length completed) ++ ")"
                  , icDelete ++ " Limpiar Completadas"
                  ]

    selection <- rofi ("TODO [" ++ stats ++ "]") (unlines options)
    case () of
        _ | null selection                        -> exitSuccess
          | "Agregar" `elem` words selection      -> addTask
          | "Pendientes" `elem` words selection   -> viewPending
          | "Completadas" `elem` words selection  -> viewCompleted
          | "Limpiar" `elem` words selection      -> cleanCompleted
          | otherwise                             -> exitSuccess

addTask :: IO ()
addTask = do
    input <- rofi "Nueva Tarea" ""
    unless (null input) $ do
        now <- getCurrentTime
        let timestamp = formatTime defaultTimeLocale "%Y-%m-%d" now
        tasks <- readTasks
        let newTask = "[ ] " ++ input ++ " (" ++ timestamp ++ ")"
        writeTasks (tasks ++ [newTask])
        notify "Tarea Agregada" input
    mainMenu

viewPending :: IO ()
viewPending = do
    tasks <- readTasks
    let pending = filter ("[ ] " `isPrefixOf`) tasks
    if null pending
        then do
            notify "TODO" "No hay tareas pendientes"
            mainMenu
        else do
            let display = map formatPending (zip [1..] pending)
            selection <- rofi "Pendientes (seleccionar para completar)" (unlines display)
            unless (null selection) $ do
                let idx = parseIndex selection
                case idx of
                    Just i -> markComplete i tasks
                    Nothing -> return ()
            mainMenu

viewCompleted :: IO ()
viewCompleted = do
    tasks <- readTasks
    let completed = filter ("[x] " `isPrefixOf`) tasks
    if null completed
        then do
            notify "TODO" "No hay tareas completadas"
            mainMenu
        else do
            let display = map formatCompleted (zip [1..] completed)
            _ <- rofi "Completadas" (unlines display)
            mainMenu

cleanCompleted :: IO ()
cleanCompleted = do
    confirm <- rofi "¿Eliminar todas las completadas?" "Sí\nNo"
    when (confirm == "Sí") $ do
        tasks <- readTasks
        let remaining = filter (not . ("[x] " `isPrefixOf`)) tasks
        let removed = length tasks - length remaining
        writeTasks remaining
        notify "Limpieza" (show removed ++ " tareas eliminadas")
    mainMenu

-- ==========================================
-- HELPERS DE FORMATO
-- ==========================================

formatPending :: (Int, String) -> String
formatPending (n, task) =
    let content = drop 4 task
    in icPending ++ " " ++ show n ++ ". " ++ content

formatCompleted :: (Int, String) -> String
formatCompleted (n, task) =
    let content = drop 4 task
    in icCheck ++ " " ++ show n ++ ". " ++ content

markComplete :: Int -> [String] -> IO ()
markComplete targetIdx tasks = do
    let pending = filter ("[ ] " `isPrefixOf`) tasks
    if targetIdx >= 1 && targetIdx <= length pending
        then do
            let targetTask = pending !! (targetIdx - 1)
                updated = map (\t -> if t == targetTask then "[x] " ++ drop 4 t else t) tasks
            writeTasks updated
            notify "Completada" (drop 4 targetTask)
        else return ()

parseIndex :: String -> Maybe Int
parseIndex s =
    let digits = takeWhile (/= '.') $ dropWhile (not . (`elem` ['0'..'9'])) s
    in case reads digits :: [(Int, String)] of
        [(n, _)] -> Just n
        _        -> Nothing
