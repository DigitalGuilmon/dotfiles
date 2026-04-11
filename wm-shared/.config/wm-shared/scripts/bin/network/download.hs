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
{-# LANGUAGE ScopedTypeVariables #-}

import System.Process (spawnCommand)
import System.Directory (getHomeDirectory, listDirectory, getModificationTime, doesFileExist)
import System.FilePath (takeExtension, (</>), takeFileName)
import Control.Exception (IOException, try)
import Control.Monad (filterM, void, unless)
import Data.List (sortBy)
import Data.Ord (comparing, Down(..))

import StandaloneUtils (rofiLines, trim)

-- ==========================================
-- CONFIGURACIÓN VISUAL
-- ==========================================
colorFile = "#85E89D" 
colorHint = "#888888"

fmt col icon txt = "<span color='" ++ col ++ "'>" ++ icon ++ "</span>  " ++ txt

getIcon :: String -> String
getIcon ext = case ext of
    ".pdf"  -> "\xf1c1"
    ".zip"  -> "\xf1c6"
    ".rar"  -> "\xf1c6"
    ".png"  -> "\xf1c5"
    ".jpg"  -> "\xf1c5"
    ".mp4"  -> "\xf1c8"
    ".mp3"  -> "\xf001"
    _       -> "\xf016"

main :: IO ()
main = do
    home <- getHomeDirectory
    let downloadDir = home </> "Downloads" 
    
    filesResult <- try (listDirectory downloadDir) :: IO (Either IOException [FilePath])
    let files = either (const []) id filesResult
    let fullPaths = map (downloadDir </>) files
    
    existingFiles <- filterM doesFileExist fullPaths
    
    fileData <- mapM (\p -> do
        modTime <- getModificationTime p
        return (p, modTime)) existingFiles
    
    let sortedFiles = map fst $ sortBy (comparing (Down . snd)) fileData
    
    let menuOptions = map (\p -> 
            let name = takeFileName p
                ext  = takeExtension name
                icon = getIcon ext
            in fmt colorFile icon name) sortedFiles

    selection <- rofiLines "hypr-downloads-main" "Descargas Recientes" ["-i", "-markup-rows"] menuOptions
    
    unless (null selection) $ do
        let cleanName = extractName selection
        let finalPath = downloadDir </> cleanName
        void $ spawnCommand $ "xdg-open \"" ++ finalPath ++ "\""
extractName :: String -> String
extractName str = trim $ reverse $ takeWhile (/= ' ') $ takeWhile (/= '>') $ reverse str
