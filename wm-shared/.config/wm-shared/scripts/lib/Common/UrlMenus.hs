module Common.UrlMenus
    ( UrlEntry (..)
    , aiProviders
    , urlEntry
    , webBookmarks
    ) where

data UrlEntry = UrlEntry
    { urlEntryLabel :: String
    , urlEntryValue :: String
    }

urlEntry :: String -> String -> UrlEntry
urlEntry = UrlEntry

webBookmarks :: [UrlEntry]
webBookmarks =
    [ urlEntry "🔍 Google" "https://www.google.com"
    , urlEntry "📺 YouTube" "https://www.youtube.com"
    , urlEntry "🐦 X (Twitter)" "https://x.com"
    , urlEntry "👽 Reddit" "https://www.reddit.com"
    , urlEntry "🟢 WhatsApp" "https://web.whatsapp.com"
    , urlEntry "🐙 GitHub" "https://github.com"
    , urlEntry "📘 Facebook" "https://www.facebook.com"
    , urlEntry "🏔️  ArchWiki" "https://wiki.archlinux.org"
    , urlEntry "🔗 LinkedIn" "https://www.linkedin.com"
    , urlEntry "📚 Stack Overflow" "https://stackoverflow.com"
    , urlEntry "🧪 Hoogle (Haskell)" "https://hoogle.haskell.org"
    ]

aiProviders :: [UrlEntry]
aiProviders =
    [ urlEntry "✨ Gemini" "https://gemini.google.com"
    , urlEntry "🧠 Claude" "https://claude.ai"
    , urlEntry "✖️ Grok" "https://x.com/i/grok"
    , urlEntry "💬 ChatGPT" "https://chatgpt.com"
    , urlEntry "🔍 Perplexity" "https://www.perplexity.ai"
    , urlEntry "🤖 GitHub Copilot" "https://github.com/copilot"
    ]
