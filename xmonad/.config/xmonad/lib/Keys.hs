module Keys where

import XMonad
import XMonad.Util.NamedScratchpad (namedScratchpadAction)
import qualified XMonad.StackSet as W
import XMonad.Layout.MultiToggle (Toggle(..))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL))

-- Importación de tus variables y módulos locales
import Variables (myTerminal, myTheme, myWorkspaces)
import Scratchpads (myScratchpads)
-- Importamos la función desde el nuevo módulo que crearemos
import Scripts.Screenshot (screenshot)

myKeys :: [(String, X ())]
myKeys = 
    -- --- SISTEMA Y CONTROL ---
    [ ("M-q",          spawn "xmonad --recompile; xmonad --restart") -- Recompilar y reiniciar
    , ("M-x",          kill)                                        -- Cerrar ventana activa
    , ("M-<Escape>",   withWindowSet $ \s -> mapM_ killWindow (W.allWindows s)) -- Cerrar todas las ventanas
    
    -- --- LANZADORES DE APLICACIONES ---
    , ("M-<Return>",   spawn myTerminal)                            -- Abrir terminal (Ghostty)
    , ("M-v",          spawn (myTerminal ++ " -e lvim"))            -- Abrir LunarVim
    , ("M-d",          spawn ("rofi -show drun -show-icons -theme " ++ myTheme)) -- Menú de aplicaciones
    , ("M-<Tab>",      spawn ("rofi -show window -show-icons -theme " ++ myTheme)) -- Selector de ventanas
    , ("M-s",          namedScratchpadAction myScratchpads "terminal") -- Terminal flotante
    
    -- --- UTILIDADES (Haskell Script) ---
    , ("M-p",          screenshot)                                  -- Captura de pantalla (Lógica en Haskell)
    
    -- --- GESTIÓN DE VENTANAS (Foco y Layout) ---
    , ("M-j",          windows W.focusDown)    -- Mover foco a la siguiente ventana
    , ("M-k",          windows W.focusUp)      -- Mover foco a la ventana anterior
    , ("M-S-j",        windows W.swapDown)     -- Intercambiar posición con la ventana siguiente
    , ("M-S-k",        windows W.swapUp)       -- Intercambiar posición con la ventana anterior
    , ("M-f",          sendMessage $ Toggle NBFULL) -- Alternar pantalla completa
    , ("M-h",          sendMessage Shrink)     -- Encoger área maestra
    , ("M-l",          sendMessage Expand)     -- Expandir área maestra
    , ("M-n",          refresh)                -- Corregir tamaño de ventanas
    ]
    ++
    -- --- WORKSPACES (Atajos dinámicos) ---
    -- M-[1..9, 0]: Cambiar al espacio | M-S-[1..9, 0]: Mover ventana al espacio
    [ ("M-" ++ m ++ k, windows $ f w) 
    | (k, w) <- zip (map show ([1..9] :: [Int]) ++ ["0"]) myWorkspaces
    , (m, f) <- [("", W.greedyView), ("S-", W.shift)]
    ]
