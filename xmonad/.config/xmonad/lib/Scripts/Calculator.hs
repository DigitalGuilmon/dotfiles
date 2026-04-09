module Scripts.Calculator (calculator) where

import XMonad
import XMonad.Util.Run (runProcessWithInput)
import Variables (myTheme)

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

-- Valida que la expresión solo contenga caracteres seguros para evaluar
isSafeExpr :: String -> Bool
isSafeExpr = all isSafeChar
  where
    isSafeChar c = c `elem` ("0123456789.+-*/() ,eE" :: String)
                || c `elem` ("abcdefghijklmnopqrstuvwxyz" :: String)
