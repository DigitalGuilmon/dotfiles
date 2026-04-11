module Standalone.NotificationCenter (runNotificationCenter) where

import Common.NotificationCenter
    ( detectNotificationBackend
    , notificationMenuId
    , notificationOptions
    , notificationPrompt
    , notificationUnavailableCommand
    )

import Standalone.Menu (MenuSpec (..), menuEntry, runMenuSpec)
import StandaloneUtils (spawnCommand_)

runNotificationCenter :: IO ()
runNotificationCenter = do
    backend <- detectNotificationBackend
    case backend of
        Just backend' ->
            runMenuSpec $
                MenuSpec
                    { menuSpecId = notificationMenuId backend'
                    , menuSpecPrompt = notificationPrompt
                    , menuSpecArgs = ["-i"]
                    , menuSpecEntries = map (uncurry menuEntry . fmap spawnCommand_) (notificationOptions backend')
                    }
        Nothing ->
            spawnCommand_ notificationUnavailableCommand
