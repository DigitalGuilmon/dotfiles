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

mySpacing = smartSpacing 15

myLayout = mkToggle (NBFULL ?? EOT) $ smartBorders $ avoidStruts $ mySpacing 
           (tiled ||| threeCol ||| grid ||| Mirror tiled ||| noBorders Full)
  where 
        tiled    = renamed [Replace "Spacing Tall"] $ Tall 1 (3/100) (1/2)
        threeCol = renamed [Replace "Spacing Col3"] $ ThreeColMid 1 (3/100) (1/2)
        grid     = renamed [Replace "Spacing Grid"] $ Grid
