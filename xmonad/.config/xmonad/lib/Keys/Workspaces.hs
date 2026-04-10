module Keys.Workspaces where

import XMonad
import qualified XMonad.StackSet as W
import XMonad.Actions.CycleWS (nextWS, prevWS, shiftToNext, shiftToPrev)

import Variables (myWorkspaces)

workspaceKeys :: [(String, X ())]
workspaceKeys =
    [ ("M-<Right>",    nextWS)                -- Siguiente workspace
    , ("M-<Left>",     prevWS)                -- Anterior workspace
    , ("M-S-<Right>",  shiftToNext >> nextWS) -- Mover ventana al siguiente workspace y seguir
    , ("M-S-<Left>",   shiftToPrev >> prevWS) -- Mover ventana al anterior workspace y seguir
    ]
    ++
    -- M-[1..9, 0]: Cambiar al espacio | M-S-[1..9, 0]: Mover ventana al espacio
    [ ("M-" ++ m ++ k, windows $ f w) 
    | (k, w) <- zip (map show ([1..9] :: [Int]) ++ ["0"]) myWorkspaces
    , (m, f) <- [("", W.greedyView), ("S-", W.shift)]
    ]
