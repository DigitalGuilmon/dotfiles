#!/usr/bin/env sh
#if 0
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
script_root="$script_dir"
while [ ! -d "$script_root/lib" ] && [ "$script_root" != "/" ]; do
    script_root=$(dirname "$script_root")
done
exec runhaskell -XCPP -i"$script_root/lib" "$0" "$@"
#endif
{-# LANGUAGE OverloadedStrings #-}

import System.Exit (exitSuccess)
import System.Directory (getHomeDirectory, createDirectoryIfMissing, doesFileExist)
import Control.Exception (IOException, try)
import Control.Monad (unless, when)
import Data.List (isPrefixOf)

import StandaloneUtils (confirmSelection, currentTimestamp, notifySend, rofiLines, rofiSelection, runMenu)

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
    let dir = home ++ "/.local/share/wm-shared/todo"
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
    runMenu "hypr-todo-main" ("TODO [" ++ stats ++ "]") ["-i"]
        [ (icAdd    ++ " Agregar Tarea", addTask)
        , (icList   ++ " Ver Pendientes (" ++ show (length pending) ++ ")", viewPending)
        , (icCheck  ++ " Ver Completadas (" ++ show (length completed) ++ ")", viewCompleted)
        , (icDelete ++ " Limpiar Completadas", cleanCompleted)
        ]

addTask :: IO ()
addTask = do
    input <- rofiSelection "hypr-todo-add" "Nueva Tarea" ["-i"] ""
    unless (null input) $ do
        timestamp <- currentTimestamp "%Y-%m-%d" "sin-fecha"
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
    confirmed <- confirmSelection "hypr-todo-clean-confirm" "¿Eliminar todas las completadas?"
    when confirmed $ do
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
