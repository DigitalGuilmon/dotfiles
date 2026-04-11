module Rules.Api (apiRules) where

import XMonad

import Variables (wsApi)

apiRules :: [ManageHook]
apiRules =
    [ className =? "Postman"            --> doShift wsApi
    , className =? "Insomnia"           --> doShift wsApi
    ]
