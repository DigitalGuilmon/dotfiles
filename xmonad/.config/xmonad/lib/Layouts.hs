-- Archivo: xmonad/.config/xmonad/lib/Layouts.hs

{-# LANGUAGE NoMonomorphismRestriction #-}
module Layouts where

import XMonad
import XMonad.Hooks.ManageDocks (avoidStruts)
import XMonad.Layout.NoBorders (smartBorders, noBorders)
import XMonad.Layout.Spacing (smartSpacing)
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances
import XMonad.Layout.ThreeColumns (ThreeCol(..))
import XMonad.Layout.Grid (Grid(..))
import XMonad.Layout.Renamed (renamed, Rename(Replace))

-- El valor de 25 da un buen margen entre ventanas
mySpacing = smartSpacing 25 

myLayout = mkToggle (NBFULL ?? EOT) $ smartBorders $ avoidStruts $ mySpacing 
           (tiled ||| threeCol ||| grid ||| Mirror tiled ||| noBorders Full)
  where 
        -- Se eliminó "Spacing" del nombre manual para evitar redundancia
        tiled    = renamed [Replace "Tall"] $ Tall 1 (3/100) (1/2)
        threeCol = renamed [Replace "Col3"] $ ThreeColMid 1 (3/100) (1/2)
        grid     = renamed [Replace "Grid"] $ Grid
