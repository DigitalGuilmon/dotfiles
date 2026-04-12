#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcessWithExitCode)
import System.Exit (exitSuccess, ExitCode(..))
import System.Directory (getHomeDirectory)
import Control.Exception (catch, IOException)
import Data.Char (isSpace)
import Data.List (dropWhileEnd, isPrefixOf, isInfixOf, intercalate)

-- ==========================================
-- HELPERS
-- ==========================================

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace

rofi :: String -> String -> String -> IO String
rofi menuId prompt opts = do
    home <- getHomeDirectory
    let theme = home ++ "/.config/rofi/themes/modern.rasi"
        helper = home ++ "/.config/rofi/scripts/frequent-menu.py"
    (exitCode, out, _) <- catch (readProcessWithExitCode helper
        ["--menu-id", menuId, "--prompt", prompt, "--theme", theme, "--", "-i", "-markup-rows"] opts)
        (\(_ :: IOException) -> return (ExitFailure 1, "", ""))
    return $ trim out

-- ==========================================
-- PARSER DE KEYBINDS
-- ==========================================

data Keybind = Keybind
    { kbMods   :: String
    , kbKey    :: String
    , kbAction :: String
    , kbArgs   :: String
    } deriving (Show)

parseKeybind :: String -> Maybe Keybind
parseKeybind line
    | any (`isPrefixOf` stripped) ["bind", "binde", "bindl", "bindle", "bindm"] =
        let afterEq = drop 1 $ dropWhile (/= '=') stripped
            parts = map trim $ splitOn ',' afterEq
        in case parts of
            (mods:key:action:rest) -> Just $ Keybind
                { kbMods   = mods
                , kbKey    = key
                , kbAction = action
                , kbArgs   = intercalate ", " rest
                }
            _ -> Nothing
    | otherwise = Nothing
  where
    stripped = trim line

splitOn :: Char -> String -> [String]
splitOn _ [] = [""]
splitOn sep str =
    let (before, rest) = break (== sep) str
    in before : case rest of
        []     -> []
        (_:xs) -> splitOn sep xs

-- ==========================================
-- FORMATO PARA ROFI
-- ==========================================

formatKeybind :: Keybind -> String
formatKeybind kb =
    let mods = kbMods kb
        key  = kbKey kb
        action = kbAction kb
        args = kbArgs kb
        modStr = case mods of
            ""  -> ""
            _   -> formatMods mods ++ " + "
        keyStr = formatKey key
        descStr = formatAction action args
    in "<b>" ++ modStr ++ keyStr ++ "</b>  →  " ++ descStr

formatMods :: String -> String
formatMods mods
    | "$mainMod ALT"       `isPrefixOf` mods = "Super + Alt"
    | "$mainMod CTRL SHIFT" `isPrefixOf` mods = "Super + Ctrl + Shift"
    | "$mainMod CTRL"      `isPrefixOf` mods = "Super + Ctrl"
    | "$mainMod SHIFT"     `isPrefixOf` mods = "Super + Shift"
    | "$mainMod"           `isPrefixOf` mods = "Super"
    | otherwise = mods

formatKey :: String -> String
formatKey "Return" = "↵ Enter"
formatKey "Space"  = "␣ Space"
formatKey "Tab"    = "⇥ Tab"
formatKey k
    | "XF86Audio"  `isPrefixOf` k = "🔊 " ++ drop 5 k
    | "XF86Mon"    `isPrefixOf` k = "🔆 " ++ drop 5 k
    | "mouse:"     `isPrefixOf` k = "🖱️ " ++ k
    | otherwise = k

