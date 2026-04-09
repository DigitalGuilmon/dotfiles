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
        _  -> spawn $ "result=$(python3 -c 'from math import *; print(" ++ expr ++ ")' 2>&1) && "
                    ++ "printf '%s' \"$result\" | xclip -selection clipboard && "
                    ++ "notify-send '🔢 Calculadora' \"" ++ expr ++ " = $result (copiado)\""
