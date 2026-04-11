module Scripts.Productivity.TodoList (todoMenu) where

import XMonad
import XMonad.Util.Run (runProcessWithInput)
import Variables (myTheme, myThemeAbs)
import Scripts.Utils (shellEscape)

todoActions :: String
todoActions = unlines
    [ "Ver tareas pendientes"
    , "Agregar tarea"
    , "Completar tarea"
    , "Eliminar tarea"
    , "Limpiar completadas"
    ]

todoFile :: String
todoFile = "$HOME/.local/share/xmonad-todo.md"

-- Gestor de tareas TODO usando rofi y un archivo markdown simple
todoMenu :: X ()
todoMenu = do
    theme <- myThemeAbs
    selection <- runProcessWithInput "rofi"
        ["-dmenu", "-p", "TODO:", "-theme", theme, "-i"] todoActions
    let res = takeWhile (/= '\n') selection
    case res of
        "Ver tareas pendientes" -> viewTodos
        "Agregar tarea"         -> addTodo
        "Completar tarea"       -> completeTodo
        "Eliminar tarea"        -> deleteTodo
        "Limpiar completadas"   -> cleanTodos
        _                       -> return ()

-- Muestra las tareas pendientes en rofi (solo lectura visual)
viewTodos :: X ()
viewTodos = spawn $ "touch " ++ todoFile ++ " && "
    ++ "cat " ++ todoFile ++ " | rofi -dmenu -p 'Tareas:' -theme " ++ myTheme
    ++ " -i > /dev/null"

-- Agrega una nueva tarea al archivo
addTodo :: X ()
addTodo = do
    theme <- myThemeAbs
    task <- runProcessWithInput "rofi"
        ["-dmenu", "-p", "Nueva tarea:", "-theme", theme] ""
    let res = takeWhile (/= '\n') task
    case res of
        "" -> return ()
        _  -> spawn $ "mkdir -p $(dirname " ++ todoFile ++ ") && "
                   ++ "printf '- [ ] %s\\n' " ++ shellEscape res ++ " >> " ++ todoFile ++ " && "
                   ++ "notify-send '✅ TODO' 'Tarea agregada'"

-- Marca una tarea como completada: muestra pendientes, el usuario elige una
-- Usa grep -nF para obtener el número de línea exacto y sed con dirección de línea,
-- evitando problemas con caracteres especiales y tareas duplicadas.
completeTodo :: X ()
completeTodo = spawn $ "touch " ++ todoFile ++ " && "
    ++ "sel=$(grep -n '\\- \\[ \\]' " ++ todoFile ++ " | rofi -dmenu -p 'Completar:' -theme " ++ myTheme ++ " -i) && "
    ++ "[ -n \"$sel\" ] && "
    ++ "linenum=$(printf '%s' \"$sel\" | cut -d: -f1) && "
    ++ "[ -n \"$linenum\" ] && "
    ++ "sed -i \"${linenum}s/- \\[ \\]/- [x]/\" " ++ todoFile ++ " && "
    ++ "notify-send '🎉 TODO' 'Tarea completada'"

-- Elimina una tarea: muestra todas con número de línea, el usuario elige cuál borrar
deleteTodo :: X ()
deleteTodo = spawn $ "touch " ++ todoFile ++ " && "
    ++ "sel=$(nl -ba -s': ' " ++ todoFile ++ " | rofi -dmenu -p 'Eliminar:' -theme " ++ myTheme ++ " -i) && "
    ++ "[ -n \"$sel\" ] && "
    ++ "linenum=$(printf '%s' \"$sel\" | awk '{print $1}' | tr -d ':') && "
    ++ "[ -n \"$linenum\" ] && "
    ++ "sed -i \"${linenum}d\" " ++ todoFile ++ " && "
    ++ "notify-send '🗑️ TODO' 'Tarea eliminada'"

-- Elimina todas las tareas completadas del archivo
cleanTodos :: X ()
cleanTodos = spawn $ "sed -i '/\\- \\[x\\]/d' " ++ todoFile
    ++ " && notify-send '🧹 TODO' 'Tareas completadas eliminadas'"
