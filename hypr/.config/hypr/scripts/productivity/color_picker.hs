#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcessWithExitCode, spawnCommand)
import System.Exit (exitSuccess, ExitCode(..))
import System.Directory (getHomeDirectory)
import Control.Exception (catch, IOException)
import Control.Monad (void, unless)
import Data.Char (isSpace, toUpper)
import Data.List (dropWhileEnd)

-- ==========================================
-- ICONOS
-- ==========================================
icPicker  = "\xf0312"
icHex     = "\xf042b"
icRGB     = "\xf012d"
icHSL     = "\xf0536"
icHistory = "\xf018"
icCopy    = "\xf0c5"
icBack    = "\xf006e"

-- ==========================================
-- HELPERS
-- ==========================================

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace

rofi :: String -> String -> IO String
rofi prompt opts = do
    home <- getHomeDirectory
    let theme = home ++ "/.config/rofi/themes/modern.rasi"
    (exitCode, out, _) <- catch (readProcessWithExitCode "rofi" ["-dmenu", "-i", "-p", prompt, "-theme", theme] opts)
                                (\(_ :: IOException) -> return (ExitFailure 1, "", ""))
    return $ trim out

notify :: String -> String -> IO ()
notify title msg = void $ spawnCommand $ "notify-send -u normal -a 'Color Picker' '" ++ title ++ "' '" ++ msg ++ "'"

copyToClipboard :: String -> IO ()
copyToClipboard text = void $ spawnCommand $ "echo -n '" ++ text ++ "' | wl-copy"

-- ==========================================
-- CONVERSIÓN DE COLORES
-- ==========================================

hexToRGB :: String -> (Int, Int, Int)
hexToRGB hex =
    let clean = dropWhile (== '#') hex
        r = readHexPair (take 2 clean)
        g = readHexPair (take 2 (drop 2 clean))
        b = readHexPair (take 2 (drop 4 clean))
    in (r, g, b)

readHexPair :: String -> Int
readHexPair [h, l] = hexDigit h * 16 + hexDigit l
readHexPair _      = 0

hexDigit :: Char -> Int
hexDigit c
    | c >= '0' && c <= '9' = fromEnum c - fromEnum '0'
    | c >= 'a' && c <= 'f' = fromEnum c - fromEnum 'a' + 10
    | c >= 'A' && c <= 'F' = fromEnum c - fromEnum 'A' + 10
    | otherwise             = 0

rgbToHSL :: (Int, Int, Int) -> (Int, Int, Int)
rgbToHSL (r', g', b') =
    let r = fromIntegral r' / 255.0 :: Double
        g = fromIntegral g' / 255.0
        b = fromIntegral b' / 255.0
        mx = maximum [r, g, b]
        mn = minimum [r, g, b]
        l = (mx + mn) / 2.0
        d = mx - mn
        s = if d == 0 then 0
            else if l < 0.5 then d / (mx + mn)
            else d / (2.0 - mx - mn)
        h = if d == 0 then 0
            else if mx == r then (g - b) / d + (if g < b then 6 else 0)
            else if mx == g then (b - r) / d + 2
            else (r - g) / d + 4
    in (round (h * 60), round (s * 100), round (l * 100))

-- ==========================================
-- LÓGICA PRINCIPAL
-- ==========================================

main :: IO ()
main = mainMenu

mainMenu :: IO ()
mainMenu = do
    let options = [ icPicker  ++ " Capturar Color de Pantalla"
                  , icHex     ++ " Introducir Código HEX"
                  ]
    selection <- rofi "Color Picker" (unlines options)
    case () of
        _ | null selection             -> exitSuccess
          | "Capturar" `elem` words selection -> pickFromScreen
          | "HEX" `elem` words selection      -> manualHex
          | otherwise                  -> exitSuccess

pickFromScreen :: IO ()
pickFromScreen = do
    (exitCode, out, _) <- readProcessWithExitCode "hyprpicker" ["-a"] ""
    if exitCode == ExitSuccess
        then do
            let color = map toUpper $ trim out
            unless (null color) $ showColorInfo color
        else notify "Error" "No se pudo iniciar hyprpicker"
    exitSuccess

manualHex :: IO ()
manualHex = do
    input <- rofi "Código HEX (#RRGGBB)" ""
    unless (null input) $ do
        let clean = if head input == '#' then input else '#' : input
        showColorInfo (map toUpper clean)
    exitSuccess

showColorInfo :: String -> IO ()
showColorInfo hex = do
    let clean = dropWhile (== '#') hex
        (r, g, b) = hexToRGB clean
        (h, s, l) = rgbToHSL (r, g, b)
        hexStr = "#" ++ clean
        rgbStr = "rgb(" ++ show r ++ ", " ++ show g ++ ", " ++ show b ++ ")"
        hslStr = "hsl(" ++ show h ++ ", " ++ show s ++ "%, " ++ show l ++ "%)"

    let options = [ icHex  ++ " HEX: " ++ hexStr
                  , icRGB  ++ " RGB: " ++ rgbStr
                  , icHSL  ++ " HSL: " ++ hslStr
                  ]

    selection <- rofi ("Color: " ++ hexStr) (unlines options)
    case () of
        _ | null selection          -> return ()
          | "HEX" `elem` words selection -> copyToClipboard hexStr >> notify "Copiado" hexStr
          | "RGB" `elem` words selection -> copyToClipboard rgbStr >> notify "Copiado" rgbStr
          | "HSL" `elem` words selection -> copyToClipboard hslStr >> notify "Copiado" hslStr
          | otherwise               -> return ()
