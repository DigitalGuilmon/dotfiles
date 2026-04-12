#!/usr/bin/env -S sh -c 'script_dir=$(dirname "$1"); exec runhaskell -i"$script_dir" -i"$script_dir/.." "$1" "$@"' sh
{-# LANGUAGE OverloadedStrings #-}

import System.Process (spawnCommand, readCreateProcess, shell)
import System.Exit (exitSuccess)
import Control.Exception (IOException, try)
import Control.Monad (void, unless)
import Data.List (isPrefixOf)

import StandaloneUtils (notifySend, rofiLines, rofiSelection, trim)

-- ==========================================
-- CONFIGURACIÓN E ICONOS
-- ==========================================

icGlobe     = "\xf0ac"   -- Mundo
icDict      = "\xf02d"   -- Diccionario
icEnEs      = "\xf0524"  -- Traducir EN -> ES
icEsEn      = "\xf0525"  -- Traducir ES -> EN
icSound     = "\xf028"   -- Sonido
icBack      = "\xf006e"

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
translationMenu = do
    let options = [ (icEnEs ++ " Inglés -> Español", performTranslation "en|es" "English to Spanish")
                  , (icEsEn ++ " Español -> Inglés", performTranslation "es|en" "Español a Inglés")
                  , (icBack ++ " Volver", mainMenu)
                  ]
    selection <- rofiLines "hypr-english-translation-menu" "Traductor" ["-i"] (map fst options)
    case lookup selection options of
        Just action -> action
        Nothing     -> mainMenu

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
mainMenu = do
    let options = [ (icGlobe ++ " Palabra Aleatoria (Live)", getWordOfTheDay)
                  , (icDict  ++ " Definición (Diccionario)",  interactiveSearch)
                  , (icEnEs  ++ " Traductor Bidireccional",  translationMenu)
                  , (icSound ++ " Escuchar pronunciación", pronounce)
                  ]
    selection <- rofiLines "hypr-english-main" "English Live Tutor" ["-i"] (map fst options)
    case lookup selection options of
        Just action -> action
        Nothing     -> exitSuccess

interactiveSearch :: IO ()
interactiveSearch = do
    word <- rofiSelection "hypr-english-dictionary-input" "Introduce palabra en Inglés" ["-i"] ""
    unless (null word) $ fetchDefinition (trim word)
