module Scripts.TodoList (todoMenu) where

import XMonad
import XMonad.Util.Run (runProcessWithInput)
import Variables (myTheme)

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
    selection <- runProcessWithInput "rofi"
        ["-dmenu", "-p", "TODO:", "-theme", myTheme, "-i"] todoActions
    let res = filter (/= '\n') selection
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
    task <- runProcessWithInput "rofi"
        ["-dmenu", "-p", "Nueva tarea:", "-theme", myTheme] ""
    let res = filter (/= '\n') task
    case res of
        "" -> return ()
        _  -> spawn $ "mkdir -p $(dirname " ++ todoFile ++ ") && "
                   ++ "printf '- [ ] %s\\n' " ++ shellEscape res ++ " >> " ++ todoFile ++ " && "
                   ++ "notify-send '✅ TODO' 'Tarea agregada'"

-- Escapa una cadena para uso seguro en shell
shellEscape :: String -> String
shellEscape s = "'" ++ concatMap esc s ++ "'"
  where esc '\'' = "'\\''"
        esc c    = [c]

-- Marca una tarea como completada: muestra pendientes, el usuario elige una
completeTodo :: X ()
completeTodo = spawn $ "touch " ++ todoFile ++ " && "
    ++ "sel=$(grep '\\- \\[ \\]' " ++ todoFile ++ " | rofi -dmenu -p 'Completar:' -theme " ++ myTheme ++ " -i) && "
    ++ "[ -n \"$sel\" ] && "
    ++ "escaped=$(printf '%s' \"$sel\" | sed 's/[][\\/.*^$&]/\\\\&/g') && "
    ++ "sed -i \"s|$escaped|$(printf '%s' \"$sel\" | sed 's/- \\[ \\]/- [x]/')|\" " ++ todoFile ++ " && "
    ++ "notify-send '🎉 TODO' 'Tarea completada'"

-- Elimina una tarea: muestra todas, el usuario elige cuál borrar
deleteTodo :: X ()
deleteTodo = spawn $ "touch " ++ todoFile ++ " && "
    ++ "sel=$(cat " ++ todoFile ++ " | rofi -dmenu -p 'Eliminar:' -theme " ++ myTheme ++ " -i) && "
    ++ "[ -n \"$sel\" ] && "
    ++ "escaped=$(printf '%s' \"$sel\" | sed 's/[][\\/.*^$&]/\\\\&/g') && "
    ++ "sed -i \"\\|$escaped|d\" " ++ todoFile ++ " && "
    ++ "notify-send '🗑️ TODO' 'Tarea eliminada'"

-- Elimina todas las tareas completadas del archivo
cleanTodos :: X ()
cleanTodos = spawn $ "sed -i '/\\- \\[x\\]/d' " ++ todoFile
    ++ " && notify-send '🧹 TODO' 'Tareas completadas eliminadas'"
