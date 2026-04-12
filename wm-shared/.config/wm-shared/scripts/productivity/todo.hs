#!/usr/bin/env -S sh -c 'script_dir=$(dirname "$1"); exec runhaskell -i"$script_dir" -i"$script_dir/.." "$1" "$@"' sh
{-# LANGUAGE OverloadedStrings #-}

import System.Exit (exitSuccess)
import System.Directory (getHomeDirectory, createDirectoryIfMissing, doesFileExist)
import Control.Exception (IOException, try)
import Control.Monad (unless, when)
import Data.List (isPrefixOf)
import Data.Time (getCurrentTime, formatTime, defaultTimeLocale)

import StandaloneUtils (notifySend, rofiLines, rofiSelection)

-- ==========================================
-- ICONOS
-- ==========================================
icAdd     = "\xf0415"
icCheck   = "\xf0134"
icPending = "\xf0131"
icDelete  = "\xf01f0"
icBack    = "\xf006e"
icList    = "\xf03a"

notify :: String -> String -> IO ()
notify title msg = notifySend ["-u", "normal", "-a", "TODO Manager", title, msg]

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
            contentResult <- try (readFile path) :: IO (Either IOException String)
            let content = either (const "") id contentResult
            let tasks = filter (not . null) $ lines content
            length tasks `seq` return tasks
        else return []

writeTasks :: [String] -> IO ()
writeTasks tasks = do
    path <- getTodoPath
    result <- try (writeFile path (unlines tasks)) :: IO (Either IOException ())
    case result of
        Left _ -> notify "Error" "No se pudo guardar las tareas"
        Right _ -> return ()

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

    selection <- rofiLines "hypr-todo-main" ("TODO [" ++ stats ++ "]") ["-i"] options
    case () of
        _ | null selection                        -> exitSuccess
          | "Agregar" `elem` words selection      -> addTask
          | "Pendientes" `elem` words selection   -> viewPending
          | "Completadas" `elem` words selection  -> viewCompleted
          | "Limpiar" `elem` words selection      -> cleanCompleted
          | otherwise                             -> exitSuccess

addTask :: IO ()
addTask = do
    input <- rofiSelection "hypr-todo-add" "Nueva Tarea" ["-i"] ""
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
            selection <- rofiLines "hypr-todo-pending" "Pendientes (seleccionar para completar)" ["-i"] display
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
            _ <- rofiLines "hypr-todo-completed" "Completadas" ["-i"] display
            mainMenu

cleanCompleted :: IO ()
cleanCompleted = do
    confirm <- rofiLines "hypr-todo-clean-confirm" "¿Eliminar todas las completadas?" ["-i"] ["Sí", "No"]
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
