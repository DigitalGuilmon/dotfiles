module Standalone.Environment
    ( runAppearanceMenu
    , runBluetoothMenu
    , runFilesMenu
    , runScratchpadMenu
    , runSessionMenu
    , runWorkspaceMenu
    ) where

import Control.Monad (forM, unless, void)
import Data.List (isInfixOf)
import System.Directory (findExecutable)
import System.Environment (lookupEnv)
import System.Process (spawnProcess)

import Standalone.Menu (MenuSpec (..), menuEntry, runMenuSpec, selectMenuSpec)
import Standalone.Runtime
    ( isWaylandSession
    , notify
    , openUrl
    , readProcessSafe
    , requireHomeDirectory
    , spawnCommandSafe
    )
import StandaloneUtils (confirmSelection, rofiSelection, shellEscape)

iconBack, iconBluetooth, iconClipboard, iconFiles, iconPaint, iconPower, iconScratchpad, iconWorkspace :: String
iconBack = "\xf006e"
iconBluetooth = "\xf00af"
iconClipboard = "\xf014c"
iconFiles = "\xf0214"
iconPaint = "\xf0534"
iconPower = "\xf0425"
iconScratchpad = "\xf11fd"
iconWorkspace = "\xf11fc"

workspaceLabels :: [(String, String)]
workspaceLabels =
    [ ("1", "1:dev")
    , ("2", "2:web")
    , ("3", "3:term")
    , ("4", "4:db")
    , ("5", "5:api")
    , ("6", "6:chat")
    , ("7", "7:media")
    , ("8", "8:sys")
    , ("9", "9:vm")
    , ("10", "10:misc")
    ]

runSessionMenu :: IO ()
runSessionMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "wm-shared-session-main"
            , menuSpecPrompt = "Sesion"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry (iconPower ++ " Bloquear pantalla") lockScreen
                , menuEntry (iconPower ++ " Suspender") (confirmAndRun "Suspender equipo" (spawnCommandSafe "systemctl suspend"))
                , menuEntry (iconPower ++ " Cerrar sesion") logoutSession
                , menuEntry (iconPower ++ " Reiniciar") (confirmAndRun "Reiniciar equipo" (spawnCommandSafe "systemctl reboot"))
                , menuEntry (iconPower ++ " Apagar") (confirmAndRun "Apagar equipo" (spawnCommandSafe "systemctl poweroff"))
                ]
            }

runFilesMenu :: IO ()
runFilesMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "wm-shared-files-main"
            , menuSpecPrompt = "Archivos"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry (iconFiles ++ " Explorador de archivos") openFileManager
                , menuEntry (iconFiles ++ " Ranger en terminal") (spawnCommandSafe "ghostty -e ranger")
                , menuEntry (iconFiles ++ " Descargas") (openHomePath "Downloads")
                , menuEntry (iconFiles ++ " Archivos recientes") recentFilesMenu
                , menuEntry (iconFiles ++ " Buscar por nombre") searchFileByName
                , menuEntry (iconFiles ++ " Buscar por contenido") searchFileByContent
                ]
            }

runWorkspaceMenu :: IO ()
runWorkspaceMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "wm-shared-workspace-main"
            , menuSpecPrompt = "Workspaces"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry (iconWorkspace ++ " Cambiar workspace") (workspaceSelectionMenu FocusWorkspace)
                , menuEntry (iconWorkspace ++ " Mover ventana actual") (workspaceSelectionMenu MoveWindowToWorkspace)
                ]
            }

runScratchpadMenu :: IO ()
runScratchpadMenu = do
    wayland <- isWaylandSession
    if wayland
        then runHyprScratchpadMenu
        else runXmonadScratchpadMenu

