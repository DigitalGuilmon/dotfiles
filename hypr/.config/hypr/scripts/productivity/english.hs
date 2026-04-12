#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}

import System.Process (readProcessWithExitCode, spawnCommand, readCreateProcess, shell)
import System.Exit (exitSuccess, ExitCode(..))
import System.Directory (getHomeDirectory)
import Control.Exception (catch, IOException)
import Control.Monad (void, unless)
import Data.Char (isSpace)
import Data.List (dropWhileEnd, isPrefixOf)

-- ==========================================
-- CONFIGURACIÓN E ICONOS
-- ==========================================

icGlobe     = "\xf0ac"   -- Mundo
icDict      = "\xf02d"   -- Diccionario
icEnEs      = "\xf0524"  -- Traducir EN -> ES
icEsEn      = "\xf0525"  -- Traducir ES -> EN
icSound     = "\xf028"   -- Sonido
icBack      = "\xf006e"

-- ==========================================
-- HELPERS DE SISTEMA
-- ==========================================

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace

rofi :: String -> String -> String -> IO String
rofi menuId prompt opts = do
    home <- getHomeDirectory
    let theme = home ++ "/.config/rofi/themes/modern.rasi"
        helper = home ++ "/.config/rofi/scripts/frequent-menu.py"
    (exitCode, out, _) <- catch (readProcessWithExitCode helper ["--menu-id", menuId, "--prompt", prompt, "--theme", theme, "--", "-i"] opts)
                                (\(_ :: IOException) -> return (ExitFailure 1, "", ""))
    return $ trim out

notify :: String -> String -> IO ()
notify title msg = void $ spawnCommand $ "notify-send -u normal -a 'English Live' '" ++ title ++ "' '" ++ msg ++ "'"

queryShell :: String -> IO String
queryShell cmd = catch (readCreateProcess (shell cmd) "") (\(_ :: IOException) -> return "")

-- ==========================================
-- LÓGICA DE TRADUCCIÓN BIDIRECCIONAL
-- ==========================================

translationMenu :: IO ()
translationMenu = do
    let options = [ (icEnEs ++ " Inglés -> Español", performTranslation "en|es" "English to Spanish")
                  , (icEsEn ++ " Español -> Inglés", performTranslation "es|en" "Español a Inglés")
                  , (icBack ++ " Volver", mainMenu)
                  ]
    let optsStr = unlines $ map fst options
    selection <- rofi "hypr-english-translation-menu" "Traductor" optsStr
    case lookup selection options of
        Just action -> action
        Nothing     -> mainMenu

performTranslation :: String -> String -> IO ()
performTranslation langPair promptStr = do
    query <- rofi "hypr-english-translation-input" promptStr ""
    unless (null query) $ do
        -- Usamos --data-urlencode para que curl maneje automáticamente espacios y símbolos
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
    word <- rofi "hypr-english-pronounce-input" "Escuchar pronunciación (EN)" ""
    unless (null word) $ do
        -- Detecta automáticamente si necesitas mpv o vlc
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
    let optsStr = unlines $ map fst options
    selection <- rofi "hypr-english-main" "English Live Tutor" optsStr
    case lookup selection options of
        Just action -> action
        Nothing     -> exitSuccess

interactiveSearch :: IO ()
interactiveSearch = do
    word <- rofi "hypr-english-dictionary-input" "Introduce palabra en Inglés" ""
    unless (null word) $ fetchDefinition (trim word)
