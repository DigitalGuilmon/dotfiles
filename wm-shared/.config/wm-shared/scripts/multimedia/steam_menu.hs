#!/usr/bin/env -S sh -c 'script_dir=$(dirname "$1"); exec runhaskell -i"$script_dir" -i"$script_dir/.." "$1" "$@"' sh

import System.Process (spawnProcess)
import System.Directory (getHomeDirectory, listDirectory, doesDirectoryExist, doesFileExist)
import System.FilePath ((</>), takeExtension, takeFileName)
import Data.List (isSuffixOf, isInfixOf, isPrefixOf, break, minimumBy)
import Data.Maybe (mapMaybe)
import Control.Monad (filterM)
import Data.Ord (comparing)

import StandaloneUtils (rofiSelection)

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
    
    if null validPaths 
        then putStrLn "No se encontró la carpeta de Steam."
        else do
            let libPath = head validPaths
            -- Carpeta donde Steam guarda los iconos de la biblioteca
            let iconCache = home ++ "/.local/share/Steam/appcache/librarycache/"
            
            files <- listDirectory libPath
            let acfFiles = filter (\f -> "appmanifest_" `isPrefixOf` f && isSuffixOf ".acf" f) files
            
            games <- mapM (parseGame libPath iconCache) acfFiles
            let validGames = mapMaybe id games
            
            -- Construcción de la entrada para Rofi: "Nombre\0icon\x1fRutaIcono"
            let rofiInput = unlines $ map (\g -> name g ++ "\0icon\x1f" ++ iconPath g) validGames
            selectedName <- rofiSelection
                "hypr-steam-menu"
                "🕹️  Steam"
                [ "-i", "-show-icons"
                , "-theme-str", "window { width: 35%; border: 2px; border-color: #c678dd; border-radius: 12px; background-color: #1e1e2e; }"
                , "-theme-str", "element { padding: 8px; border-radius: 10px; }"
                , "-theme-str", "element selected { background-color: #313244; }"
                , "-theme-str", "element-icon { size: 48px; margin: 0 15px 0 0; }"
                , "-theme-str", "listview { lines: 8; }"
                ]
                rofiInput
            case filter (\g -> name g == selectedName) validGames of
                (g:_) -> spawnProcess "steam" ["steam://run/" ++ appId g] >> return ()
                _     -> return ()

-- Parsea el archivo .acf y busca el icono correspondiente
parseGame :: FilePath -> FilePath -> FilePath -> IO (Maybe Game)
parseGame libPath iconCache file = do
    content <- readFile (libPath ++ "/" ++ file)
    let ls = lines content
    let gName = extractValue "name" ls
    let gId = extractValue "appid" ls
    case (gName, gId) of
        (Just n, Just i) | i /= "228980" -> do
            finalIcon <- findBestIcon iconCache i
            return $ Just $ Game n i finalIcon
        _ -> return Nothing

findBestIcon :: FilePath -> String -> IO FilePath
findBestIcon iconCache appId = do
    let appDir = iconCache </> appId
        legacyCandidates =
            [ iconCache </> (appId ++ "_icon.jpg")
            , iconCache </> (appId ++ "_icon.png")
            ]

    legacyIcons <- filterM doesFileExist legacyCandidates
    appIcons <-
        ifM (doesDirectoryExist appDir)
            (collectFiles appDir)
            (return [])

    let imageFiles = filter isSupportedImage appIcons
        candidates = imageFiles ++ legacyIcons

    return $ maybe "steam" id (pickPreferredArtwork candidates)

pickPreferredArtwork :: [FilePath] -> Maybe FilePath
pickPreferredArtwork [] = Nothing
pickPreferredArtwork files = Just $ minimumBy (comparing artworkPriority) files

artworkPriority :: FilePath -> Int
artworkPriority path
    | "library_600x900" `isPrefixOf` fileName = 1
    | "library_capsule" `isPrefixOf` fileName = 2
    | "library_header" `isPrefixOf` fileName = 3
    | "library_hero" `isPrefixOf` fileName && not ("blur" `isInfixOf` fileName) = 4
    | "_icon" `isInfixOf` fileName = 5
    | otherwise = 99
  where
    fileName = takeFileName path

isSupportedImage :: FilePath -> Bool
isSupportedImage path =
    takeExtension path `elem` [".jpg", ".jpeg", ".png"]

collectFiles :: FilePath -> IO [FilePath]
collectFiles dir = do
    entries <- listDirectory dir
    paths <- mapM descend entries
    return (concat paths)
  where
    descend entry = do
        let path = dir </> entry
        isDir <- doesDirectoryExist path
        if isDir
            then collectFiles path
            else return [path]

ifM :: IO Bool -> IO a -> IO a -> IO a
ifM condition onTrue onFalse = do
    result <- condition
    if result then onTrue else onFalse

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