runBluetoothMenu :: IO ()
runBluetoothMenu = do
    powered <- bluetoothPowered
    devices <- bluetoothDevices
    deviceEntries <- forM devices $ \(mac, name) -> do
        connected <- bluetoothConnected mac
        let prefix = if connected then "\xf058 " else "\xf111 "
        pure (menuEntry (prefix ++ name) (toggleBluetoothDevice mac connected))
    runMenuSpec $
        MenuSpec
            { menuSpecId = "wm-shared-bluetooth-main"
            , menuSpecPrompt = "Bluetooth"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry (iconBluetooth ++ " " ++ if powered then "Apagar Bluetooth" else "Encender Bluetooth") toggleBluetoothPower
                , menuEntry (iconBluetooth ++ " Abrir Blueman") (spawnIfAvailable "blueman-manager" [] "Bluetooth" "Instala blueman para gestionar dispositivos.")
                ]
                    ++ if null deviceEntries
                        then [menuEntry "Sin dispositivos emparejados" (notify "normal" "Bluetooth" "No se encontraron dispositivos emparejados.")]
                        else deviceEntries
            }

runAppearanceMenu :: IO ()
runAppearanceMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "wm-shared-appearance-main"
            , menuSpecPrompt = "Apariencia"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry (iconPaint ++ " Wallpaper") (spawnCommandSafe "$HOME/.config/wm-shared/scripts/bin/system/wallpaper_universe.hs")
                , menuEntry (iconPaint ++ " Color picker") (spawnCommandSafe "$HOME/.config/wm-shared/scripts/bin/productivity/color_picker.hs")
                , menuEntry (iconPaint ++ " Tema GTK (lxappearance)") (spawnIfAvailable "lxappearance" [] "Apariencia" "No se encontro lxappearance.")
                , menuEntry (iconPaint ++ " Carpeta de temas de rofi") (openHomePath ".config/rofi/themes")
                , menuEntry (iconPaint ++ " Carpeta de wallpapers") (openHomePath "Pictures/Wallpapers")
                ]
            }

data WorkspaceAction
    = FocusWorkspace
    | MoveWindowToWorkspace
    deriving (Eq)

workspaceSelectionMenu :: WorkspaceAction -> IO ()
workspaceSelectionMenu action = do
    let entries = map (\(code, label) -> menuEntry label (runWorkspaceAction action code)) workspaceLabels
    runMenuSpec $
        MenuSpec
            { menuSpecId = "wm-shared-workspace-select"
            , menuSpecPrompt = if action == FocusWorkspace then "Ir a workspace" else "Mover a workspace"
            , menuSpecArgs = ["-i", "-l", "10"]
            , menuSpecEntries = entries
            }

runWorkspaceAction :: WorkspaceAction -> String -> IO ()
runWorkspaceAction action workspace = do
    wayland <- isWaylandSession
    if wayland
        then spawnCommandSafe (hyprWorkspaceCommand action workspace)
        else triggerXmonadKey (xmonadWorkspaceKey action workspace)

hyprWorkspaceCommand :: WorkspaceAction -> String -> String
hyprWorkspaceCommand action workspace =
    case action of
        FocusWorkspace -> "hyprctl dispatch workspace " ++ workspace
        MoveWindowToWorkspace -> "hyprctl dispatch movetoworkspace " ++ workspace

xmonadWorkspaceKey :: WorkspaceAction -> String -> String
xmonadWorkspaceKey action workspace =
    let xKey = if workspace == "10" then "0" else workspace
    in case action of
        FocusWorkspace -> "Super+" ++ xKey
        MoveWindowToWorkspace -> "Super+Shift+" ++ xKey

runHyprScratchpadMenu :: IO ()
runHyprScratchpadMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "wm-shared-scratchpad-hypr"
            , menuSpecPrompt = "Scratchpad"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry (iconScratchpad ++ " Mostrar/Ocultar scratchpad") (spawnCommandSafe "hyprctl dispatch togglespecialworkspace scratchpad")
                , menuEntry (iconScratchpad ++ " Enviar ventana actual al scratchpad") (spawnCommandSafe "hyprctl dispatch movetoworkspacesilent special:scratchpad")
                ]
            }

