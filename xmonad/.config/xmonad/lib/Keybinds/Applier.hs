module Keybinds.Applier (applyGeneratedKeybinds) where

import XMonad
import qualified XMonad.StackSet as W
import XMonad.Actions.CycleWS (nextWS, prevWS, shiftToNext, shiftToPrev)
import XMonad.Layout.MultiToggle (Toggle (..))
import XMonad.Layout.MultiToggle.Instances (StdTransformers (NBFULL))
import XMonad.Util.NamedScratchpad (namedScratchpadAction)
import System.Exit (ExitCode (ExitSuccess), exitWith)

import Actions.Menus (changeWallpaper, confirmKillAll, devMenu, gridGoToWindow, layoutMenu, monitorMenu, powerMenu, screenshot, windowManagerMenu)
import Actions.Prompts (runShell, searchGoogle, searchMan, searchYouTube)
import Actions.WindowControls (centerWindow, sinkAll, sinkWindow, toggleFloatCentered)
import Keybinds.Spec (KeybindSpec (..))
import Scratchpads (myScratchpads)
import Variables

type ActionResolver = KeybindSpec -> X ()

applyGeneratedKeybinds :: [KeybindSpec] -> [(String, X ())]
applyGeneratedKeybinds = map (\spec -> (keybindKey spec, resolveAction spec))

resolveAction :: KeybindSpec -> X ()
resolveAction spec =
    case lookup (keybindAction spec) actionResolvers of
        Just action -> action spec
        Nothing -> error ("Unknown generated xmonad action: " ++ keybindAction spec)

actionResolvers :: [(String, ActionResolver)]
actionResolvers =
    concat
        [ constResolvers
        , sharedResolvers
        , scratchpadResolvers
        , workspaceResolvers
        ]

