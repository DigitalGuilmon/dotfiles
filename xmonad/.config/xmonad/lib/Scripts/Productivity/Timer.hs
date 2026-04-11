module Scripts.Productivity.Timer (timerMenu) where

import XMonad
import XMonad.Util.Run (runProcessWithInput)
import Variables (myThemeAbs)

timerOptions :: String
timerOptions = unlines
    [ "Pomodoro (25 min)"
    , "Descanso corto (5 min)"
    , "Descanso largo (15 min)"
    , "Timer 10 min"
    , "Timer 45 min"
    , "Timer 60 min"
    , "Personalizado"
    ]

-- Menú de temporizadores Pomodoro usando rofi
-- Usa notify-send al terminar y un sonido de alerta con paplay
timerMenu :: X ()
timerMenu = do
    theme <- myThemeAbs
    selection <- runProcessWithInput "rofi"
        ["-dmenu", "-p", "Timer:", "-theme", theme, "-i"] timerOptions
    let res = filter (/= '\n') selection
    case res of
        "Pomodoro (25 min)"     -> startTimer 25 "Pomodoro"
        "Descanso corto (5 min)"-> startTimer 5  "Descanso corto"
        "Descanso largo (15 min)"-> startTimer 15 "Descanso largo"
        "Timer 10 min"          -> startTimer 10 "Timer"
        "Timer 45 min"          -> startTimer 45 "Timer"
        "Timer 60 min"          -> startTimer 60 "Timer"
        "Personalizado"         -> customTimer
        _                       -> return ()

-- Inicia un timer de N minutos con notificación al finalizar
startTimer :: Int -> String -> X ()
startTimer minutes label = do
    let secs = show (minutes * 60)
    spawn $ "notify-send '⏱️ " ++ label ++ "' '" ++ show minutes ++ " minutos iniciados' && "
         ++ "(sleep " ++ secs ++ " && notify-send -u critical '🔔 " ++ label ++ "' '¡Tiempo terminado! (" ++ show minutes ++ " min)' "
         ++ "&& (paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga 2>/dev/null "
         ++ "|| notify-send '🔇 Timer' 'No se pudo reproducir sonido de alarma')) &"

-- Pide al usuario un número de minutos personalizado via rofi
customTimer :: X ()
customTimer = do
    theme <- myThemeAbs
    input <- runProcessWithInput "rofi"
        ["-dmenu", "-p", "Minutos:", "-theme", theme] ""
    let res = filter (/= '\n') input
    case reads res :: [(Int, String)] of
        [(mins, "")] | mins > 0 -> startTimer mins "Timer personalizado"
        _            -> spawn "notify-send '⚠️ Timer' 'Entrada inválida. Usa un número entero positivo.'"
