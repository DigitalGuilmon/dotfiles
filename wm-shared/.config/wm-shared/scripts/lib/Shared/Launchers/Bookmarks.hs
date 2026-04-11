module Shared.Launchers.Bookmarks (bookmarkMenu) where

import XMonad (X)

import Shared.Script (runWmSharedScript)

-- Menú de bookmarks con búsqueda fuzzy
bookmarkMenu :: X ()
bookmarkMenu = runWmSharedScript "network/web_menu.hs"
