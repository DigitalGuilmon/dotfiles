module Keys.Windows where

import XMonad
import qualified XMonad.StackSet as W
import XMonad.Layout.MultiToggle (Toggle(..))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL))

import Scripts.System.LayoutMenu (layoutMenu)
import Scripts.System.WindowControls (sinkWindow, sinkAll)

windowKeys :: [(String, X ())]
windowKeys =
    -- Foco y posición
    [ ("M-j",          windows W.focusDown)       -- Mover foco a la siguiente ventana
    , ("M-k",          windows W.focusUp)         -- Mover foco a la ventana anterior
    , ("M-m",          windows W.focusMaster)     -- Mover foco a la ventana maestra
    , ("M-S-j",        windows W.swapDown)        -- Intercambiar posición con la ventana siguiente
    , ("M-S-k",        windows W.swapUp)          -- Intercambiar posición con la ventana anterior
    , ("M-S-<Return>", windows W.swapMaster)      -- Intercambiar ventana enfocada con la maestra
    , ("M-f",          sendMessage $ Toggle NBFULL) -- Alternar pantalla completa
    , ("M-h",          sendMessage Shrink)        -- Encoger área maestra
    , ("M-l",          sendMessage Expand)        -- Expandir área maestra
    , ("M-,",          sendMessage (IncMasterN 1))    -- Incrementar ventanas en área maestra
    , ("M-.",          sendMessage (IncMasterN (-1)))  -- Decrementar ventanas en área maestra
    , ("M-n",          refresh)                   -- Corregir tamaño de ventanas
    , ("M-t",          sinkWindow)                -- Hundir ventana enfocada (quitar float)
    , ("M-S-t",        sinkAll)                   -- Hundir todas las ventanas flotantes
    -- Navegación de layouts
    , ("M-u",          layoutMenu)                -- Menú Rofi para cambiar layout
    , ("M-<Space>",    sendMessage NextLayout)    -- Siguiente layout
    , ("M-S-<Space>",  sendMessage FirstLayout)   -- Resetear al primer layout
    ]
