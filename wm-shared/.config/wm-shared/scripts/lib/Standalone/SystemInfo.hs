module Standalone.SystemInfo (runSystemInfoMenu) where

import Common.SystemInfo (systemInfoOptions)
import Standalone.Menu (MenuSpec (..), menuEntry, runMenuSpec)
import StandaloneUtils (spawnCommand_)

runSystemInfoMenu :: IO ()
runSystemInfoMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "wm-shared-system-info"
            , menuSpecPrompt = "SysInfo:"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries = map (uncurry menuEntry . fmap spawnCommand_) systemInfoOptions
            }
