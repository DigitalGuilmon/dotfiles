#!/usr/bin/env runhaskell

import System.Process (readProcessWithExitCode, spawnProcess)
import System.Exit (ExitCode(ExitSuccess))
import System.Directory (getHomeDirectory)
import Data.List (intercalate)

main :: IO ()
main = do
    home <- getHomeDirectory
    let theme = home ++ "/.config/rofi/themes/modern.rasi"

    let options = [ "✨ Gemini"
                  , "🧠 Claude"
                  , "✖️ Grok"
                  , "💬 ChatGPT"
                  , "🔍 Perplexity"
                  , "🤖 GitHub Copilot"
                  ]
        inputStr = intercalate "\n" options

    (exitCode, out, _) <- readProcessWithExitCode "rofi" 
        [ "-dmenu"
        , "-i"
        , "-p", "🤖 AI"
        , "-l", show (length options)
        , "-theme", theme
        ] 
        inputStr

    if exitCode == ExitSuccess
        then do
            let selection = filter (/= '\n') out
            case selection of
                "✨ Gemini"         -> openUrl "https://gemini.google.com"
                "🧠 Claude"         -> openUrl "https://claude.ai"
                "✖️ Grok"           -> openUrl "https://x.com/i/grok"
                "💬 ChatGPT"        -> openUrl "https://chatgpt.com"
                "🔍 Perplexity"     -> openUrl "https://www.perplexity.ai"
                "🤖 GitHub Copilot" -> openUrl "https://github.com/copilot"
                _                   -> return ()
        else
            return ()

openUrl :: String -> IO ()
openUrl url = do
    _ <- spawnProcess "brave" ["--new-tab", url]
    return ()
