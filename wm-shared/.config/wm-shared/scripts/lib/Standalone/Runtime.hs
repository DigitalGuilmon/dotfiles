module Standalone.Runtime
    ( isWaylandSession
    , notify
    , openUrl
    , readProcessSafe
    , requireHomeDirectory
    , spawnCommandSafe
    ) where

import Control.Exception (IOException, catch)
import Control.Monad (void)
import Data.List (isPrefixOf)
import System.Directory (doesDirectoryExist, doesFileExist, findExecutable)
import System.Environment (lookupEnv)
import System.Exit (ExitCode (ExitSuccess))
import System.Process (readProcessWithExitCode, spawnCommand, spawnProcess)

import StandaloneUtils (notifySend)

notify :: String -> String -> String -> IO ()
notify urgency title message =
    notifySend ["-u", urgency, "-a", "wm-shared", title, message]

isWaylandSession :: IO Bool
isWaylandSession = do
    sessionType <- lookupEnv "XDG_SESSION_TYPE"
    waylandDisplay <- lookupEnv "WAYLAND_DISPLAY"
    pure (sessionType == Just "wayland" || maybe False (not . null) waylandDisplay)

spawnCommandSafe :: String -> IO ()
spawnCommandSafe command =
    catch (void $ spawnCommand command) handler
  where
    handler :: IOException -> IO ()
    handler _ = notify "critical" "Error de ejecucion" "No se pudo lanzar el comando."

readProcessSafe :: String -> [String] -> String -> IO String
readProcessSafe command args input =
    catch runCommand handler
  where
    runCommand = do
        (exitCode, out, _) <- readProcessWithExitCode command args input
        pure $
            if exitCode == ExitSuccess
                then out
                else ""
    handler :: IOException -> IO String
    handler _ = pure ""

openUrl :: String -> IO ()
openUrl target =
    catch
        (if isLocalTarget target then openLocalTarget target else openExternalTarget target)
        handler
  where
    handler :: IOException -> IO ()
    handler _ = notify "critical" "Abrir recurso" ("No se pudo abrir: " ++ target)

isLocalTarget :: String -> Bool
isLocalTarget target = "/" `isPrefixOf` target || "file://" `isPrefixOf` target

normalizeLocalTarget :: String -> String
normalizeLocalTarget target =
    if "file://" `isPrefixOf` target
        then drop 7 target
        else target

openLocalTarget :: String -> IO ()
openLocalTarget target = do
    let path = normalizeLocalTarget target
    fileExists <- doesFileExist path
    dirExists <- doesDirectoryExist path
    if not (fileExists || dirExists)
        then notify "critical" "Abrir recurso" ("La ruta no existe: " ++ path)
        else
            if dirExists
                then spawnFirstAvailable [("thunar", [path]), ("xdg-open", [path]), ("gio", ["open", path])]
                else spawnFirstAvailable [("xdg-open", [path]), ("gio", ["open", path]), ("thunar", [path])]

openExternalTarget :: String -> IO ()
openExternalTarget target =
    spawnFirstAvailable [("xdg-open", [target]), ("gio", ["open", target])]

spawnFirstAvailable :: [(FilePath, [String])] -> IO ()
spawnFirstAvailable [] =
    notify "critical" "Abrir recurso" "No se encontro una aplicacion disponible para abrir el recurso."
spawnFirstAvailable ((command, args) : rest) = do
    executable <- findExecutable command
    case executable of
        Just _ -> void $ spawnProcess command args
        Nothing -> spawnFirstAvailable rest

requireHomeDirectory :: String -> String -> (FilePath -> IO ()) -> IO ()
requireHomeDirectory errorTitle errorMessage action = do
    home <- lookupEnv "HOME"
    case home of
        Just homeDir -> action homeDir
        Nothing -> notify "critical" errorTitle errorMessage
