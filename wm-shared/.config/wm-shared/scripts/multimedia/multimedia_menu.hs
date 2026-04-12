#!/usr/bin/env -S sh -c 'script_dir=$(dirname "$1"); exec runhaskell -i"$script_dir" -i"$script_dir/.." "$1" "$@"' sh
{-# LANGUAGE OverloadedStrings #-}

import System.Process (spawnCommand)
import System.Exit (exitSuccess)
import Data.List (isInfixOf)

import StandaloneUtils (rofiLines)

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
    let options =
            [ iconAudio ++ " Audio"
            , iconBright ++ " Brillo"
            , iconMedia ++ " Medios"
            , iconNight ++ " Modo Nocturno"
            ]
    selection <- rofiLines "hypr-multimedia-main" "Multimedia" ["-i"] options
    case selection of
        _ | "Audio" `isInfixOf` selection   -> audioMenu
        _ | "Brillo" `isInfixOf` selection  -> brightMenu
        _ | "Medios" `isInfixOf` selection  -> mediaMenu
        _ | "Nocturno" `isInfixOf` selection -> nightMenu
        _ -> exitSuccess

audioMenu :: IO ()
audioMenu = do
    let back = iconBack ++ " Volver"
        options = ["Subir Volumen (+5%)", "Bajar Volumen (-5%)", "Mutear/Desmutear", back]
    selection <- rofiLines "hypr-multimedia-audio" "Control de Audio" ["-i"] options
    case selection of
        _ | "+5%" `isInfixOf` selection    -> spawnCommand "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+" >> audioMenu
        _ | "-5%" `isInfixOf` selection    -> spawnCommand "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" >> audioMenu
        _ | "Mutear" `isInfixOf` selection -> spawnCommand "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" >> audioMenu
        _ | "Volver" `isInfixOf` selection -> mainMenu
        _ -> exitSuccess

brightMenu :: IO ()
brightMenu = do
    let back = iconBack ++ " Volver"
        options = ["Brillo +10%", "Brillo -10%", "Máximo", "Mínimo", back]
    selection <- rofiLines "hypr-multimedia-brightness" "Brillo" ["-i"] options
    case selection of
        "Brillo +10%" -> spawnCommand "brightnessctl set +10%" >> brightMenu
        "Brillo -10%" -> spawnCommand "brightnessctl set 10%-" >> brightMenu
        "Máximo"      -> spawnCommand "brightnessctl set 100%" >> brightMenu
        "Mínimo"      -> spawnCommand "brightnessctl set 5%"   >> brightMenu
        _ | "Volver" `isInfixOf` selection -> mainMenu
        _             -> exitSuccess

mediaMenu :: IO ()
mediaMenu = do
    let back = iconBack ++ " Volver"
        options = ["Play/Pause", "Siguiente", "Anterior", back]
    selection <- rofiLines "hypr-multimedia-player" "Reproductor" ["-i"] options
    case selection of
        "Play/Pause" -> spawnCommand "playerctl play-pause" >> mediaMenu
        "Siguiente"  -> spawnCommand "playerctl next" >> mediaMenu
        "Anterior"   -> spawnCommand "playerctl previous" >> mediaMenu
        _ | "Volver" `isInfixOf` selection -> mainMenu
        _            -> exitSuccess

nightMenu :: IO ()
nightMenu = do
    let back = iconBack ++ " Volver"
        options = ["Activar Modo Noche", "Desactivar Modo Noche", back]
    selection <- rofiLines "hypr-multimedia-night" "Luz Nocturna" ["-i"] options
    case selection of
        "Activar Modo Noche"    -> spawnCommand "wlsunset -t 4500 -T 6500" >> exitSuccess
        "Desactivar Modo Noche" -> spawnCommand "pkill wlsunset" >> exitSuccess
        _ | "Volver" `isInfixOf` selection -> mainMenu
        _                       -> exitSuccess
