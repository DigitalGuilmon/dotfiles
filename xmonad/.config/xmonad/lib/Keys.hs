module Keys where

import XMonad
import XMonad.Util.NamedScratchpad (namedScratchpadAction)
import qualified XMonad.StackSet as W
import XMonad.Layout.MultiToggle (Toggle(..))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL))

import Variables (myTerminal, myTheme, myWorkspaces)
import Scratchpads (myScratchpads)

myKeys :: [(String, X ())]
myKeys = 
    [ ("M-x", kill)
    , ("M-<Return>", spawn myTerminal)
    , ("M-v", spawn (myTerminal ++ " -e lvim"))
    , ("M-s", namedScratchpadAction myScratchpads "terminal")
    , ("M-q", spawn "xmonad --recompile; xmonad --restart")
    , ("M-<Escape>", withWindowSet $ \s -> mapM_ killWindow (W.allWindows s))
    
    -- Menús Rofi (simplificados)
    , ("M-<Tab>", spawn ("rofi -show window -show-icons -theme " ++ myTheme))
    , ("M-d", spawn ("rofi -show drun -show-icons -theme " ++ myTheme))
    
    -- Utilidades
    , ("M-p", spawn "bash -c 'res=$(echo -e \"Full Screen\\nArea Selection\\nActive Window\" | rofi -dmenu -p \"Screenshot:\" -theme ~/.config/rofi/cyberpunk.rasi -i); sleep 0.4; f=~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png; case \"$res\" in \"Full Screen\") maim \"$f\" ;; \"Area Selection\") maim -s \"$f\" ;; \"Active Window\") maim -i $(xdotool getactivewindow) \"$f\" ;; esac; if [ -f \"$f\" ]; then xclip -selection clipboard -t image/png -i \"$f\" && notify-send \"Screenshot\" \"Guardada\"; fi'")

    -- Control de Layout y Foco
    , ("M-j", windows W.focusDown)
    , ("M-k", windows W.focusUp)
    , ("M-f", sendMessage $ Toggle NBFULL)
    , ("M-h", sendMessage Shrink)
    , ("M-l", sendMessage Expand)
    ]
    ++
    [ ("M-" ++ m ++ k, windows $ f w) | (k, w) <- zip (map show ([1..9] :: [Int]) ++ ["0"]) myWorkspaces, (m, f) <- [("", W.greedyView), ("S-", W.shift)] ]
