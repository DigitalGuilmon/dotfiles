module Actions.Menus
    ( changeWallpaper
    , confirmKillAll
    , devMenu
    , gridGoToWindow
    , layoutMenu
    , monitorMenu
    , powerMenu
    , restoreWallpaper
    , screenshot
    , windowManagerMenu
    ) where

import Data.Char (isAlphaNum)
import System.Exit (ExitCode (ExitSuccess), exitWith)
import XMonad
import qualified XMonad.StackSet as W
import XMonad.Actions.GridSelect
import XMonad.Layout (JumpToLayout (JumpToLayout))
import XMonad.Prompt
import XMonad.Prompt.FuzzyMatch (fuzzyMatch)
import XMonad.Util.Run (runProcessWithInput)

import Actions.Rofi (rofiSelect)
import Actions.WindowControls (centerWindow, sinkAll, sinkWindow, toggleFloatCentered)
import Variables (myWmSharedScriptShell)

screenshot :: X ()
screenshot = spawn $ myWmSharedScriptShell "multimedia/screenshot.hs"

changeWallpaper :: X ()
changeWallpaper = spawn $ myWmSharedScriptShell "system/wallpaper_universe.hs"

restoreWallpaper :: X ()
restoreWallpaper =
    spawn "if [ -f ~/.cache/wallpaper.jpg ]; then feh --bg-fill ~/.cache/wallpaper.jpg; else notify-send '🖼️ Wallpaper' 'No se encontró wallpaper en cache. Usa Super+U para descargar uno.'; fi"

myGridConfig :: GSConfig Window
myGridConfig =
    def
        { gs_cellheight = 50
        , gs_cellwidth = 250
        , gs_cellpadding = 10
        , gs_font = "xft:JetBrainsMono Nerd Font:weight=bold:pixelsize=14"
        , gs_colorizer = colorizer
        }
  where
    colorizer _ True = pure ("#bd93f9", "#282a36")
    colorizer _ False = pure ("#282a36", "#f8f8f2")

gridGoToWindow :: X ()
gridGoToWindow = goToSelected myGridConfig

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
        Nothing -> pure ()

data DevPrompt = DevPrompt

instance XPrompt DevPrompt where
    showXPrompt DevPrompt = " DevTools: "
    commandToComplete _ c = c
    nextCompletion _ = getNextCompletion

devOptions :: [(String, X ())]
devOptions =
    [ ("Docker: Listar Contenedores", spawn "ghostty -e sh -c 'docker ps -a; echo; echo \"[Enter para cerrar]\"; read'")
    , ("Docker: Compose Up", spawn "ghostty -e sh -c 'docker compose up -d && echo && echo \"✅ Servicios iniciados\" ; echo \"[Enter para cerrar]\"; read'")
    , ("Docker: Compose Down", spawn "ghostty -e sh -c 'docker compose down && echo && echo \"🛑 Servicios detenidos\" ; echo \"[Enter para cerrar]\"; read'")
    , ("Docker: Prune (Limpieza)", spawn "ghostty -e sh -c 'docker system prune -f && echo && echo \"🧹 Limpieza completada\" ; echo \"[Enter para cerrar]\"; read'")
    , ("Git: Status", spawn "ghostty -e sh -c 'git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo \"No es un repositorio git. Directorio: $(pwd)\"; echo; echo \"[Enter para cerrar]\"; read; exit 1; }; git status; echo; echo \"[Enter para cerrar]\"; read'")
    , ("Git: Log (ultimos 20)", spawn "ghostty -e sh -c 'git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo \"No es un repositorio git. Directorio: $(pwd)\"; echo; echo \"[Enter para cerrar]\"; read; exit 1; }; git log --oneline --graph -20; echo; echo \"[Enter para cerrar]\"; read'")
    , ("Git: Lazygit", spawn "ghostty -e lazygit")
    , ("Tmux: Nueva Sesion Dev", spawn "ghostty -e tmux new-session -s dev")
    , ("Tmux: Attach Sesion", spawn "ghostty -e sh -c 'tmux ls 2>/dev/null && tmux attach || echo \"No hay sesiones activas\"; echo; echo \"[Enter para cerrar]\"; read'")
    , ("Sys: htop/btop", spawn "ghostty -e btop")
    , ("Sys: Uso de Disco (ncdu)", spawn "ghostty -e ncdu /")
    , ("Sys: Logs del Sistema", spawn "ghostty -e sh -c 'journalctl -f'")
    , ("Sys: Procesos Zombie", spawn "result=$(ps aux | awk '$8==\"Z\" {print $0}' | head -10); notify-send '🧟 Zombies' \"${result:-Ninguno encontrado}\"")
    ]

devXPConfig :: XPConfig
devXPConfig =
    def
        { font = "xft:JetBrainsMono Nerd Font:size=11"
        , bgColor = "#282a36"
        , fgColor = "#f8f8f2"
        , bgHLight = "#50fa7b"
        , fgHLight = "#282a36"
        , borderColor = "#50fa7b"
        , promptBorderWidth = 2
        , position = CenteredAt 0.5 0.5
        , height = 50
        , alwaysHighlight = True
        , searchPredicate = fuzzyMatch
        }

