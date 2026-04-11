module Shared.Launchers.AudioControl (audioMenu) where

import XMonad (X)

import Shared.Script (runWmSharedScriptArgs)

-- Menú interactivo de control de audio
audioMenu :: X ()
audioMenu = runWmSharedScriptArgs "multimedia/volume.hs" ["menu"]
