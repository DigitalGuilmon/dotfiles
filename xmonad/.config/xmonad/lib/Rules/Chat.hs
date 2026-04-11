module Rules.Chat (chatRules) where

import XMonad

import Variables (wsChat)

chatRules :: [ManageHook]
chatRules =
    [ className =? "discord"            --> doShift wsChat
    , className =? "TelegramDesktop"    --> doShift wsChat
    ]
