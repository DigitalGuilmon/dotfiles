module Rules.Chat (chatRules) where

import XMonad

import Variables (myWorkspaces)

chatRules :: [ManageHook]
chatRules =
    [ className =? "discord"            --> doShift (myWorkspaces !! 5)
    , className =? "TelegramDesktop"    --> doShift (myWorkspaces !! 5)
    ]
