module Scripts.Productivity.Calculator (calculator) where

import XMonad
import XMonad.Util.Run (runProcessWithInput)
import Variables (myThemeAbs)

import Data.Char (isLower, isDigit)

-- Calculadora rápida usando rofi y python3 para evaluar expresiones
-- El resultado se muestra con notify-send y se copia al clipboard
calculator :: X ()
calculator = do
    theme <- myThemeAbs
    expression <- runProcessWithInput "rofi"
        ["-dmenu", "-p", "Calc:", "-theme", theme, "-i",
         "-mesg", "Ejemplos: 2+2 | sqrt(144) | 100*0.15 | 2**10"] ""
    let expr = filter (/= '\n') expression
    case expr of
        "" -> return ()
        _  | isSafeExpr expr -> spawn $ "errfile=$(mktemp /tmp/calc_err.XXXXXX) && "
                    ++ "{ result=$(python3 -c 'from math import *; print(" ++ expr ++ ")' 2>\"$errfile\") && "
                    ++ "printf '%s' \"$result\" | xclip -selection clipboard && "
                    ++ "notify-send '🔢 Calculadora' \"" ++ expr ++ " = $result (copiado)\" && rm -f \"$errfile\"; } || "
                    ++ "{ notify-send '⚠️ Calculadora' \"Error: $(cat \"$errfile\")\"; rm -f \"$errfile\"; }"
           | otherwise -> spawn "notify-send '⚠️ Calculadora' 'Expresión inválida. Solo se permiten números y operaciones matemáticas.'"

-- Funciones y constantes matemáticas permitidas de Python math
safeMathFunctions :: [String]
safeMathFunctions =
    [ "sqrt", "sin", "cos", "tan", "asin", "acos", "atan", "atan2"
    , "log", "log2", "log10", "exp", "pow", "abs", "round", "ceil", "floor"
    , "pi", "e", "tau", "inf", "degrees", "radians", "factorial"
    , "hypot", "gcd", "lcm", "trunc", "fmod", "fsum"
    ]

-- Valida que la expresión solo contenga caracteres seguros para evaluar
-- y que las palabras alfabéticas sean funciones matemáticas conocidas.
-- Solo letras minúsculas son permitidas como identificadores (e, pi, sqrt, etc.).
-- Notación científica usa 'e' minúscula (ej: 1e5).
isSafeExpr :: String -> Bool
isSafeExpr s = all isSafeChar s && all (`elem` safeMathFunctions) (extractWords s)
  where
    isSafeChar c = isDigit c || c `elem` (".+-*/() ," :: String) || isLower c
    extractWords [] = []
    extractWords (c:cs)
        | isLower c = let (word, rest) = span isLower (c:cs)
                      in word : extractWords rest
        | otherwise = extractWords cs
