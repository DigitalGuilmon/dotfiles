module Scripts.Productivity.EmojiPicker (emojiPicker) where

import XMonad
import XMonad.Util.Run (runProcessWithInput)
import Variables (myThemeAbs)
import Scripts.Utils (shellEscape)

-- Lista de emojis frecuentes con descripción para búsqueda rápida
emojiList :: String
emojiList = unlines
    [ "😀 Sonrisa"
    , "😂 Risa"
    , "😍 Ojos de corazón"
    , "🤔 Pensando"
    , "👍 Pulgar arriba"
    , "👎 Pulgar abajo"
    , "❤️ Corazón rojo"
    , "🔥 Fuego"
    , "✅ Check verde"
    , "❌ Cruz roja"
    , "⭐ Estrella"
    , "🚀 Cohete"
    , "💻 Laptop"
    , "🐛 Bug"
    , "🔧 Llave inglesa"
    , "📝 Nota"
    , "📋 Clipboard"
    , "📁 Carpeta"
    , "🔍 Buscar"
    , "⚙️ Engranaje"
    , "🎉 Fiesta"
    , "💡 Idea"
    , "⚠️ Advertencia"
    , "🔒 Candado"
    , "🔑 Llave"
    , "📧 Email"
    , "🕐 Reloj"
    , "📊 Gráfico"
    , "🗑️ Basura"
    , "💾 Guardar"
    , "🖥️ Monitor"
    , "🎯 Diana"
    , "📌 Pin"
    , "🏷️ Etiqueta"
    , "🔗 Enlace"
    , "➡️ Flecha derecha"
    , "⬅️ Flecha izquierda"
    , "⬆️ Flecha arriba"
    , "⬇️ Flecha abajo"
    , "✨ Brillos"
    , "👀 Ojos"
    , "🙏 Manos juntas"
    , "💪 Fuerza"
    , "🎮 Control"
    , "🎵 Nota musical"
    , "☕ Café"
    , "🍕 Pizza"
    , "🐧 Pingüino Linux"
    , "🦊 Zorro"
    , "🤖 Robot"
    ]

-- Selector de emojis usando rofi: copia el emoji al clipboard con xclip
emojiPicker :: X ()
emojiPicker = do
    theme <- myThemeAbs
    selection <- runProcessWithInput "rofi"
        ["-dmenu", "-p", "Emoji:", "-theme", theme, "-i"] emojiList
    let res = filter (/= '\n') selection
    case res of
        "" -> return ()
        _  -> do
            -- Extraer solo el emoji (primer carácter/cluster antes del espacio)
            let emoji = takeWhile (/= ' ') res
            -- Usar xdotool para escribir directamente o xclip para copiar (seguro contra inyección)
            spawn $ "printf '%s' " ++ shellEscape emoji ++ " | xclip -selection clipboard && notify-send '📋 Emoji' 'Copiado al clipboard'"
