#!/usr/bin/env sh
#if 0
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
script_root="$script_dir"
while [ ! -d "$script_root/lib" ] && [ "$script_root" != "/" ]; do
    script_root=$(dirname "$script_root")
done
exec runhaskell -XCPP -i"$script_root/lib" "$0" "$@"
#endif
{-# LANGUAGE OverloadedStrings #-}

import System.Process (spawnCommand, readCreateProcess, shell)
import Control.Exception (IOException, try)
import Control.Monad (void, unless)
import Data.List (isPrefixOf)

import Standalone.Menu (MenuSpec (..), menuEntry, runMenuSpec)
import StandaloneUtils (notifySend, rofiSelection, trim)

-- ==========================================
-- CONFIGURACIÓN E ICONOS
-- ==========================================

icGlobe     = "\xf0ac"   -- Mundo
icDict      = "\xf02d"   -- Diccionario
icEnEs      = "\xf0524"  -- Traducir EN -> ES
icEsEn      = "\xf0525"  -- Traducir ES -> EN
icSound     = "\xf028"   -- Sonido
icBack      = "\xf006e"

data TranslationDirection = TranslationDirection
    { directionLangPair :: String
    , directionPrompt :: String
    , directionLabel :: String
    }

translationDirections :: [TranslationDirection]
translationDirections =
    [ TranslationDirection "en|es" "English to Spanish" (icEnEs ++ " Inglés -> Español")
    , TranslationDirection "es|en" "Español a Inglés" (icEsEn ++ " Español -> Inglés")
    ]

notify :: String -> String -> IO ()
notify title msg = notifySend ["-u", "normal", "-a", "English Live", title, msg]

queryShell :: String -> IO String
queryShell cmd = do
    result <- try (readCreateProcess (shell cmd) "") :: IO (Either IOException String)
    pure $ either (const "") id result

-- ==========================================
-- LÓGICA DE TRADUCCIÓN BIDIRECCIONAL
-- ==========================================

translationMenu :: IO ()
translationMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "hypr-english-translation-menu"
            , menuSpecPrompt = "Traductor"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                map (\direction -> menuEntry (directionLabel direction) (performTranslation (directionLangPair direction) (directionPrompt direction))) translationDirections
                    ++ [menuEntry (icBack ++ " Volver") mainMenu]
            }

performTranslation :: String -> String -> IO ()
performTranslation langPair promptStr = do
    query <- rofiSelection "hypr-english-translation-input" promptStr ["-i"] ""
    unless (null query) $ do
        let baseUrl = "https://api.mymemory.translated.net/get"
        let cmd = "curl -s -G \"" ++ baseUrl ++ "\" --data-urlencode \"q=" ++ query ++ "\" --data-urlencode \"langpair=" ++ langPair ++ "\" | jq -r '.responseData.translatedText'"
        
        res <- queryShell cmd
        if null res || res == "null"
            then notify "Error" "No se pudo conectar con el servicio de traducción."
            else notify "Traducción" (query ++ " -> " ++ res)
    translationMenu

-- ==========================================
-- DICCIONARIO Y PALABRA ALEATORIA
-- ==========================================

getWordOfTheDay :: IO ()
getWordOfTheDay = do
    notify "Internet" "Buscando palabra nueva..."
    word <- queryShell "curl -s https://random-word-api.herokuapp.com/word?number=1 | jq -r '.[0]'"
    unless (null word) $ fetchDefinition (trim word)

fetchDefinition :: String -> IO ()
fetchDefinition word = do
    let apiUrl = "https://api.dictionaryapi.dev/api/v2/entries/en/" ++ word
    let jqCmd = "jq -r '.[0].meanings[0].definitions[0] | \"Def: \\(.definition)\\n\\nEx: \\(.example // \"N/A\")\"'"
    
    result <- queryShell $ "curl -s " ++ apiUrl ++ " | " ++ jqCmd
    
    if "null" `isPrefixOf` result || null result
        then notify "Error" ("No se encontró definición para: " ++ word)
        else notify ("English: " ++ word) result
    mainMenu

-- ==========================================
-- PRONUNCIACIÓN (TTS)
-- ==========================================

pronounce :: IO ()
pronounce = do
    word <- rofiSelection "hypr-english-pronounce-input" "Escuchar pronunciación (EN)" ["-i"] ""
    unless (null word) $ do
        void $ spawnCommand $ "mpv --no-terminal \"https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&q=" ++ word ++ "&tl=en\""
    mainMenu

-- ==========================================
-- MENÚ PRINCIPAL
-- ==========================================

main :: IO ()
main = mainMenu

mainMenu :: IO ()
mainMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "hypr-english-main"
            , menuSpecPrompt = "English Live Tutor"
            , menuSpecArgs = ["-i"]
            , menuSpecEntries =
                [ menuEntry (icGlobe ++ " Palabra Aleatoria (Live)") getWordOfTheDay
                , menuEntry (icDict ++ " Definición (Diccionario)") interactiveSearch
                , menuEntry (icEnEs ++ " Traductor Bidireccional") translationMenu
                , menuEntry (icSound ++ " Escuchar pronunciación") pronounce
                ]
            }

interactiveSearch :: IO ()
interactiveSearch = do
    word <- rofiSelection "hypr-english-dictionary-input" "Introduce palabra en Inglés" ["-i"] ""
    unless (null word) $ fetchDefinition (trim word)
