module StandaloneUtils
    ( notifySend
    , rofiHelperPath
    , rofiInput
    , rofiLines
    , rofiSelection
    , rofiThemePath
    , shellEscape
    , trim
    ) where

import Control.Exception (IOException, try)
import Control.Monad (void)
import Data.Char (isSpace)
import Data.List (dropWhileEnd)
import System.Directory (getHomeDirectory)
import System.Exit (ExitCode (ExitSuccess))
import System.Process (readProcessWithExitCode, spawnProcess)

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace

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

notifySend :: [String] -> IO ()
notifySend = void . spawnProcess "notify-send"

shellEscape :: String -> String
shellEscape s = "'" ++ concatMap escapeChar s ++ "'"
  where
    escapeChar '\'' = "'\\''"
    escapeChar c = [c]
