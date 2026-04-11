module Common.NotificationCenter
    ( NotificationBackend (..)
    , detectNotificationBackend
    , notificationMenuId
    , notificationOptions
    , notificationPrompt
    , notificationUnavailableCommand
    ) where

import System.Directory (findExecutable)

data NotificationBackend
    = SwayNotificationCenter
    | DunstNotificationCenter

notificationPrompt :: String
notificationPrompt = "Notificaciones"

notificationMenuId :: NotificationBackend -> String
notificationMenuId SwayNotificationCenter = "wm-shared-notifications-swaync"
notificationMenuId DunstNotificationCenter = "wm-shared-notifications-dunst"

notificationOptions :: NotificationBackend -> [(String, String)]
notificationOptions SwayNotificationCenter =
    [ ("Mostrar panel", "swaync-client -op -sw")
    , ("Ocultar panel", "swaync-client -cp -sw")
    , ("Toggle panel", "swaync-client -t -sw")
    , ("Activar DND", "swaync-client -dn -sw")
    , ("Desactivar DND", "swaync-client -df -sw")
    , ("Toggle DND", "swaync-client -d -sw")
    , ("Cerrar ultima", "swaync-client --close-latest -sw")
    , ("Cerrar todas", "swaync-client -C -sw")
    , ("Conteo actual", "count=$(swaync-client -c -sw) && notify-send '🔔 Notificaciones' \"Pendientes: $count\"")
    ]
notificationOptions DunstNotificationCenter =
    [ ("Mostrar historial", "dunstctl history-pop")
    , ("Cerrar ultima", "dunstctl close")
    , ("Cerrar todas", "dunstctl close-all")
    , ("Activar DND", "notify-send -t 1500 '🔕 DND' 'Modo No Molestar activado' && sleep 2 && dunstctl set-paused true")
    , ("Desactivar DND", "dunstctl set-paused false && notify-send '🔔 DND' 'Notificaciones restauradas'")
    , ("Toggle DND", "dunstctl set-paused toggle")
    , ("Estado actual", "notify-send '📊 Dunst' \"Pausado: $(dunstctl is-paused) | Esperando: $(dunstctl count waiting) | Mostradas: $(dunstctl count displayed)\"")
    ]

notificationUnavailableCommand :: String
notificationUnavailableCommand = "notify-send '⚠️ Notificaciones' 'No se encontro swaync-client ni dunstctl'"

detectNotificationBackend :: IO (Maybe NotificationBackend)
detectNotificationBackend = do
    swaync <- findExecutable "swaync-client"
    dunst <- findExecutable "dunstctl"
    pure $
        case (swaync, dunst) of
            (Just _, _) -> Just SwayNotificationCenter
            (Nothing, Just _) -> Just DunstNotificationCenter
            _ -> Nothing