devMenu :: X ()
devMenu =
    mkXPrompt DevPrompt devXPConfig (mkComplFunFromList' devXPConfig (map fst devOptions)) $ \selection ->
        case lookup selection devOptions of
            Just action -> action
            Nothing -> pure ()

data PowerPrompt = PowerPrompt

instance XPrompt PowerPrompt where
    showXPrompt PowerPrompt = " Energía (Escoge o escribe): "
    commandToComplete _ c = c
    nextCompletion _ = getNextCompletion

powerOptions :: [(String, X ())]
powerOptions =
    [ ("1. Apagar (Shutdown)", spawn "systemctl poweroff")
    , ("2. Reiniciar (Reboot)", spawn "systemctl reboot")
    , ("3. Suspender (Suspend)", spawn "systemctl suspend")
    , ("4. Cerrar Sesión (Logout)", io (exitWith ExitSuccess))
    ]

powerXPConfig :: XPConfig
powerXPConfig =
    def
        { font = "xft:JetBrainsMono Nerd Font:size=11"
        , bgColor = "#282a36"
        , fgColor = "#f8f8f2"
        , bgHLight = "#ff79c6"
        , fgHLight = "#282a36"
        , borderColor = "#bd93f9"
        , promptBorderWidth = 2
        , position = CenteredAt 0.5 0.5
        , height = 50
        , alwaysHighlight = True
        , searchPredicate = fuzzyMatch
        }

powerMenu :: X ()
powerMenu =
    mkXPrompt PowerPrompt powerXPConfig (mkComplFunFromList' powerXPConfig (map fst powerOptions)) $ \selection ->
        case lookup selection powerOptions of
            Just action -> action
            Nothing -> pure ()

data MonitorPrompt = MonitorPrompt

instance XPrompt MonitorPrompt where
    showXPrompt MonitorPrompt = " Configuración de Pantallas: "
    commandToComplete _ c = c
    nextCompletion _ = getNextCompletion

sanitizeOutput :: String -> String
sanitizeOutput = filter (\c -> isAlphaNum c || c `elem` ("-_." :: String))

detectOutputs :: X (String, Maybe String)
detectOutputs = do
    out <- io $ runProcessWithInput "sh" ["-c", "xrandr --query | grep ' connected' | awk '{print $1}'"] ""
    let outputs = filter (not . null) . map sanitizeOutput $ lines (filter (/= '\r') out)
    case outputs of
        (primary:secondary:_) -> pure (primary, Just secondary)
        (primary:_) -> pure (primary, Nothing)
        _ -> pure ("eDP-1", Nothing)

monitorOptions :: String -> String -> [(String, X ())]
monitorOptions laptop external =
    [ ("1. Solo Laptop", spawn $ "xrandr --output '" ++ laptop ++ "' --auto --output '" ++ external ++ "' --off")
    , ("2. Extender (Derecha)", spawn $ "xrandr --output '" ++ laptop ++ "' --auto --output '" ++ external ++ "' --auto --right-of '" ++ laptop ++ "'")
    , ("3. Extender (Izquierda)", spawn $ "xrandr --output '" ++ laptop ++ "' --auto --output '" ++ external ++ "' --auto --left-of '" ++ laptop ++ "'")
    , ("4. Duplicar (Mirror)", spawn $ "xrandr --output '" ++ laptop ++ "' --auto --output '" ++ external ++ "' --auto --same-as '" ++ laptop ++ "'")
    , ("5. Solo Monitor Externo", spawn $ "xrandr --output '" ++ laptop ++ "' --off --output '" ++ external ++ "' --auto")
    ]

monitorXPConfig :: XPConfig
monitorXPConfig =
    def
        { font = "xft:JetBrainsMono Nerd Font:size=11"
        , bgColor = "#282a36"
        , fgColor = "#f8f8f2"
        , bgHLight = "#ff79c6"
        , fgHLight = "#282a36"
        , borderColor = "#8be9fd"
        , promptBorderWidth = 2
        , position = CenteredAt 0.5 0.5
        , height = 50
        , alwaysHighlight = True
        , searchPredicate = fuzzyMatch
        }

monitorMenu :: X ()
monitorMenu = do
    (laptop, mExternal) <- detectOutputs
    case mExternal of
        Nothing -> spawn "notify-send '🖥️ Monitor' 'Solo se detectó una pantalla conectada'"
        Just external -> do
            let opts = monitorOptions laptop external
            mkXPrompt MonitorPrompt monitorXPConfig (mkComplFunFromList' monitorXPConfig (map fst opts)) $ \selection ->
                case lookup selection opts of
                    Just action -> action
                    Nothing -> pure ()

confirmKillAll :: X ()
confirmKillAll = do
    res <- rofiSelect "xmonad-confirm-kill-all" "¿Cerrar TODAS las ventanas?" ["-i"] "Sí\nNo"
    case res of
        "Sí" -> withWindowSet $ \ws -> mapM_ killWindow (W.allWindows ws)
        _ -> pure ()

windowManagerOptions :: [(String, X ())]
windowManagerOptions =
    [ ("Mostrar todas las ventanas", gridGoToWindow)
    , ("Toggle ventana flotante", toggleFloatCentered)
    , ("Centrar ventana actual", centerWindow)
    , ("Hundir ventana actual", sinkWindow)
    , ("Hundir todas las flotantes", sinkAll)
    , ("Cerrar ventana actual", kill)
    , ("Cerrar todas las ventanas", confirmKillAll)
    ]

windowManagerMenu :: X ()
windowManagerMenu = do
    selection <- rofiSelect "xmonad-window-manager" "Ventanas" ["-i"] (unlines (map fst windowManagerOptions))
    case lookup selection windowManagerOptions of
        Just action -> action
        Nothing -> pure ()
