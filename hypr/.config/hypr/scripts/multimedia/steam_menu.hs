#!/usr/bin/env runhaskell

import System.Process (readProcessWithExitCode, spawnProcess)
import System.Exit (ExitCode(ExitSuccess))
import System.Directory (getHomeDirectory, listDirectory, doesDirectoryExist, doesFileExist)
import Data.List (intercalate, isSuffixOf, isInfixOf, break)
import Data.Maybe (mapMaybe)
import Control.Monad (filterM)

-- Estructura para manejar los juegos y sus iconos
data Game = Game { name :: String, appId :: String, iconPath :: FilePath } deriving (Show)

main :: IO ()
main = do
    home <- getHomeDirectory
    -- Rutas comunes de la librería de Steam
    let steamPaths = [ home ++ "/.local/share/Steam/steamapps"
                     , home ++ "/.local/share/steam/steamapps"
                     , home ++ "/.steam/steam/steamapps" ]
    
    validPaths <- filterM doesDirectoryExist steamPaths
    
    case validPaths of
        [] -> putStrLn "No se encontró la carpeta de Steam."
        (libPath:_) -> do
            -- Carpeta donde Steam guarda los iconos de la biblioteca
            let iconCache = home ++ "/.local/share/Steam/appcache/librarycache/"
            
            files <- listDirectory libPath
            let acfFiles = filter (isSuffixOf ".acf") files
            
            games <- mapM (parseGame libPath iconCache) acfFiles
            let validGames = mapMaybe id games
            
            -- Construcción de la entrada para Rofi: "Nombre\0icon\x1fRutaIcono"
            let rofiInput = intercalate "\n" $ map (\g -> name g ++ "\0icon\x1f" ++ iconPath g) validGames
            
            -- Ejecución de Rofi inyectando tu estilo de Hyprland (Borde #c678dd y rounding 12)
            (exitCode, out, _) <- readProcessWithExitCode "rofi" 
                [ "-dmenu", "-i", "-p", "🕹️  Steam", "-show-icons"
                , "-theme-str", "window { width: 35%; border: 2px; border-color: #c678dd; border-radius: 12px; background-color: #1e1e2e; }"
                , "-theme-str", "element { padding: 8px; border-radius: 10px; }"
                , "-theme-str", "element selected { background-color: #313244; }"
                , "-theme-str", "element-icon { size: 48px; margin: 0 15px 0 0; }"
                , "-theme-str", "listview { lines: 8; }"
                ] rofiInput

            if exitCode == ExitSuccess
                then do
                    let selectedName = filter (/= '\n') out
                    case filter (\g -> name g == selectedName) validGames of
                        (g:_) -> spawnProcess "steam" ["steam://run/" ++ appId g] >> return ()
                        _     -> return ()
                else return ()

-- Parsea el archivo .acf y busca el icono correspondiente
parseGame :: FilePath -> FilePath -> FilePath -> IO (Maybe Game)
parseGame libPath iconCache file = do
    content <- readFile (libPath ++ "/" ++ file)
    let ls = lines content
    let gName = extractValue "name" ls
    let gId = extractValue "appid" ls
    case (gName, gId) of
        (Just n, Just i) | i /= "228980" -> do
            -- Steam guarda los iconos como appid_icon.jpg
            let fullIconPath = iconCache ++ i ++ "_icon.jpg"
            exists <- doesFileExist fullIconPath
            let finalIcon = if exists then fullIconPath else "steam"
            return $ Just $ Game n i finalIcon
        _ -> return Nothing

-- Extrae valores manejando nombres completos entre comillas
extractValue :: String -> [String] -> Maybe String
extractValue key ls = 
    case filter (\l -> ("\"" ++ key ++ "\"") `isInfixOf` l) ls of
        (line:_) -> case splitByQuotes line of
                      (_:val:_) -> Just val
                      _         -> Nothing
        _        -> Nothing
  where
    splitByQuotes s = case dropWhile (/= '"') s of
        "" -> []
        (_:remainder) -> let (quoted, rest) = break (== '"') remainder
                         in quoted : splitByQuotes (drop 1 rest)
