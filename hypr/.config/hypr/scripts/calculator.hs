#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcessWithExitCode, spawnCommand)
import System.Exit (exitSuccess, ExitCode(..))
import System.Directory (getHomeDirectory)
import Control.Exception (catch, IOException)
import Control.Monad (void, unless)
import Data.Char (isSpace)
import Data.List (dropWhileEnd, isPrefixOf)

-- ==========================================
-- ICONOS (Usando códigos Hex para evitar errores de GHC)
-- ==========================================
icPi   = "\xf03ff"  -- Icono de Pi
icNum  = "\xf039a"  -- Icono de número
icSqrt = "\xf0467"  -- Icono de raíz
icPow  = "\xf0b34"  -- Icono de potencia
icSin  = "\xf06a0"  -- Icono de seno/curva
icCopy = "\xf0c5"   -- Icono de copiar
icCalc = "\xf01ec"  -- Icono de calculadora

-- ==========================================
-- PREDEFINIDOS (Nombre en menú, Expresión Haskell)
-- ==========================================
opciones :: [(String, String)]
opciones = 
    [ (icPi   ++ " Pi (Constante)", "pi")
    , (icNum  ++ " Número E", "exp 1")
    , (icSqrt ++ " Raíz Cuadrada (sqrt)", "PROMPT:sqrt ")
    , (icPow  ++ " Potencia (x^y)", "PROMPT:^")
    , (icSin  ++ " Seno (Radianes)", "PROMPT:sin ")
    , (icSin  ++ " Coseno (Radianes)", "PROMPT:cos ")
    , (icCopy ++ " Copiar último resultado", "ACTION:copy")
    ]

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
notify title msg = void $ spawnCommand $ "notify-send '" ++ title ++ "' '" ++ msg ++ "'"

-- Evalúa usando GHC
evalHaskell :: String -> IO (Either String String)
evalHaskell expr = do
    (exitCode, out, _) <- readProcessWithExitCode "ghc" ["-e", expr] ""
    case exitCode of
        ExitSuccess -> return $ Right (trim out)
        _           -> return $ Left "Error de sintaxis"

-- ==========================================
-- LÓGICA PRINCIPAL
-- ==========================================

main :: IO ()
main = calcLoop ""

calcLoop :: String -> IO ()
calcLoop lastResult = do
    let prompt = if null lastResult then "Haskell Calc" else "Res: " ++ lastResult
    let menuItems = unlines $ map fst opciones
    
    selection <- rofi prompt menuItems
    
    unless (null selection) $ do
        case lookup selection opciones of
            Just val -> handleOption val lastResult
            Nothing  -> executeCalc selection lastResult

handleOption :: String -> String -> IO ()
handleOption val lastResult
    | "ACTION:copy" == val = do
        unless (null lastResult) $ void $ spawnCommand $ "echo -n '" ++ lastResult ++ "' | wl-copy"
        notify "Copiado" "Al portapapeles"
        calcLoop lastResult
    
    | "PROMPT:" `isPrefixOf` val = do
        let func = drop 7 val
        input <- rofi ("Entrada para " ++ func) ""
        unless (null input) $ 
            if func == "^" 
            then executeCalc (lastResult ++ "^" ++ input) lastResult -- Ejemplo para potencias
            else executeCalc (func ++ "(" ++ input ++ ")") lastResult
        calcLoop lastResult

    | otherwise = executeCalc val lastResult 

executeCalc :: String -> String -> IO ()
executeCalc expr oldResult = do
    res <- evalHaskell expr
    case res of
        Left err -> do
            notify "Error" "Expresión no válida"
            calcLoop oldResult
        Right val -> do
            notify "Resultado" val
            calcLoop val
