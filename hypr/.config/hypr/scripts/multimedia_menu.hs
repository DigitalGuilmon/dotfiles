#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcess, spawnCommand)
import System.Exit (exitSuccess)
import Data.List (isInfixOf)

-- Configuración estética
theme = "~/.config/rofi/themes/modern.rasi"

-- Iconos (Nerd Fonts)
iconAudio  = "\xf04c3"
iconBright = "\xf00e0"
iconMedia  = "\xf075a"
iconNight  = "\xf0594"
iconBack   = "\xf006e"

main :: IO ()
main = mainMenu

mainMenu :: IO ()
mainMenu = do
    let options = iconAudio ++ " Audio\n" ++ 
                  iconBright ++ " Brillo\n" ++ 
                  iconMedia ++ " Medios\n" ++ 
                  iconNight ++ " Modo Nocturno"
    selection <- rofi "Multimedia" options
    case selection of
        _ | "Audio" `isInfixOf` selection   -> audioMenu
        _ | "Brillo" `isInfixOf` selection  -> brightMenu
        _ | "Medios" `isInfixOf` selection  -> mediaMenu
        _ | "Nocturno" `isInfixOf` selection -> nightMenu
        _ -> exitSuccess

audioMenu :: IO ()
audioMenu = do
    let options = "Subir Volumen (+5%)\nBajar Volumen (-5%)\nMutear/Desmutear\n" ++ iconBack ++ " Volver"
    selection <- rofi "Control de Audio" options
    case selection of
        _ | "+5%" `isInfixOf` selection    -> spawnCommand "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+" >> audioMenu
        _ | "-5%" `isInfixOf` selection    -> spawnCommand "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" >> audioMenu
        _ | "Mutear" `isInfixOf` selection -> spawnCommand "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" >> audioMenu
        _ | "Volver" `isInfixOf` selection -> mainMenu
        _ -> exitSuccess

brightMenu :: IO ()
brightMenu = do
    let options = "Brillo +10%\nBrillo -10%\nMáximo\nMínimo\n" ++ iconBack ++ " Volver"
    selection <- rofi "Brillo" options
    case selection of
        "Brillo +10%" -> spawnCommand "brightnessctl set +10%" >> brightMenu
        "Brillo -10%" -> spawnCommand "brightnessctl set 10%-" >> brightMenu
        "Máximo"      -> spawnCommand "brightnessctl set 100%" >> brightMenu
        "Mínimo"      -> spawnCommand "brightnessctl set 5%"   >> brightMenu
        "Volver"      -> mainMenu
        _             -> exitSuccess

mediaMenu :: IO ()
mediaMenu = do
    let options = "Play/Pause\nSiguiente\nAnterior\n" ++ iconBack ++ " Volver"
    selection <- rofi "Reproductor" options
    case selection of
        "Play/Pause" -> spawnCommand "playerctl play-pause" >> mediaMenu
        "Siguiente"  -> spawnCommand "playerctl next" >> mediaMenu
        "Anterior"   -> spawnCommand "playerctl previous" >> mediaMenu
        "Volver"     -> mainMenu
        _            -> exitSuccess

nightMenu :: IO ()
nightMenu = do
    let options = "Activar Modo Noche\nDesactivar Modo Noche\n" ++ iconBack ++ " Volver"
    selection <- rofi "Luz Nocturna" options
    case selection of
        "Activar Modo Noche"    -> spawnCommand "wlsunset -t 4500 -T 6500" >> exitSuccess
        "Desactivar Modo Noche" -> spawnCommand "pkill wlsunset" >> exitSuccess
        "Volver"                -> mainMenu
        _                       -> exitSuccess

rofi :: String -> String -> IO String
rofi prompt opts = do
    res <- readProcess "rofi" ["-dmenu", "-i", "-p", prompt, "-theme", theme] opts
    return $ if null res then "" else init res
