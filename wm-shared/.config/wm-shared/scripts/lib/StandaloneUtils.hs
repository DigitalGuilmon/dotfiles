module StandaloneUtils
    ( MenuOption
    , confirmSelection
    , currentTimestamp
    , notifySend
    , openBrowserUrl
    , rofiHelperPath
    , rofiInput
    , rofiLines
    , rofiSelection
    , rofiThemePath
    , runMenu
    , runUrlMenu
    , selectOption
    , shellEscape
    , spawnCommand_
    , trim
    ) where

import Control.Exception (IOException, try)
import Control.Monad (void)
import Common.Text (shellEscape, trimWhitespace)
import System.Directory (findExecutable, getHomeDirectory)
import System.Exit (ExitCode (ExitSuccess))
import System.Process (readProcessWithExitCode, spawnCommand, spawnProcess)

type MenuOption a = (String, a)

trim :: String -> String
trim = trimWhitespace

currentTimestamp :: String -> String -> IO String
currentTimestamp format fallbackValue = do
    result <- try (readProcessWithExitCode "date" ["+" ++ format] "") :: IO (Either IOException (ExitCode, String, String))
    pure $ case result of
        Right (ExitSuccess, out, _) ->
            let value = trim out
            in if null value then fallbackValue else value
        _ -> fallbackValue

rofiThemePath :: IO FilePath
rofiThemePath = do
    home <- getHomeDirectory
    pure $ home ++ "/.config/rofi/themes/modern.rasi"

rofiHelperPath :: IO FilePath
rofiHelperPath = do
    home <- getHomeDirectory
    pure $ home ++ "/.config/rofi/scripts/frequent-menu.py"

rofiSelection :: String -> String -> [String] -> String -> IO String
rofiSelection menuId prompt extraArgs input = do
    theme <- rofiThemePath
    helper <- rofiHelperPath
    let args =
            [ "--menu-id", menuId
            , "--prompt", prompt
            , "--theme", theme
            , "--"
            ] ++ extraArgs
    result <- try (readProcessWithExitCode helper args input) :: IO (Either IOException (ExitCode, String, String))
    pure $ case result of
        Right (ExitSuccess, out, _) -> trim out
        _ -> ""

rofiLines :: String -> String -> [String] -> [String] -> IO String
rofiLines menuId prompt extraArgs = rofiSelection menuId prompt extraArgs . unlines

rofiInput :: String -> String -> [String] -> String -> IO String
rofiInput = rofiSelection

selectOption :: String -> String -> [String] -> [MenuOption a] -> IO (Maybe a)
selectOption menuId prompt extraArgs options = do
    selection <- rofiLines menuId prompt extraArgs (map fst options)
    pure (lookup selection options)

runMenu :: String -> String -> [String] -> [MenuOption (IO ())] -> IO ()
runMenu menuId prompt extraArgs options = do
    selected <- selectOption menuId prompt extraArgs options
    maybe (pure ()) id selected

runUrlMenu :: String -> String -> [String] -> [MenuOption String] -> IO ()
runUrlMenu menuId prompt browserArgs options = do
    selected <- selectOption menuId prompt ["-i", "-l", show (length options)] options
    maybe (pure ()) (openBrowserUrl browserArgs) selected

confirmSelection :: String -> String -> IO Bool
confirmSelection menuId prompt = do
    selected <- selectOption menuId prompt ["-i"] [("Sí", True), ("No", False)]
    pure (selected == Just True)

notifySend :: [String] -> IO ()
notifySend = void . spawnProcess "notify-send"

spawnCommand_ :: String -> IO ()
spawnCommand_ = void . spawnCommand

openBrowserUrl :: [String] -> String -> IO ()
openBrowserUrl browserArgs url = openWith fallbackCommands
  where
    fallbackCommands =
        [ ("brave", browserArgs ++ [url])
        , ("xdg-open", [url])
        , ("gio", ["open", url])
        ]
    openWith [] =
        notifySend ["-u", "critical", "-a", "wm-shared", "Browser", "No se encontro un navegador o launcher web disponible."]
    openWith ((command, args) : rest) = do
        executable <- findExecutable command
        case executable of
            Just _ -> void $ spawnProcess command args
            Nothing -> openWith rest
