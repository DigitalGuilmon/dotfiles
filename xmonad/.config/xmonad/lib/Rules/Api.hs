module Rules.Api (apiRules) where

import XMonad

import Variables (myWorkspaces)

apiRules :: [ManageHook]
apiRules =
    [ className =? "Postman"            --> doShift (myWorkspaces !! 4)
    , className =? "Insomnia"           --> doShift (myWorkspaces !! 4)
    ]