constResolvers :: [(String, ActionResolver)]
constResolvers =
    concat
        [ constActions (spawn myTerminal) ["terminal"]
        , constActions (spawn myAppLauncher) ["launcher-menu"]
        , constActions (spawn myBrowser) ["browser"]
        , constActions (spawn myEditor) ["editor"]
        , constActions (spawn myYouTubeCmd) ["youtube"]
        , constActions (spawn ("rofi -show window -show-icons -theme " ++ myTheme)) ["rofi-window-picker"]
        , constActions powerMenu ["system-menu"]
        , constActions screenshot ["screenshot"]
        , constActions gridGoToWindow ["window-list", "search-window-grid"]
        , constActions windowManagerMenu ["window-menu"]
        , constActions confirmKillAll ["close-all-windows"]
        , constActions changeWallpaper ["wallpaper"]
        , constActions layoutMenu ["layout-menu"]
        , constActions devMenu ["dev-tools"]
        , constActions monitorMenu ["monitor-menu"]
        , constActions (spawn (syncKeybindsCommand "xmonad" ++ " && xmonad --recompile && xmonad --restart")) ["reload-wm"]
        , constActions (spawn "xmonad --restart") ["restart-bars-or-wm"]
        , constActions (io (exitWith ExitSuccess)) ["logout", "force-exit"]
        , constActions (return ()) ["disable-default-gmrun"]
        , constActions searchGoogle ["search-google"]
        , constActions searchYouTube ["search-youtube"]
        , constActions searchMan ["search-man"]
        , constActions runShell ["search-shell"]
        , constActions kill ["window-close"]
        , constActions (sendMessage $ Toggle NBFULL) ["window-fullscreen"]
        , constActions toggleFloatCentered ["window-toggle-floating"]
        , constActions centerWindow ["window-center"]
        , constActions (windows W.focusDown) ["window-focus-down"]
        , constActions (windows W.focusUp) ["window-focus-up"]
        , constActions (sendMessage Shrink) ["window-focus-left"]
        , constActions (sendMessage Expand) ["window-focus-right"]
        , constActions (windows W.focusMaster) ["window-focus-master"]
        , constActions (windows W.swapDown) ["window-move-down"]
        , constActions (windows W.swapUp) ["window-move-up"]
        , constActions (windows W.swapMaster) ["window-swap-master"]
        , constActions (sendMessage (IncMasterN 1)) ["window-inc-masters"]
        , constActions (sendMessage (IncMasterN (-1))) ["window-dec-masters"]
        , constActions refresh ["window-refresh"]
        , constActions sinkWindow ["window-send-to-scratchpad"]
        , constActions sinkAll ["window-sink-all"]
        , constActions (sendMessage FirstLayout) ["window-first-layout"]
        , constActions (sendMessage NextLayout) ["window-next-layout"]
        , constActions nextWS ["workspace-next", "workspace-next-arrow"]
        , constActions prevWS ["workspace-prev", "workspace-prev-arrow"]
        , constActions (shiftToNext >> nextWS) ["workspace-shift-next"]
        , constActions (shiftToPrev >> prevWS) ["workspace-shift-prev"]
        , constActions (spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") ["volume-up"]
        , constActions (spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") ["volume-down"]
        , constActions (spawn "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") ["volume-mute"]
        , constActions (spawn "$HOME/.config/wm-shared/scripts/bin/multimedia/volume.hs mic") ["mic-mute"]
        , constActions (spawn "playerctl previous") ["media-prev"]
        , constActions (spawn "playerctl play-pause") ["media-play-pause"]
        , constActions (spawn "playerctl next") ["media-next"]
        , constActions (spawn "brightnessctl set +5%") ["brightness-up"]
        , constActions (spawn "brightnessctl set 5%-") ["brightness-down"]
        ]

sharedResolvers :: [(String, ActionResolver)]
sharedResolvers =
    concat
        [ sharedActions
            [ ("ai-menu", "ai/ai_menu.hs")
            , ("network-menu", "network/network_menu.hs")
            , ("todo-menu", "productivity/todo.hs")
            , ("volume-menu", "multimedia/volume.hs menu")
            , ("steam-menu", "multimedia/steam_menu.hs")
            , ("docker-menu", "system/docker.hs")
            , ("calculator", "productivity/calculator.hs")
            , ("english-menu", "productivity/english.hs")
            , ("web-bookmarks", "network/web_menu.hs")
            , ("yt-dlp-menu", "network/yt_dlp_menu.hs")
            , ("shell-prompt", "system/prompt.hs")
            ]
        , dispatchActions
            [ "multimedia-menu"
            , "notifications"
            , "productivity-menu"
            , "projects-menu"
            , "emoji-picker"
            , "timer-menu"
            , "system-info"
            , "clipboard-menu"
            , "workspace-menu"
            , "scratchpad-menu"
            , "session-menu"
            , "files-menu"
            , "bluetooth-menu"
            , "appearance-menu"
            ]
        ]

scratchpadResolvers :: [(String, ActionResolver)]
scratchpadResolvers =
    scratchpadActions
        [ ("window-toggle-scratchpad", "terminal")
        , ("scratchpad-vscode", "vscode")
        , ("scratchpad-filemanager", "filemanager")
        , ("scratchpad-btop", "btop")
        , ("scratchpad-notes", "notes")
        ]

workspaceResolvers :: [(String, ActionResolver)]
workspaceResolvers =
    [ ("workspace-focus", workspaceAction W.greedyView "workspace-focus")
    , ("workspace-move", workspaceAction W.shift "workspace-move")
    ]

constActions :: X () -> [String] -> [(String, ActionResolver)]
constActions action names = [(name, constAction action) | name <- names]

sharedActions :: [(String, FilePath)] -> [(String, ActionResolver)]
sharedActions entries = [(name, constAction (spawnShared path)) | (name, path) <- entries]

dispatchActions :: [String] -> [(String, ActionResolver)]
dispatchActions names = [(name, constAction (spawnDispatch name)) | name <- names]

scratchpadActions :: [(String, String)] -> [(String, ActionResolver)]
scratchpadActions entries = [(name, constAction (namedScratchpadAction myScratchpads scratchName)) | (name, scratchName) <- entries]

constAction :: X () -> ActionResolver
constAction action _ = action

spawnShared :: FilePath -> X ()
spawnShared = spawn . myWmSharedScriptShell

spawnDispatch :: String -> X ()
spawnDispatch actionName = spawnShared ("dispatch.hs " ++ actionName)

syncKeybindsCommand :: String -> String
syncKeybindsCommand target = "$HOME/.config/wm-shared/scripts/bin/system/sync_keybinds.sh --target " ++ target

workspaceAction :: (WorkspaceId -> WindowSet -> WindowSet) -> String -> ActionResolver
workspaceAction action actionName spec = windows $ action (requiredArg actionName spec)

requiredArg :: String -> KeybindSpec -> String
requiredArg actionName spec =
    case keybindArg spec of
        Just value -> value
        Nothing -> error ("Missing argument for generated xmonad action: " ++ actionName)
