module Scripts.Productivity.Calculator (calculator) where

import XMonad
import XMonad.Util.Run (runProcessWithInput)
import Variables (myTheme)

import Data.Char (isAlpha, isDigit)

-- Calculadora rápida usando rofi y python3 para evaluar expresiones
-- El resultado se muestra con notify-send y se copia al clipboard
calculator :: X ()
calculator = do
    expression <- runProcessWithInput "rofi"
        ["-dmenu", "-p", "Calc:", "-theme", myTheme, "-i",
         "-mesg", "Ejemplos: 2+2 | sqrt(144) | 100*0.15 | 2**10"] ""
    let expr = filter (/= '\n') expression
    case expr of
        "" -> return ()
        _  | isSafeExpr expr -> spawn $ "result=$(python3 -c 'from math import *; print(" ++ expr ++ ")' 2>&1) && "
                    ++ "printf '%s' \"$result\" | xclip -selection clipboard && "
                    ++ "notify-send '🔢 Calculadora' \"" ++ expr ++ " = $result (copiado)\""
           | otherwise -> spawn "notify-send '⚠️ Calculadora' 'Expresión inválida. Solo se permiten números y operaciones matemáticas.'"

-- Funciones matemáticas permitidas de Python math
safeMathFunctions :: [String]
safeMathFunctions =
    [ "sqrt", "sin", "cos", "tan", "asin", "acos", "atan", "atan2"
    , "log", "log2", "log10", "exp", "pow", "abs", "round", "ceil", "floor"
    , "pi", "e", "tau", "inf", "degrees", "radians", "factorial"
    , "hypot", "gcd", "lcm", "trunc", "fmod", "fsum"
    ]

-- Valida que la expresión solo contenga caracteres seguros para evaluar
-- y que las palabras sean funciones matemáticas conocidas
isSafeExpr :: String -> Bool
isSafeExpr s = all isSafeChar s && all (`elem` safeMathFunctions) (extractWords s)
  where
    isSafeChar c = isDigit c || c `elem` (".+-*/() ,eE**" :: String) || isAlpha c
    extractWords [] = []
    extractWords (c:cs)
        | isAlpha c = let (word, rest) = span isAlpha (c:cs)
                      in word : extractWords rest
        | otherwise = extractWords cs
