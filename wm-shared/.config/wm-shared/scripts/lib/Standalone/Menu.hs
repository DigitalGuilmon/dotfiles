module Standalone.Menu
    ( MenuEntry (..)
    , MenuSpec (..)
    , menuEntry
    , runMenuSpec
    , selectMenuSpec
    ) where

import StandaloneUtils (selectOption)

data MenuEntry a = MenuEntry
    { menuEntryLabel :: String
    , menuEntryValue :: a
    }

data MenuSpec a = MenuSpec
    { menuSpecId :: String
    , menuSpecPrompt :: String
    , menuSpecArgs :: [String]
    , menuSpecEntries :: [MenuEntry a]
    }

menuEntry :: String -> a -> MenuEntry a
menuEntry = MenuEntry

selectMenuSpec :: MenuSpec a -> IO (Maybe a)
selectMenuSpec spec =
    selectOption
        (menuSpecId spec)
        (menuSpecPrompt spec)
        (menuSpecArgs spec)
        (map (\entry -> (menuEntryLabel entry, menuEntryValue entry)) (menuSpecEntries spec))

runMenuSpec :: MenuSpec (IO ()) -> IO ()
runMenuSpec spec = do
    selected <- selectMenuSpec spec
    maybe (pure ()) id selected
