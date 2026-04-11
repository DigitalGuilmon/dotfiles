-- Archivo: xmonad/.config/xmonad/lib/Layouts.hs

{-# LANGUAGE NoMonomorphismRestriction #-}
module Layouts where

import XMonad
import XMonad.Hooks.ManageDocks (avoidStruts)
import XMonad.Layout.NoBorders (smartBorders)
import XMonad.Layout.Spacing (smartSpacing)
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances
import XMonad.Layout.ThreeColumns (ThreeCol(..))
import XMonad.Layout.Grid (Grid(..))
import XMonad.Layout.Renamed (renamed, Rename(Replace))

mySpacing = smartSpacing 5 

-- Al aplicar renamed DESPUÉS de mySpacing, sobrescribimos el nombre generado automáticamente
myLayout = mkToggle (NBFULL ?? EOT) $ smartBorders $ avoidStruts $ 
           (renamed [Replace "Tall"]   $ mySpacing tiled) ||| 
           (renamed [Replace "Col3"]   $ mySpacing threeCol) ||| 
           (renamed [Replace "Grid"]   $ mySpacing grid) ||| 
           (renamed [Replace "Mirror"] $ Mirror $ mySpacing tiled) ||| 
           (renamed [Replace "Max"] Full)
  where 
        tiled    = Tall 1 (3/100) (1/2)
        threeCol = ThreeColMid 1 (3/100) (1/2)
        grid     = Grid
