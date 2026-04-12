#!/usr/bin/env -S sh -c 'script_dir=$(dirname "$1"); exec runhaskell -i"$script_dir" -i"$script_dir/.." "$1" "$@"' sh

import System.Process (spawnProcess)

import StandaloneUtils (rofiLines)

main :: IO ()
main = do
    let options = [ "🔍 Google"
                  , "📺 YouTube"
                  , "🐦 X (Twitter)"
                  , "👽 Reddit"
                  , "🟢 WhatsApp"
                  , "🐙 GitHub"
                  , "📘 Facebook"
                  , "🏔️  ArchWiki"
                  , "🔗 LinkedIn"
                  , "📚 Stack Overflow"
                  , "🧪 Hoogle (Haskell)"
                  ]
    selection <- rofiLines "hypr-web-menu" "🌐 Ir a" ["-i", "-l", show (length options)] options
    case selection of
        "🔍 Google"           -> openInNewWindow "https://www.google.com"
        "📺 YouTube"          -> openInNewWindow "https://www.youtube.com"
        "🐦 X (Twitter)"      -> openInNewWindow "https://x.com"
        "👽 Reddit"           -> openInNewWindow "https://www.reddit.com"
        "🟢 WhatsApp"         -> openInNewWindow "https://web.whatsapp.com"
        "🐙 GitHub"           -> openInNewWindow "https://github.com"
        "📘 Facebook"         -> openInNewWindow "https://www.facebook.com"
        "🏔️  ArchWiki"        -> openInNewWindow "https://wiki.archlinux.org"
        "🔗 LinkedIn"         -> openInNewWindow "https://www.linkedin.com"
        "📚 Stack Overflow"   -> openInNewWindow "https://stackoverflow.com"
        "🧪 Hoogle (Haskell)" -> openInNewWindow "https://hoogle.haskell.org"
        _                     -> return ()

openInNewWindow :: String -> IO ()
openInNewWindow url = do
    _ <- spawnProcess "brave" ["--new-window", url]
    return ()