runXmonadScratchpadMenu :: IO ()
runXmonadScratchpadMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "wm-shared-scratchpad-xmonad"
            , menuSpecPrompt = "Scratchpads"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry (iconScratchpad ++ " Terminal") (triggerXmonadKey "Super+Up")
                , menuEntry (iconScratchpad ++ " VS Code") (triggerXmonadKey "Super+Shift+Up")
                , menuEntry (iconScratchpad ++ " File manager") (triggerXmonadKey "Super+Shift+F")
                , menuEntry (iconScratchpad ++ " btop") (triggerXmonadKey "Super+Shift+T")
                , menuEntry (iconScratchpad ++ " Notas") (triggerXmonadKey "Super+Shift+N")
                ]
            }

triggerXmonadKey :: String -> IO ()
triggerXmonadKey keyChord = do
    hasXdotool <- isInstalled "xdotool"
    if hasXdotool
        then
            spawnCommandSafe
                ("sh -c \"sleep 0.15; xdotool key --clearmodifiers "
                    ++ keyChord
                    ++ "\"")
        else notify "normal" "XMonad" "No se encontro xdotool para disparar los atajos de XMonad."

lockScreen :: IO ()
lockScreen = do
    command <- lockCommand
    case command of
        Just cmd -> spawnCommandSafe cmd
        Nothing -> notify "normal" "Sesion" "No se encontro un comando de bloqueo disponible."

lockCommand :: IO (Maybe String)
lockCommand = do
    wayland <- isWaylandSession
    hasHyprlock <- isInstalled "hyprlock"
    hasBetterlockscreen <- isInstalled "betterlockscreen"
    hasI3lock <- isInstalled "i3lock"
    sessionId <- lookupEnv "XDG_SESSION_ID"
    pure $
        if wayland && hasHyprlock
            then Just "hyprlock"
            else
                if hasBetterlockscreen
                    then Just "betterlockscreen -l"
                    else
                        if hasI3lock
                            then Just "i3lock"
                            else fmap (\sid -> "loginctl lock-session " ++ shellEscape sid) sessionId

logoutSession :: IO ()
logoutSession = do
    confirmed <- confirmSelection "wm-shared-session-logout" "Cerrar sesion - seguro?"
    unless (not confirmed) $ do
        wayland <- isWaylandSession
        sessionId <- lookupEnv "XDG_SESSION_ID"
        case () of
            _ | wayland -> spawnCommandSafe "hyprctl dispatch exit"
              | Just sid <- sessionId -> spawnCommandSafe ("loginctl terminate-session " ++ shellEscape sid)
              | otherwise -> notify "normal" "Sesion" "No se encontro una forma segura de cerrar la sesion."

confirmAndRun :: String -> IO () -> IO ()
confirmAndRun prompt action = do
    confirmed <- confirmSelection ("wm-shared-confirm-" ++ sanitizeMenuId prompt) (prompt ++ " - seguro?")
    unless (not confirmed) action

sanitizeMenuId :: String -> String
sanitizeMenuId = map replace
  where
    replace ' ' = '-'
    replace c = c

openFileManager :: IO ()
openFileManager = do
    hasThunar <- isInstalled "thunar"
    if hasThunar
        then spawnCommandSafe "thunar $HOME"
        else openHomePath ""

recentFilesMenu :: IO ()
recentFilesMenu =
    requireHomeDirectory "Archivos" "No se encontro la variable HOME." $ \homeDir -> do
        filesRaw <- readProcessSafe "sh" ["-c", recentFilesCommand homeDir] ""
        let files = take 200 (lines filesRaw)
        pickPathFromList "wm-shared-files-recent" "Recientes" files

searchFileByName :: IO ()
searchFileByName = do
    query <- rofiSelection "wm-shared-files-name-query" "Buscar archivo" ["-i"] ""
    unless (null query) $
        requireHomeDirectory "Archivos" "No se encontro la variable HOME." $ \homeDir -> do
            filesRaw <- readProcessSafe "sh" ["-c", fileNameSearchCommand homeDir query] ""
            pickPathFromList "wm-shared-files-name-results" "Resultados" (lines filesRaw)

