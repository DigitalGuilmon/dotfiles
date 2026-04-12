#!/usr/bin/env -S sh -c 'script_dir=$(dirname "$1"); exec runhaskell -i"$script_dir" -i"$script_dir/.." "$1" "$@"' sh

import System.Process (spawnProcess)

import StandaloneUtils (rofiLines)

main :: IO ()
main = do
    let options = [ "✨ Gemini"
                  , "🧠 Claude"
                  , "✖️ Grok"
                  , "💬 ChatGPT"
                  , "🔍 Perplexity"
                  , "🤖 GitHub Copilot"
                  ]
    selection <- rofiLines "hypr-ai-menu" "🤖 AI" ["-i", "-l", show (length options)] options
    case selection of
        "✨ Gemini"         -> openUrl "https://gemini.google.com"
        "🧠 Claude"         -> openUrl "https://claude.ai"
        "✖️ Grok"           -> openUrl "https://x.com/i/grok"
        "💬 ChatGPT"        -> openUrl "https://chatgpt.com"
        "🔍 Perplexity"     -> openUrl "https://www.perplexity.ai"
        "🤖 GitHub Copilot" -> openUrl "https://github.com/copilot"
        _                   -> return ()

openUrl :: String -> IO ()
openUrl url = do
    _ <- spawnProcess "brave" ["--new-tab", url]
    return ()
