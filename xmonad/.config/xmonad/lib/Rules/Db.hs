module Rules.Db (dbRules) where

import XMonad

import Variables (wsDb)

dbRules :: [ManageHook]
dbRules =
    [ className =? "DBeaver"            --> doShift wsDb
    ]
