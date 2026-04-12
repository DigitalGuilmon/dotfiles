module Scripts.Network.Bookmarks (bookmarkMenu) where

import XMonad
import XMonad.Prompt
import XMonad.Prompt.FuzzyMatch (fuzzyMatch)

data BookmarkPrompt = BookmarkPrompt

instance XPrompt BookmarkPrompt where
    showXPrompt BookmarkPrompt = " Bookmarks: "
    commandToComplete _ c = c
    nextCompletion _ = getNextCompletion

-- Personaliza con tus URLs más usadas
bookmarkList :: [(String, X ())]
bookmarkList =
    -- Desarrollo
    [ ("GitHub",            spawn "xdg-open https://github.com")
    , ("GitHub Repos",      spawn "xdg-open https://github.com?tab=repositories")
    , ("Stack Overflow",    spawn "xdg-open https://stackoverflow.com")
    , ("Hoogle (Haskell)",  spawn "xdg-open https://hoogle.haskell.org")
    , ("Hackage",           spawn "xdg-open https://hackage.haskell.org")
    , ("DevDocs",           spawn "xdg-open https://devdocs.io")
    , ("Docker Hub",        spawn "xdg-open https://hub.docker.com")
    -- Productividad
    , ("ChatGPT",           spawn "xdg-open https://chat.openai.com")
    , ("Notion",            spawn "xdg-open https://notion.so")
    , ("Trello",            spawn "xdg-open https://trello.com")
    -- Linux / Arch
    , ("Arch Wiki",         spawn "xdg-open https://wiki.archlinux.org")
    , ("AUR Packages",      spawn "xdg-open https://aur.archlinux.org")
    , ("XMonad Docs",       spawn "xdg-open https://xmonad.org/documentation.html")
    -- Multimedia
    , ("YouTube",           spawn "xdg-open https://youtube.com")
    , ("Spotify Web",       spawn "xdg-open https://open.spotify.com")
    , ("Reddit",            spawn "xdg-open https://reddit.com")
    ]

bookmarkXPConfig :: XPConfig
bookmarkXPConfig = def
    { font              = "xft:JetBrainsMono Nerd Font:size=11"
    , bgColor           = "#282a36"
    , fgColor           = "#f8f8f2"
    , bgHLight          = "#ffb86c"
    , fgHLight          = "#282a36"
    , borderColor       = "#ffb86c"
    , promptBorderWidth = 2
    , position          = CenteredAt 0.5 0.5
    , height            = 50
    , alwaysHighlight   = True
    , searchPredicate   = fuzzyMatch
    }

-- Menú de bookmarks con búsqueda fuzzy
bookmarkMenu :: X ()
bookmarkMenu = mkXPrompt BookmarkPrompt bookmarkXPConfig
    (mkComplFunFromList' bookmarkXPConfig (map fst bookmarkList))
    (\selection -> case lookup selection bookmarkList of
        Just action -> action
        Nothing     -> return ()
    )
