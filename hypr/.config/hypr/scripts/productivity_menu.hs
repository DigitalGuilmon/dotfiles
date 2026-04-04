#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcess, spawnCommand, callCommand)
import System.Exit (exitSuccess)
import Data.List (isInfixOf)
import Control.Monad (unless)

-- Configuración estética
theme = "~/.config/rofi/themes/modern.rasi"

-- Iconos (Nerd Fonts)
iconClip    = "󰅌"
iconProject = "󱓞"
iconEmoji   = "󰞅"
iconCalc    = "󰪚"
iconBack    = "󰁮"

main :: IO ()
main = mainMenu

mainMenu :: IO ()
mainMenu = do
    let options = iconClip    ++ " Portapapeles\n" ++ 
                  iconProject ++ " Proyectos\n" ++ 
                  iconEmoji   ++ " Emojis\n" ++ 
                  iconCalc    ++ " Calculadora"
    selection <- rofi "Productividad" options
    case selection of
        _ | "Portapapeles" `isInfixOf` selection -> clipboardMenu
        _ | "Proyectos"    `isInfixOf` selection -> projectsMenu
        _ | "Emojis"       `isInfixOf` selection -> emojiMenu
        _ | "Calculadora"  `isInfixOf` selection -> calcMenu
        _ -> exitSuccess

clipboardMenu :: IO ()
clipboardMenu = do
    -- Requiere cliphist
    spawnCommand "cliphist list | rofi -dmenu -p 'Portapapeles' -theme ~/.config/rofi/themes/modern.rasi | cliphist decode | wl-copy"
    exitSuccess

projectsMenu :: IO ()
projectsMenu = do
    -- Busca carpetas en ~/Projects (ajusta tu ruta si es necesario)
    projects <- readProcess "find" ["/home/" ++ "elsadeveloper" ++ "/Projects", "-maxdepth", "2", "-type", "d", "-printf", "%P\n"] ""
    selection <- rofi "Abrir Proyecto" (projects ++ iconBack ++ " Volver")
    unless (null selection || "Volver" `isInfixOf` selection) $ do
        -- Abre Ghostty y LunarVim en esa ruta
        spawnCommand $ "ghostty --working-directory=~/Projects/" ++ selection ++ " -e lvim"
    if "Volver" `isInfixOf` selection then mainMenu else exitSuccess

emojiMenu :: IO ()
emojiMenu = do
    -- Requiere un archivo simple de emojis o usa un comando directo
    spawnCommand "rofi -show emoji -theme ~/.config/rofi/themes/modern.rasi"
    exitSuccess

calcMenu :: IO ()
calcMenu = do
    input <- rofi "Calculadora (ej: 2+2)" ""
    unless (null input) $ do
        result <- readProcess "bc" ["-l"] <<< input
        spawnCommand $ "notify-send 'Resultado' '" ++ result ++ "'"
        calcMenu -- Re-abrir para más cálculos
    exitSuccess

-- Función auxiliar para rofi
rofi :: String -> String -> IO String
rofi prompt opts = do
    res <- readProcess "rofi" ["-dmenu", "-i", "-p", prompt, "-theme", theme] opts
    return $ if null res then "" else init res

-- Operador para pasar entrada a procesos
(<<<) :: (String -> [String] -> String -> IO a) -> String -> IO a
f <<< input = f "bc" ["-l"] input
