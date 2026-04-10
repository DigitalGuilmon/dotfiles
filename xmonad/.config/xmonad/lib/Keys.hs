module Keys where

import XMonad
import XMonad.Util.NamedScratchpad (namedScratchpadAction)
import qualified XMonad.StackSet as W
import XMonad.Layout.MultiToggle (Toggle(..))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL))
import XMonad.Actions.CycleWS (nextWS, prevWS, shiftToNext, shiftToPrev)

-- Importación de tus variables y módulos locales
import Variables (myTerminal, myTheme, myWorkspaces)
import Scratchpads (myScratchpads)
import Scripts.Screenshot (screenshot)

-- Importaciones de tus módulos extra y prompts
import Scripts.GridMenu (gridGoToWindow)
import Scripts.WindowControls (sinkWindow, sinkAll)
import Scripts.Prompts (searchGoogle, searchYouTube, searchMan, runShell)
import Scripts.PowerMenu (powerMenu)
import Scripts.Monitors (monitorMenu)
import Scripts.Wallpaper (changeWallpaper)

-- Nuevos scripts de productividad
import Scripts.QuickApps (quickApps)
import Scripts.Clipboard (clipboardMenu, clipboardClear)
import Scripts.ProjectManager (projectMenu)
import Scripts.AudioControl (audioMenu)
import Scripts.NetworkMenu (networkMenu)
import Scripts.Bookmarks (bookmarkMenu)
import Scripts.NotificationCenter (notificationMenu)
import Scripts.DevTools (devMenu)

-- Scripts de productividad con Rofi
import Scripts.EmojiPicker (emojiPicker)
import Scripts.Calculator (calculator)
import Scripts.Timer (timerMenu)
import Scripts.TodoList (todoMenu)
import Scripts.SystemInfo (systemInfo)

