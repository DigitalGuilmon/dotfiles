module Shared.Menu.NotificationCenter (notificationMenu) where

import Common.NotificationCenter
    ( NotificationBackend
    , detectNotificationBackend
    , notificationOptions
    , notificationUnavailableCommand
    )
import XMonad
import XMonad.Prompt (XPConfig)

import Shared.Menu.Prompt (promptConfig, runStaticPromptMenu)

notifOptions :: NotificationBackend -> [(String, X ())]
notifOptions backend =
    zipWith formatOption [1 :: Int ..] (notificationOptions backend)
  where
    formatOption index (label, command) =
        (show index ++ ". " ++ label, spawn command)

notifXPConfig :: XPConfig
notifXPConfig = promptConfig "#ff5555" "#f8f8f2" "#ff5555"

-- Menú de control de notificaciones
notificationMenu :: X ()
notificationMenu = do
    backend <- io detectNotificationBackend
    case backend of
        Just backend' ->
            let options = notifOptions backend'
            in runStaticPromptMenu " Notificaciones: " notifXPConfig options id
        Nothing ->
            spawn notificationUnavailableCommand
