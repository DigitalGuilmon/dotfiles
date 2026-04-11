module Shared.Launchers.NetworkMenu (networkMenu) where

import XMonad (X)

import Shared.Script (runWmSharedScript)

-- Menú de gestión de red y conectividad
networkMenu :: X ()
networkMenu = runWmSharedScript "network/network_menu.hs"
