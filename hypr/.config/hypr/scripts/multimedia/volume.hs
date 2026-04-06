#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcess, spawnCommand)
import System.Environment (getArgs)
import Control.Monad (void)
import Data.List (isInfixOf)
import Text.Printf (printf)
import Data.Char (isDigit)

-- Identificador para sincronizar notificaciones (estilo macOS)
syncId :: String
syncId = "string:x-canonical-private-synchronous:sys-notify"

main :: IO ()
main = do
    args <- getArgs
    case args of
        ["up"]   -> changeVolume "5%+"
        ["down"] -> changeVolume "5%-"
        ["mute"] -> toggleMute
        _        -> putStrLn "Uso: volume.hs [up|down|mute]"

changeVolume :: String -> IO ()
changeVolume delta = do
    -- El flag -l 1.0 evita distorsión al no pasar del 100%
    void $ readProcess "wpctl" ["set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", delta] ""
    notifyVolume

toggleMute :: IO ()
toggleMute = do
    void $ spawnCommand "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    notifyVolume

notifyVolume :: IO ()
notifyVolume = do
    status <- readProcess "wpctl" ["get-volume", "@DEFAULT_AUDIO_SINK@"] ""
    let isMuted = "[MUTED]" `isInfixOf` status
    -- Extraer solo números y punto decimal
    let volStr = filter (\c -> isDigit c || c == '.') status
    let volPercent = case reads volStr :: [(Double, String)] of
            [(v, _)] -> round (v * 100) :: Int
            _        -> 0
    
    let (icon, label) = getIconAndLabel isMuted volPercent
    -- Forzamos a que printf devuelva un String explícito para evitar errores de scope
    let notifyCmd = printf "notify-send -e -h %s -h int:value:%d -i %s '%s' '%d%%'" 
                           syncId volPercent icon label volPercent :: String
    
    void $ spawnCommand notifyCmd

-- Lógica de iconos separada para mayor claridad (estilo Clean Code)
getIconAndLabel :: Bool -> Int -> (String, String)
getIconAndLabel True _ = ("audio-volume-muted", "Silencio")
getIconAndLabel _ 0    = ("audio-volume-muted", "Silencio")
getIconAndLabel _ v
    | v < 33    = ("audio-volume-low", "Volumen")
    | v < 66    = ("audio-volume-medium", "Volumen")
    | otherwise = ("audio-volume-high", "Volumen")
