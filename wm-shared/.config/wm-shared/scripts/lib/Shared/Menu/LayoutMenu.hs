module Shared.Menu.LayoutMenu (layoutMenu) where

import XMonad
import XMonad.Layout (JumpToLayout(..))

import Shared.Utils (rofiSelect)

layoutOptions :: [(String, String)]
layoutOptions =
    [ ("Tall - Principal + stack", "Tall")
    , ("Col3 - Tres columnas", "Col3")
    , ("Grid - Cuadricula", "Grid")
    , ("Mirror - Horizontal", "Mirror")
    , ("Max - Pantalla completa", "Max")
    ]

layoutMenu :: X ()
layoutMenu = do
    res <- rofiSelect "xmonad-layout-menu" "Layout:" ["-i"] (unlines (map fst layoutOptions))
    case lookup res layoutOptions of
        Just layoutName -> sendMessage (JumpToLayout layoutName)
        Nothing         -> return ()
