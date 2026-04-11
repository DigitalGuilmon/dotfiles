module Keys.Workspaces where

import XMonad
import qualified XMonad.StackSet as W
import XMonad.Actions.CycleWS (nextWS, prevWS, shiftToNext, shiftToPrev)

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
    | (k, w) <- zip (map show ([1..9] :: [Int]) ++ ["0"])
                     ["1:dev", "2:web", "3:term", "4:db", "5:api", "6:chat", "7:media", "8:sys", "9:vm", "10:misc"]
    , (m, f) <- [("", W.greedyView), ("S-", W.shift)]
    ]
