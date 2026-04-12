#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}

import System.Process (spawnCommand, readProcessWithExitCode)
import System.Exit (exitSuccess, ExitCode(..))
import System.Directory (getHomeDirectory, listDirectory, getModificationTime, doesFileExist)
import System.FilePath (takeExtension, (</>), takeFileName)
import Control.Exception (catch, IOException)
import Control.Monad (filterM, void, unless) -- Importamos void y unless explícitamente
import Data.List (sortBy, dropWhileEnd)
import Data.Ord (comparing, Down(..)) -- Importamos Down para el orden descendente
import Data.Time.Clock (UTCTime)
import Data.Char (isSpace)

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

-- ==========================================
-- LÓGICA DE ARCHIVOS
-- ==========================================

trim = dropWhileEnd isSpace . dropWhile isSpace

main :: IO ()
main = do
    home <- getHomeDirectory
    let downloadDir = home </> "Downloads" 
    
    -- Obtener archivos
    files <- catch (listDirectory downloadDir) (\(_ :: IOException) -> return [])
    let fullPaths = map (downloadDir </>) files
    
    -- Filtrar solo archivos existentes
    existingFiles <- filterM doesFileExist fullPaths
    
    -- Obtener tiempos de modificación
    fileData <- mapM (\p -> do
        modTime <- getModificationTime p
        return (p, modTime)) existingFiles
    
    -- ORDENACIÓN CORREGIDA: De más nuevo (Down) a más viejo
    let sortedFiles = map fst $ sortBy (comparing (Down . snd)) fileData
    
    -- Preparar líneas para Rofi
    let menuOptions = map (\p -> 
            let name = takeFileName p
                ext  = takeExtension name
                icon = getIcon ext
            in fmt colorFile icon name) sortedFiles

    -- Ejecutar Rofi
    selection <- rofi "hypr-downloads-main" "Descargas Recientes" menuOptions
    
    unless (null selection) $ do
        let cleanName = extractName selection
        let finalPath = downloadDir </> cleanName
        
        -- ABRIR CORREGIDO: void ya está en scope
        void $ spawnCommand $ "xdg-open \"" ++ finalPath ++ "\""

-- ==========================================
-- HELPERS DE SISTEMA
-- ==========================================

rofi :: String -> String -> [String] -> IO String
rofi menuId prompt options = do
    home <- getHomeDirectory
    let theme = home </> ".config/rofi/themes/modern.rasi"
        helper = home </> ".config/rofi/scripts/frequent-menu.py"
    (exitCode, out, _) <- catch (readProcessWithExitCode helper ["--menu-id", menuId, "--prompt", prompt, "--theme", theme, "--", "-i", "-markup-rows"] (unlines options))
                                (\(_ :: IOException) -> return (ExitFailure 1, "", ""))
    return $ trim out

-- Limpieza de Pango mejorada: buscamos el último '>' para obtener el nombre
extractName :: String -> String
extractName str = trim $ reverse $ takeWhile (/= ' ') $ takeWhile (/= '>') $ reverse str
