module Standalone.UrlMenu
    ( UrlEntry (..)
    , runNamedUrlMenu
    , runUrlEntries
    , urlEntry
    ) where

import Common.UrlMenus (UrlEntry (..), urlEntry)
import StandaloneUtils (runUrlMenu)

runUrlEntries :: String -> String -> [String] -> [UrlEntry] -> IO ()
runUrlEntries menuId prompt browserArgs entries =
    runUrlMenu menuId prompt browserArgs (map (\entry -> (urlEntryLabel entry, urlEntryValue entry)) entries)

runNamedUrlMenu :: String -> String -> [String] -> [UrlEntry] -> IO ()
runNamedUrlMenu = runUrlEntries
