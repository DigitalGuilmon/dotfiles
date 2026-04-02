{-# LANGUAGE NoMonomorphismRestriction #-}
module Layouts where

import XMonad
import XMonad.Hooks.ManageDocks (avoidStruts)
import XMonad.Layout.NoBorders (smartBorders, noBorders)
import XMonad.Layout.Spacing (smartSpacing)
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances

-- Gaps inteligentes de 15px (se desactivan si hay una sola ventana)
mySpacing = smartSpacing 15

-- Envolvemos todo en mkToggle para soporte de Fullscreen real
myLayout = mkToggle (NBFULL ?? EOT) $ smartBorders $ avoidStruts $ mySpacing 
           (tiled ||| Mirror tiled ||| noBorders Full)
  where 
        tiled = Tall 1 (3/100) (1/2)
