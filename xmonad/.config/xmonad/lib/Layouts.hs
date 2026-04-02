{-# LANGUAGE NoMonomorphismRestriction #-}
module Layouts where

import XMonad
import XMonad.Hooks.ManageDocks (avoidStruts)
import XMonad.Layout.NoBorders (smartBorders, noBorders)
import XMonad.Layout.Spacing (spacingRaw, Border(..))
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances

-- Gaps de 15px
mySpacing = spacingRaw False (Border 15 15 15 15) True (Border 15 15 15 15) True

-- Envolvemos todo en mkToggle para soporte de Fullscreen real
myLayout = mkToggle (NBFULL ?? EOT) $ smartBorders $ avoidStruts $ mySpacing 
           (tiled ||| Mirror tiled ||| noBorders Full)
  where 
        tiled = Tall 1 (3/100) (1/2)
