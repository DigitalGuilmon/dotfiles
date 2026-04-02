{-# LANGUAGE NoMonomorphismRestriction #-}
module Layouts where

import XMonad
import XMonad.Hooks.ManageDocks (avoidStruts)
import XMonad.Layout.NoBorders (smartBorders, noBorders)
import XMonad.Layout.Spacing (smartSpacing)
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances

-- Nuevas importaciones para mejorar los layouts
import XMonad.Layout.ThreeColumns (ThreeCol(..))
import XMonad.Layout.Grid (Grid(..))
import XMonad.Layout.Renamed (renamed, Rename(Replace))

-- Gaps inteligentes de 15px (se desactivan si hay una sola ventana)
mySpacing = smartSpacing 15

-- Envolvemos todo en mkToggle para soporte de Fullscreen real
myLayout = mkToggle (NBFULL ?? EOT) $ smartBorders $ avoidStruts $ mySpacing 
           (tiled ||| threeCol ||| grid ||| Mirror tiled ||| noBorders Full)
  where 
        -- Renombramos los layouts para que Xmobar muestre nombres limpios
        tiled    = renamed [Replace "Tall"] $ Tall 1 (3/100) (1/2)
        threeCol = renamed [Replace "Col3"] $ ThreeColMid 1 (3/100) (1/2)
        grid     = renamed [Replace "Grid"] $ Grid
