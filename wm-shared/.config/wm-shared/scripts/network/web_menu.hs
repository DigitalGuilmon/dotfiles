#!/usr/bin/env runhaskell

import System.Process (readProcessWithExitCode, spawnProcess)
import System.Exit (ExitCode(ExitSuccess))
import System.Directory (getHomeDirectory)
import Data.List (intercalate)

main :: IO ()
main = do
    home <- getHomeDirectory
    let theme = home ++ "/.config/rofi/themes/modern.rasi"
        helper = home ++ "/.config/rofi/scripts/frequent-menu.py"

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
        inputStr = intercalate "\n" options

    (exitCode, out, _) <- readProcessWithExitCode helper
        [ "--menu-id", "hypr-web-menu"
        , "--prompt", "🌐 Ir a"
        , "--theme", theme
        , "--", "-i", "-l", show (length options)
        ]
        inputStr

    if exitCode == ExitSuccess
        then do
            let selection = filter (/= '\n') out
            case selection of
                "🔍 Google"           -> openInNewWindow "https://www.google.com"
                "📺 YouTube"          -> openInNewWindow "https://www.youtube.com"
                "🐦 X (Twitter)"       -> openInNewWindow "https://x.com"
                "👽 Reddit"           -> openInNewWindow "https://www.reddit.com"
                "🟢 WhatsApp"         -> openInNewWindow "https://web.whatsapp.com"
                "🐙 GitHub"           -> openInNewWindow "https://github.com"
                "📘 Facebook"         -> openInNewWindow "https://www.facebook.com"
                "🏔️  ArchWiki"         -> openInNewWindow "https://wiki.archlinux.org"
                "🔗 LinkedIn"         -> openInNewWindow "https://www.linkedin.com"
                "📚 Stack Overflow"   -> openInNewWindow "https://stackoverflow.com"
                "🧪 Hoogle (Haskell)" -> openInNewWindow "https://hoogle.haskell.org"
                _                     -> return ()
        else
            return ()

openInNewWindow :: String -> IO ()
openInNewWindow url = do
    _ <- spawnProcess "brave" ["--new-window", url]
    return ()