formatAction :: String -> String -> String
formatAction "exec" args
    | "ai_menu"           `isInfixOf` args = "🤖 Menú AI"
    | "system_utils"      `isInfixOf` args = "🛠️ Utilidades del Sistema"
    | "multimedia_menu"   `isInfixOf` args = "🎵 Menú Multimedia"
    | "network_menu"      `isInfixOf` args = "🌐 Menú de Red"
    | "screenshot"        `isInfixOf` args = "📸 Captura de Pantalla"
    | "wallpaper"         `isInfixOf` args = "🎨 Cambiar Wallpaper"
    | "volume"            `isInfixOf` args = "🔊 Control de Volumen"
    | "steam_menu"        `isInfixOf` args = "🎮 Menú Steam"
    | "docker"            `isInfixOf` args = "🐳 Docker Manager"
    | "calculator"        `isInfixOf` args = "🔢 Calculadora"
    | "english"           `isInfixOf` args = "📖 English Tutor"
    | "productivity_menu" `isInfixOf` args = "📋 Menú Productividad"
    | "color_picker"      `isInfixOf` args = "🎨 Color Picker"
    | "todo"              `isInfixOf` args = "✅ Lista TODO"
    | "keybind_cheatsheet" `isInfixOf` args = "⌨️ Cheatsheet"
    | "window_manager"    `isInfixOf` args = "🪟 Gestor de Ventanas"
    | "web_menu"          `isInfixOf` args = "🌍 Menú Web"
    | "prompt"            `isInfixOf` args = "📝 Prompts IA"
    | "download"          `isInfixOf` args = "📥 Descargas"
    | "ghostty"           `isInfixOf` args = "💻 Terminal"
    | "brave"             `isInfixOf` args = "🦁 Navegador"
    | "lvim"              `isInfixOf` args = "📝 Editor (LunarVim)"
    | "rofi"              `isInfixOf` args = "🔍 Lanzador (Rofi)"
    | "youtube"           `isInfixOf` args = "📺 YouTube"
    | "hyprctl reload"    `isInfixOf` args = "🔄 Recargar Config"
    | "waybar"            `isInfixOf` args = "📊 Reiniciar Waybar"
    | "wlogout"           `isInfixOf` args = "🚪 Menú de Sesión"
    | "swaync"            `isInfixOf` args = "🔔 Notificaciones"
    | "brightnessctl"     `isInfixOf` args = "🔆 Brillo"
    | "wpctl"             `isInfixOf` args = "🔊 Audio"
    | otherwise = args
formatAction "killactive"    _ = "❌ Cerrar Ventana"
formatAction "fullscreen"    _ = "🖥️ Pantalla Completa"
formatAction "togglefloating" _ = "🔀 Toggle Flotante"
formatAction "centerwindow"  _ = "🎯 Centrar Ventana"
formatAction "workspace"     a = "📂 Workspace " ++ a
formatAction "movetoworkspace" a = "➡️ Mover a Workspace " ++ a
formatAction "movefocus"     a = "👁️ Foco → " ++ formatDir a
formatAction "movewindow"    a = "🪟 Mover → " ++ formatDir a
formatAction "resizeactive"  a = "↔️ Redimensionar " ++ a
formatAction "pin"           _ = "📌 Anclar Ventana"
formatAction "exit"          _ = "⚠️ Salir de Hyprland"
formatAction action args = action ++ " " ++ args

formatDir :: String -> String
formatDir "l" = "⬅️ Izquierda"
formatDir "r" = "➡️ Derecha"
formatDir "u" = "⬆️ Arriba"
formatDir "d" = "⬇️ Abajo"
formatDir d   = d

-- ==========================================
-- LÓGICA PRINCIPAL
-- ==========================================

main :: IO ()
main = do
    home <- getHomeDirectory
    let keybindsPath = home ++ "/.config/hypr/conf/keybinds.conf"
    
    content <- catch (readFile keybindsPath) (\(_ :: IOException) -> return "")
    
    if null content
        then do
            _ <- rofi "hypr-keybind-cheatsheet-error" "Error" "No se pudo leer keybinds.conf"
            exitSuccess
        else do
            let ls = lines content
                binds = concatMap (\l -> case parseKeybind l of
                    Just kb -> [kb]
                    Nothing -> []) ls
                formatted = map formatKeybind binds
            
            _ <- rofi "hypr-keybind-cheatsheet-main" "⌨️ Keybindings Hyprland" (unlines formatted)
            exitSuccess