searchFileByContent :: IO ()
searchFileByContent = do
    query <- rofiSelection "wm-shared-files-content-query" "Buscar contenido" ["-i"] ""
    unless (null query) $
        requireHomeDirectory "Archivos" "No se encontro la variable HOME." $ \homeDir -> do
            filesRaw <- readProcessSafe "rg" ["-l", "-i", query, homeDir] ""
            pickPathFromList "wm-shared-files-content-results" "Coincidencias" (lines filesRaw)

pickPathFromList :: String -> String -> [FilePath] -> IO ()
pickPathFromList menuId prompt options = do
    let trimmed = filter (not . null) options
    if null trimmed
        then notify "normal" "Archivos" "No se encontraron resultados."
        else do
            let spec =
                    MenuSpec
                        { menuSpecId = menuId
                        , menuSpecPrompt = prompt
                        , menuSpecArgs = ["-i", "-l", show (min 15 (length trimmed))]
                        , menuSpecEntries = map (\path -> menuEntry path path) trimmed ++ [menuEntry (iconBack ++ " Volver") ""]
                        }
            selected <- selectMenuSpec spec
            case selected of
                Just "" -> pure ()
                Just path -> openUrl path
                Nothing -> pure ()

openHomePath :: FilePath -> IO ()
openHomePath relativePath =
    requireHomeDirectory "Archivos" "No se encontro la variable HOME." $ \homeDir ->
        openUrl (if null relativePath then homeDir else homeDir ++ "/" ++ relativePath)

recentFilesCommand :: FilePath -> String
recentFilesCommand homeDir =
    "find "
        ++ shellEscape homeDir
        ++ " -path '*/.git' -prune -o -path '*/node_modules' -prune -o -type f -printf '%T@\\t%p\\n' 2>/dev/null | sort -nr | head -n 200 | cut -f2-"

fileNameSearchCommand :: FilePath -> String -> String
fileNameSearchCommand homeDir query =
    "find "
        ++ shellEscape homeDir
        ++ " -path '*/.git' -prune -o -path '*/node_modules' -prune -o -type f -iname "
        ++ shellEscape ("*" ++ query ++ "*")
        ++ " -print 2>/dev/null | head -n 200"

bluetoothPowered :: IO Bool
bluetoothPowered = do
    output <- readProcessSafe "bluetoothctl" ["show"] ""
    pure ("Powered: yes" `isInfixOf` output)

bluetoothDevices :: IO [(String, String)]
bluetoothDevices = do
    output <- readProcessSafe "bluetoothctl" ["paired-devices"] ""
    pure $
        [ (mac, unwords nameParts)
        | line <- lines output
        , ("Device" : mac : nameParts) <- [words line]
        ]

bluetoothConnected :: String -> IO Bool
bluetoothConnected mac = do
    output <- readProcessSafe "bluetoothctl" ["info", mac] ""
    pure ("Connected: yes" `isInfixOf` output)

toggleBluetoothPower :: IO ()
toggleBluetoothPower = do
    powered <- bluetoothPowered
    spawnCommandSafe $
        if powered
            then "bluetoothctl power off"
            else "bluetoothctl power on"

toggleBluetoothDevice :: String -> Bool -> IO ()
toggleBluetoothDevice mac connected =
    spawnCommandSafe $
        "bluetoothctl "
            ++ if connected then "disconnect " else "connect "
            ++ shellEscape mac

spawnIfAvailable :: FilePath -> [String] -> String -> String -> IO ()
spawnIfAvailable command args title errorMessage = do
    executable <- findExecutable command
    case executable of
        Just _ -> void $ spawnProcess command args
        Nothing -> notify "normal" title errorMessage

isInstalled :: FilePath -> IO Bool
isInstalled command = do
    executable <- findExecutable command
    pure (maybe False (const True) executable)
