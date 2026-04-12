#!/usr/bin/env -S sh -c 'script_dir=$(dirname "$1"); exec runhaskell -i"$script_dir" -i"$script_dir/.." "$1" "$@"' sh
{-# LANGUAGE OverloadedStrings #-}

import System.Process (spawnCommand)
import System.Exit (exitSuccess)
import Control.Monad (void, unless)
import Data.List (isInfixOf)

import StandaloneUtils (notifySend, rofiLines, rofiSelection)

-- ==========================================
-- CONFIGURACIÓN DE COLORES Y ICONOS
-- ==========================================
colorAccent  = "#5292E2" -- Azul (Info/Arquitectura)
colorSuccess = "#85E89D" -- Verde (Testing/Refactor)
colorWarning = "#EBB461" -- Naranja (Review/Bugs)
colorDB      = "#B392F0" -- Morado (SQL/Data)
colorHint    = "#888888"

icArch   = "\xf0632" -- Arquitectura
icTest   = "\xf1be" -- Bug/Test
icReview = "\xf002" -- Lupa/Review
icDB     = "\xf1c0" -- Base de datos
icBack   = "\xf006e"

fmt :: String -> String -> String -> String
fmt col icon txt = "<span color='" ++ col ++ "'>" ++ icon ++ "</span>  <b>" ++ txt ++ "</b>"

-- ==========================================
-- PLANTILLAS XML DE INGENIERÍA DE SOFTWARE
-- ==========================================

-- 1. DISEÑO DE SISTEMA / ARQUITECTURA
promptArch :: String -> String
promptArch reqs = 
    "<prompt>\n\
    \  <role>Senior Software Architect</role>\n\
    \  <task>Diseñar una solución técnica escalable y mantenible.</task>\n\
    \  <requirements>" ++ reqs ++ "</requirements>\n\
    \  <constraints>\n\
    \    <constraint>Priorizar desacoplamiento y alta cohesión.</constraint>\n\
    \    <constraint>Usar patrones de diseño reconocidos (SOLID, Hexagonal, etc.).</constraint>\n\
    \  </constraints>\n\
    \  <output_format>\n\
    \    1. Diagrama de componentes (Mermaid).\n\
    \    2. Justificación de stack tecnológico.\n\
    \    3. Análisis de posibles cuellos de botella.\n\
    \  </output_format>\n\
    \</prompt>"

-- 2. GENERADOR DE UNIT TESTS (TDD)
promptTest :: String -> String
promptTest code = 
    "<prompt>\n\
    \  <role>QA Automation Engineer (Expert in Unit Testing)</role>\n\
    \  <action>Generar una suite de pruebas unitarias exhaustiva.</action>\n\
    \  <input_code>\n" ++ code ++ "\n  </input_code>\n\
    \  <goal>\n\
    \    Cubrir casos base, valores límite (edge cases) y escenarios de error.\n\
    \  </goal>\n\
    \  <instructions>\n\
    \    <instruction>Usa el framework estándar del lenguaje proporcionado.</instruction>\n\
    \    <instruction>Aplica el patrón AAA (Arrange, Act, Assert).</instruction>\n\
    \    <instruction>Mocotea (Mock) dependencias externas.</instruction>\n\
    \  </instructions>\n\
    \</prompt>"

-- 3. CODE REVIEW (SOLID & CLEAN CODE)
promptReview :: String -> String
promptReview code = 
    "<prompt>\n\
    \  <role>Senior Tech Lead (Code Reviewer)</role>\n\
    \  <task>Realizar un análisis crítico del código para mejorar su calidad.</task>\n\
    \  <code_to_review>\n" ++ code ++ "\n  </code_to_review>\n\
    \  <checkpoints>\n\
    \    <check>Principios SOLID y DRY.</check>\n\
    \    <check>Complejidad ciclomática y legibilidad.</check>\n\
    \    <check>Posibles vulnerabilidades de seguridad (OWASP).</check>\n\
    \  </checkpoints>\n\
    \  <output>Lista de hallazgos clasificados por severidad (Crítica, Media, Sugerencia).</output>\n\
    \</prompt>"

-- 4. OPTIMIZADOR DE SQL / DB
promptDB :: String -> String
promptDB sql = 
    "<prompt>\n\
    \  <role>Database Administrator (DBA Expert)</role>\n\
    \  <task>Optimizar la siguiente consulta o esquema de base de datos.</task>\n\
    \  <input_sql>" ++ sql ++ "</input_sql>\n\
    \  <analysis_steps>\n\
    \    <step>Identificar escaneos de tabla completa (Full Table Scans).</step>\n\
    \    <step>Sugerir índices necesarios.</step>\n\
    \    <step>Reescribir la consulta para mejorar el tiempo de ejecución.</step>\n\
    \  </analysis_steps>\n\
    \</prompt>"

notify urgency icon title msg = void $ spawnCommand $ "notify-send -u " ++ urgency ++ " -i " ++ icon ++ " '" ++ title ++ "' '" ++ msg ++ "'"

-- ==========================================
-- LÓGICA DE SELECCIÓN
-- ==========================================

mainMenu :: IO ()
mainMenu = do
    let options = [ fmt colorAccent  icArch   "System Architect (Diseño)"
                  , fmt colorSuccess icTest   "Unit Test Generator"
                  , fmt colorWarning icReview "Code Review (Clean Code)"
                  , fmt colorDB      icDB     "SQL/DB Optimizer"
                  ]
    selection <- rofiLines "hypr-prompt-main" "Software Engineering Toolbox" ["-i", "-markup-rows"] options
    
    if null selection then exitSuccess
    else if "Architect" `isInfixOf` selection then handlePrompt promptArch "Requisitos del sistema"
    else if "Unit Test" `isInfixOf` selection then handlePrompt promptTest "Pega el código para testear"
    else if "Code Review" `isInfixOf` selection then handlePrompt promptReview "Pega el código para revisar"
    else if "SQL" `isInfixOf` selection then handlePrompt promptDB "Pega el SQL o esquema"
    else exitSuccess

handlePrompt :: (String -> String) -> String -> IO ()
handlePrompt templateFunc inputLabel = do
    userInput <- rofiSelection "hypr-prompt-input" inputLabel ["-i"] ""
    unless (null userInput) $ do
        let finalPrompt = templateFunc userInput
        void $ spawnCommand $ "echo '" ++ escapeSingleQuotes finalPrompt ++ "' | wl-copy"
        notifySend ["-u", "normal", "-i", "edit-copy", "Copiado", "Prompt XML listo para pegar."]
    mainMenu

escapeSingleQuotes = concatMap (\c -> if c == '\'' then "'\\''" else [c])

main :: IO ()
main = mainMenu
