module Scripts.Productivity.TodoList (todoMenu) where

import XMonad
import Scripts.Utils (rofiInput, rofiMenuCommand, rofiSelect, shellEscape)

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
    res <- rofiSelect "xmonad-todo-menu" "TODO:" ["-i"] todoActions
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
    ++ "cat " ++ todoFile ++ " | " ++ rofiMenuCommand "xmonad-todo-view" "Tareas:" ["-i"]
    ++ " > /dev/null"

-- Agrega una nueva tarea al archivo
addTodo :: X ()
addTodo = do
    res <- rofiInput "Nueva tarea:" [] ""
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
    ++ "sel=$(grep -nF '- [ ]' " ++ todoFile ++ " | " ++ rofiMenuCommand "xmonad-todo-complete" "Completar:" ["-i"] ++ ") && "
    ++ "[ -n \"$sel\" ] && "
    ++ "linenum=$(printf '%s' \"$sel\" | cut -d: -f1) && "
    ++ "[ -n \"$linenum\" ] && "
    ++ "sed -i \"${linenum}s/- \\[ \\]/- [x]/\" " ++ todoFile ++ " && "
    ++ "notify-send '🎉 TODO' 'Tarea completada'"

-- Elimina una tarea: muestra todas con número de línea, el usuario elige cuál borrar
deleteTodo :: X ()
deleteTodo = spawn $ "touch " ++ todoFile ++ " && "
    ++ "sel=$(nl -ba -s': ' " ++ todoFile ++ " | " ++ rofiMenuCommand "xmonad-todo-delete" "Eliminar:" ["-i"] ++ ") && "
    ++ "[ -n \"$sel\" ] && "
    ++ "linenum=$(printf '%s' \"$sel\" | awk '{print $1}' | tr -d ':') && "
    ++ "[ -n \"$linenum\" ] && "
    ++ "sed -i \"${linenum}d\" " ++ todoFile ++ " && "
    ++ "notify-send '🗑️ TODO' 'Tarea eliminada'"

-- Elimina todas las tareas completadas del archivo
cleanTodos :: X ()
cleanTodos = spawn $ "sed -i '/\\- \\[x\\]/d' " ++ todoFile
    ++ " && notify-send '🧹 TODO' 'Tareas completadas eliminadas'"