myKeys :: [(String, X ())]
myKeys = 
    -- --- SISTEMA Y CONTROL ---
    [ ("M-q",          spawn "xmonad --recompile && xmonad --restart") -- Recompilar y reiniciar
    , ("M-S-q",        powerMenu)                                   -- Menú de Energía (Apagar, Reiniciar...)
    , ("M-S-m",        monitorMenu)                                 -- Menú de configuración de Monitores
    , ("M-x",          kill)                                        -- Cerrar ventana activa
    , ("M-<Escape>",   withWindowSet $ \s -> mapM_ killWindow (W.allWindows s)) -- Cerrar todas las ventanas
    
    -- --- LANZADORES DE APLICACIONES ---
    , ("M-<Return>",   spawn myTerminal)                            -- Abrir terminal (Ghostty)
    , ("M-v",          spawn (myTerminal ++ " -e lvim"))            -- Abrir LunarVim
    , ("M-d",          spawn ("rofi -show drun -show-icons -theme " ++ myTheme)) -- Menú de aplicaciones
    , ("M-<Tab>",      spawn ("rofi -show window -show-icons -theme " ++ myTheme)) -- Selector de ventanas
    , ("M-a",          quickApps)                                   -- Lanzador rápido de apps por categoría
    
    -- --- SCRATCHPADS (ventanas flotantes toggle) ---
    , ("M-s",          namedScratchpadAction myScratchpads "terminal")    -- Terminal flotante
    , ("M-S-s",        namedScratchpadAction myScratchpads "vscode")      -- VS Code flotante
    , ("M-S-f",        namedScratchpadAction myScratchpads "filemanager") -- Thunar flotante
    , ("M-S-b",        namedScratchpadAction myScratchpads "btop")        -- Monitor de sistema flotante
    , ("M-S-n",        namedScratchpadAction myScratchpads "notes")       -- Notas rápidas flotante
    
    -- --- UTILIDADES (Haskell Scripts) ---
    , ("M-p",          screenshot)                                  -- Captura de pantalla
    , ("M-w",          changeWallpaper)                             -- Cambiar a un fondo de Anime aleatorio
    , ("M-c",          clipboardMenu)                               -- Historial del clipboard
    , ("M-S-c",        clipboardClear)                              -- Limpiar historial del clipboard
    
    -- --- PRODUCTIVIDAD ---
    , ("M-o",          projectMenu)                                 -- Saltar a un proyecto (terminal + editor)
    , ("M-b",          bookmarkMenu)                                -- Abrir bookmarks favoritos
    , ("M-S-d",        devMenu)                                     -- Herramientas de desarrollo (Docker, Git, Tmux...)
    
    -- --- PRODUCTIVIDAD CON ROFI ---
    , ("M-e",          emojiPicker)                                  -- Selector de emojis (copia al clipboard)
    , ("M-r",          calculator)                                   -- Calculadora rápida con Rofi
    , ("M-y",          timerMenu)                                    -- Temporizador Pomodoro con Rofi
    , ("M-z",          todoMenu)                                     -- Gestor de tareas TODO con Rofi
    , ("M-i",          systemInfo)                                   -- Info del sistema con Rofi
    
    -- --- BÚSQUEDAS Y MENÚS EXTRA (Prompts) ---
    , ("M-g",          gridGoToWindow)             -- Lanzar Grid visual de ventanas
    , ("M-S-g",        searchGoogle)               -- Buscar en Google
    , ("M-S-y",        searchYouTube)              -- Buscar en YouTube
    , ("M-S-h",        searchMan)                  -- Buscar manuales de terminal (Man Pages)
    , ("M-S-r",        runShell)                   -- Ejecutar comando rápido (Shell Prompt)
    
    -- --- SISTEMA Y CONTROL AVANZADO ---
    , ("M-S-a",        audioMenu)                                   -- Control de audio (volumen, salida, mic)
    , ("M-S-w",        networkMenu)                                 -- Gestión de red (WiFi, VPN)
    , ("M-S-x",        notificationMenu)                            -- Control de notificaciones (DND, limpiar)
    
    -- --- GESTIÓN DE VENTANAS (Foco, Layout y Flotantes) ---
    , ("M-j",          windows W.focusDown)    -- Mover foco a la siguiente ventana
    , ("M-k",          windows W.focusUp)      -- Mover foco a la ventana anterior
    , ("M-m",          windows W.focusMaster)  -- Mover foco a la ventana maestra
    , ("M-S-j",        windows W.swapDown)     -- Intercambiar posición con la ventana siguiente
    , ("M-S-k",        windows W.swapUp)       -- Intercambiar posición con la ventana anterior
    , ("M-S-<Return>", windows W.swapMaster)   -- Intercambiar ventana enfocada con la maestra
    , ("M-f",          sendMessage $ Toggle NBFULL) -- Alternar pantalla completa
    , ("M-h",          sendMessage Shrink)     -- Encoger área maestra
    , ("M-l",          sendMessage Expand)     -- Expandir área maestra
    , ("M-,",          sendMessage (IncMasterN 1))    -- Incrementar ventanas en área maestra
    , ("M-.",          sendMessage (IncMasterN (-1)))  -- Decrementar ventanas en área maestra
    , ("M-n",          refresh)                -- Corregir tamaño de ventanas
    , ("M-t",          sinkWindow)             -- Hundir ventana enfocada (quitar float)
    , ("M-S-t",        sinkAll)                -- Hundir todas las ventanas flotantes

    -- --- NAVEGACIÓN DE LAYOUTS ---
    , ("M-<Space>",    sendMessage NextLayout)   -- Siguiente layout
    , ("M-S-<Space>",  sendMessage FirstLayout)  -- Resetear al primer layout

    -- --- NAVEGACIÓN DE WORKSPACES ---
    , ("M-<Right>",    nextWS)                        -- Siguiente workspace
    , ("M-<Left>",     prevWS)                        -- Anterior workspace
    , ("M-S-<Right>",  shiftToNext >> nextWS)         -- Mover ventana al siguiente workspace y seguir
    , ("M-S-<Left>",   shiftToPrev >> prevWS)         -- Mover ventana al anterior workspace y seguir
    
    -- --- TECLAS MULTIMEDIA Y BRILLO ---
    , ("<XF86AudioRaiseVolume>", spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")
    , ("<XF86AudioLowerVolume>", spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
    , ("<XF86AudioMute>",        spawn "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
    , ("<XF86MonBrightnessUp>",  spawn "brightnessctl set +5%")
    , ("<XF86MonBrightnessDown>",spawn "brightnessctl set 5%-")
    ]
    ++
    -- --- WORKSPACES (Atajos dinámicos) ---
    -- M-[1..9, 0]: Cambiar al espacio | M-S-[1..9, 0]: Mover ventana al espacio
    [ ("M-" ++ m ++ k, windows $ f w) 
    | (k, w) <- zip (map show ([1..9] :: [Int]) ++ ["0"]) myWorkspaces
    , (m, f) <- [("", W.greedyView), ("S-", W.shift)]
    ]
