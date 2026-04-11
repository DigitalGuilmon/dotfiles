#!/usr/bin/env sh
#if 0
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
script_root="$script_dir"
while [ ! -d "$script_root/lib" ] && [ "$script_root" != "/" ]; do
    script_root=$(dirname "$script_root")
done
exec runhaskell -XCPP -i"$script_root/lib" "$0" "$@"
#endif

import Control.Exception (IOException, try)
import Control.Monad (unless, when)
import Data.List (intercalate, isSuffixOf)
import Data.Maybe (catMaybes, fromMaybe)
import System.Directory
    ( createDirectoryIfMissing
    , doesDirectoryExist
    , doesFileExist
    , findExecutable
    , getHomeDirectory
    , listDirectory
    )
import System.Exit (ExitCode (ExitSuccess))
import System.FilePath ((</>), takeBaseName, takeDirectory)
import System.Process (readProcessWithExitCode)

import Common.PromptDSL
    ( ContextArtifact (..)
    , ContextSource (..)
    , ImportSpec (..)
    , NamedSection (..)
    , PromptDepth (..)
    , PromptDoc (..)
    , PromptDocKind (..)
    , PromptFormat (..)
    , PromptLanguage (..)
    , asSubprompt
    , compilePromptDoc
    , contextSourceLabel
    , depthLabel
    , emptyPromptDoc
    , formatLabel
    , languageLabel
    , mergePromptDocs
    , parsePromptDoc
    , renderPromptDocAs
    , serializePromptDoc
    , validatePromptDoc
    )
import Common.Text (trimWhitespace)
import Common.UrlMenus (UrlEntry (..), aiProviders)
import Standalone.Menu (MenuSpec (..), menuEntry, runMenuSpec, selectMenuSpec)
import Standalone.Runtime (notify, openUrl)
import StandaloneUtils (currentTimestamp, notifySend, openBrowserUrl, rofiSelection)

data PromptTemplate = PromptTemplate
    { templateId :: String
    , templateLabel :: String
    , templateRole :: String
    , templateTask :: String
    , templateObjectivePrompt :: String
    , templateContextPrompt :: String
    , templateContextKind :: String
    , templateInstructions :: [String]
    , templateDeliverables :: [String]
    , templateChecklist :: [String]
    , templateQualityBar :: [String]
    }

data SelectionAction a
    = SelectItem a
    | SelectDone
    | SelectReset

data SavedPrompt = SavedPrompt
    { savedPromptPath :: FilePath
    , savedPromptDoc :: PromptDoc
    }

iconClipboard, iconManual, iconSkip, iconPrompt, iconAi, iconXml, iconMd, iconSave, iconFolder :: String
iconClipboard = "\xf014c"
iconManual = "\xf040"
iconSkip = "\xf05e0"
iconPrompt = "\xf0eb"
iconAi = "\xf109"
iconXml = "\xf05c0"
iconMd = "\xf0354"
iconSave = "\xf0193"
iconFolder = "\xf0214"

contextLimit :: Int
contextLimit = 12000

templates :: [PromptTemplate]
templates =
    [ PromptTemplate
        { templateId = "architecture"
        , templateLabel = "\xf0632  Arquitectura y diseno"
        , templateRole = "Principal Software Architect"
        , templateTask = "Disena una solucion tecnica escalable, mantenible y operable."
        , templateObjectivePrompt = "Que sistema o decision quieres disenar"
        , templateContextPrompt = "Requisitos, dominio, restricciones o contexto actual"
        , templateContextKind = "requirements"
        , templateInstructions =
            [ "Identifica objetivos, restricciones y riesgos antes de proponer la solucion."
            , "Separa claramente componentes, limites, flujos de datos e integraciones."
            , "Justifica trade-offs y explica por que la propuesta es mantenible y escalable."
            , "Evita inventar detalles: declara supuestos cuando falte informacion."
            ]
        , templateDeliverables =
            [ "Propuesta de arquitectura con modulos y responsabilidades."
            , "Diagrama Mermaid o esquema equivalente."
            , "Decisiones tecnicas, trade-offs y riesgos operativos."
            , "Plan de implementacion incremental o roadmap tecnico."
            ]
        , templateChecklist =
            [ "Boundaries y ownership de cada componente."
            , "Escalabilidad, resiliencia y observabilidad."
            , "Integraciones, dependencias externas y puntos de fallo."
            , "Riesgos de complejidad, latencia y coste."
            ]
        , templateQualityBar =
            [ "La propuesta debe poder implementarse por fases."
            , "Cada decision importante debe estar justificada."
            , "Los riesgos deben venir acompanados de mitigaciones."
            ]
        }
    , PromptTemplate
        { templateId = "implementation"
        , templateLabel = "\xf0ad  Implementacion de feature"
        , templateRole = "Staff Software Engineer"
        , templateTask = "Propone e implementa un cambio tecnico de forma clara, segura y mantenible."
        , templateObjectivePrompt = "Que feature, flujo o cambio quieres implementar"
        , templateContextPrompt = "Historia de usuario, codigo existente, API o comportamiento deseado"
        , templateContextKind = "code"
        , templateInstructions =
            [ "Descompone el trabajo en pasos ejecutables y dependencias."
            , "Propone la solucion mas simple que cubra el caso real sin perder mantenibilidad."
            , "Si hay codigo, respeta estilo, nombres y patrones del contexto dado."
            , "Incluye validaciones, errores y consideraciones de testing."
            ]
        , templateDeliverables =
            [ "Enfoque tecnico y plan de implementacion."
            , "Codigo o pseudocodigo listo para adaptar."
            , "Cambios necesarios en tests, config y migraciones si aplican."
            , "Riesgos de integracion y puntos a validar."
            ]
        , templateChecklist =
            [ "Cobertura de edge cases y errores."
            , "Compatibilidad con el codigo existente."
            , "Manejo de dependencias, config y migraciones."
            , "Plan de verificacion o testing."
            ]
        , templateQualityBar =
            [ "La solucion debe ser concreta y aterrizada al contexto."
            , "No debe depender de supuestos ocultos."
            , "Debe indicar impactos colaterales del cambio."
            ]
        }
    , PromptTemplate
        { templateId = "debugging"
        , templateLabel = "\xf188  Debug y root cause"
        , templateRole = "Senior Debugging Engineer"
        , templateTask = "Diagnostica la causa raiz de un problema y propone una correccion fiable."
        , templateObjectivePrompt = "Que bug, error o comportamiento extrano quieres resolver"
        , templateContextPrompt = "Stack trace, logs, sintomas, pasos de reproduccion o codigo implicado"
        , templateContextKind = "debug-artifact"
        , templateInstructions =
            [ "Prioriza la causa raiz por encima de los sintomas."
            , "Formula hipotesis ordenadas por probabilidad e impacto."
            , "Propone pasos concretos de diagnostico antes de tocar codigo si hace falta evidencia."
            , "Sugiere una correccion con prevencion de regresiones."
            ]
        , templateDeliverables =
            [ "Hipotesis de causa raiz con razonamiento."
            , "Plan de diagnostico o reproduccion."
            , "Fix propuesto con cambios concretos."
            , "Medidas para evitar que el bug reaparezca."
            ]
        , templateChecklist =
            [ "Sintoma observable versus causa subyacente."
            , "Condiciones de reproduccion y variables relevantes."
            , "Evidencia requerida para confirmar o descartar hipotesis."
            , "Riesgo de regresiones al aplicar el fix."
            ]
        , templateQualityBar =
            [ "No confundas correlacion con causa raiz."
            , "Cada hipotesis debe tener una prueba o indicio asociado."
            , "La solucion debe reducir la probabilidad de reaparicion."
            ]
        }
    , PromptTemplate
        { templateId = "refactor"
        , templateLabel = "\xf021e  Refactor y clean up"
        , templateRole = "Senior Refactoring Specialist"
        , templateTask = "Mejora la estructura del codigo preservando el comportamiento esperado."
        , templateObjectivePrompt = "Que modulo, clase o flujo quieres refactorizar"
        , templateContextPrompt = "Codigo actual, smells detectados y restricciones de compatibilidad"
        , templateContextKind = "code"
        , templateInstructions =
            [ "Conserva el comportamiento y la semantica salvo que se indique lo contrario."
            , "Detecta duplicacion, complejidad innecesaria, acoplamiento y nombres pobres."
            , "Propone refactors pequenos, seguros y faciles de revisar."
            , "Aclara que test o verificaciones deben acompanar el cambio."
            ]
        , templateDeliverables =
            [ "Diagnostico de problemas estructurales."
            , "Plan de refactor paso a paso."
            , "Version mejorada del codigo o esquema de cambios."
            , "Checklist de seguridad funcional despues del refactor."
            ]
        , templateChecklist =
            [ "Duplicacion y puntos de acoplamiento."
            , "Legibilidad, nombres y responsabilidades."
            , "Riesgo de romper contratos publicos."
            , "Estrategia de refactor incremental."
            ]
        , templateQualityBar =
            [ "El refactor debe ser revisable y seguro."
            , "Debe preservar comportamiento salvo que se indique lo contrario."
            , "Debe aclarar como validar que no hubo regresiones."
            ]
        }
    , PromptTemplate
        { templateId = "review"
        , templateLabel = "\xf002  Code review de alto nivel"
        , templateRole = "Principal Code Reviewer"
        , templateTask = "Realiza una revision tecnica de alto valor centrada en defectos reales."
        , templateObjectivePrompt = "Que cambio quieres revisar"
        , templateContextPrompt = "Diff, archivo, modulo, PR o fragmento de codigo"
        , templateContextKind = "diff"
        , templateInstructions =
            [ "Senala solo problemas reales: bugs, seguridad, deuda importante y riesgo de mantenimiento."
            , "Clasifica los hallazgos por severidad y explica impacto."
            , "No pierdas tiempo en estilo superficial salvo que afecte claridad o defectos."
            , "Para cada issue, sugiere correccion concreta."
            ]
        , templateDeliverables =
            [ "Lista priorizada de hallazgos."
            , "Explicacion breve del impacto de cada hallazgo."
            , "Sugerencias o patch guidance para corregirlos."
            ]
        , templateChecklist =
            [ "Errores logicos o casos no cubiertos."
            , "Riesgos de seguridad, concurrencia o datos."
            , "Problemas de mantenibilidad con impacto real."
            , "Inconsistencias entre intencion y comportamiento."
            ]
        , templateQualityBar =
            [ "No senales nitpicks sin valor."
            , "Cada hallazgo debe incluir impacto y arreglo sugerido."
            , "Prioriza severidad y accionabilidad."
            ]
        }
    , PromptTemplate
        { templateId = "testing"
        , templateLabel = "\xf1c3  Testing y cobertura"
        , templateRole = "Senior QA Automation Engineer"
        , templateTask = "Disena una estrategia de pruebas y casos relevantes para el contexto dado."
        , templateObjectivePrompt = "Que codigo o comportamiento necesitas cubrir con tests"
        , templateContextPrompt = "Codigo, contrato, casos esperados, edge cases o dependencias externas"
        , templateContextKind = "test-target"
        , templateInstructions =
            [ "Cubre camino feliz, bordes, errores y regresiones probables."
            , "Explica que test unitarios, de integracion o e2e aportan mas valor."
            , "Mocotea o aisla dependencias externas cuando convenga."
            , "Si faltan invariantes o contratos, explicitalos antes de proponer tests."
            ]
        , templateDeliverables =
            [ "Plan de pruebas por capas."
            , "Casos concretos con Arrange/Act/Assert o equivalente."
            , "Manejo de mocks, fixtures y datos de prueba."
            , "Huecos de cobertura y riesgos remanentes."
            ]
        , templateChecklist =
            [ "Cobertura de casos felices y edge cases."
            , "Errores, timeouts y respuestas inesperadas."
            , "Dependencias externas, fixtures y mocks."
            , "Regresiones historicamente probables."
            ]
        , templateQualityBar =
            [ "Los tests propuestos deben tener valor real, no solo volumen."
            , "Los casos deben ser concretos y verificables."
            , "Debe quedar claro que capa de testing conviene a cada caso."
            ]
        }
    , PromptTemplate
        { templateId = "security"
        , templateLabel = "\xf13d  Security review"
        , templateRole = "Application Security Engineer"
        , templateTask = "Audita el contexto tecnico buscando vulnerabilidades y mitigaciones concretas."
        , templateObjectivePrompt = "Que flujo, endpoint o codigo quieres auditar"
        , templateContextPrompt = "Codigo, arquitectura, endpoints, auth, datos sensibles o amenazas"
        , templateContextKind = "security-scope"
        , templateInstructions =
            [ "Analiza superficie de ataque, trust boundaries y manejo de datos."
            , "Prioriza vulnerabilidades explotables y configuraciones peligrosas."
            , "Relaciona cada hallazgo con impacto y remediacion concreta."
            , "Evita recomendaciones vagas: aterriza cambios tecnicos aplicables."
            ]
        , templateDeliverables =
            [ "Lista de riesgos y vulnerabilidades por severidad."
            , "Escenarios de explotacion plausibles."
            , "Mitigaciones concretas y cambios recomendados."
            , "Buenas practicas faltantes y controles defensivos."
            ]
        , templateChecklist =
            [ "Autenticacion, autorizacion y trust boundaries."
            , "Exposicion de datos, secretos o PII."
            , "Validacion de entradas y abuso de APIs."
            , "Logging, observabilidad y controles defensivos."
            ]
        , templateQualityBar =
            [ "Prioriza hallazgos explotables."
            , "Cada vulnerabilidad debe incluir impacto y mitigacion."
            , "No inventes amenazas sin soporte en el contexto."
            ]
        }
    , PromptTemplate
        { templateId = "sql"
        , templateLabel = "\xf1c0  SQL y datos"
        , templateRole = "Senior DBA and Data Engineer"
        , templateTask = "Optimiza consultas o modelos de datos con foco en rendimiento y claridad operativa."
        , templateObjectivePrompt = "Que consulta, modelo o problema de datos quieres optimizar"
        , templateContextPrompt = "SQL, esquema, explain plan, volumen de datos o sintomas de rendimiento"
        , templateContextKind = "sql"
        , templateInstructions =
            [ "Analiza costo, selectividad, indices, joins y cardinalidad."
            , "Diferencia optimizaciones de consulta frente a cambios de esquema."
            , "Justifica por que cada cambio mejoraria rendimiento o mantenibilidad."
            , "Si faltan datos del plan de ejecucion, indica que medir."
            ]
        , templateDeliverables =
            [ "Diagnostico del cuello de botella."
            , "Consulta reescrita o cambios de esquema sugeridos."
            , "Indices y metricas a validar."
            , "Trade-offs de consistencia, coste y complejidad."
            ]
        , templateChecklist =
            [ "Filtros, joins, agrupaciones y ordenamientos costosos."
            , "Indices faltantes o sobredimensionados."
            , "Cardinalidad y planes de ejecucion."
            , "Impacto en escritura, almacenamiento y mantenimiento."
            ]
        , templateQualityBar =
            [ "Cada optimizacion debe venir con razon tecnica."
            , "Distingue claramente quick wins y cambios estructurales."
            , "Indica como validar mejora real."
            ]
        }
    , PromptTemplate
        { templateId = "docs"
        , templateLabel = "\xf02d  Documentacion y handoff"
        , templateRole = "Senior Technical Writer for Engineering"
        , templateTask = "Convierte contexto tecnico disperso en documentacion clara y accionable."
        , templateObjectivePrompt = "Que documento o explicacion necesitas producir"
        , templateContextPrompt = "Feature, modulo, notas sueltas, decisiones o codigo fuente"
        , templateContextKind = "documentation-source"
        , templateInstructions =
            [ "Convierte conocimiento disperso en una explicacion clara y accionable."
            , "Adapta la estructura al lector: equipo tecnico, reviewer o usuario interno."
            , "Destaca decisiones, pasos de uso, limitaciones y ejemplos."
            , "No inventes comportamientos no sustentados por el contexto."
            ]
        , templateDeliverables =
            [ "Documento estructurado y facil de escanear."
            , "Resumen ejecutivo o contextual."
            , "Pasos de uso, ejemplos y notas operativas."
            , "Pendientes o dudas abiertas si falta informacion."
            ]
        , templateChecklist =
            [ "Lectores objetivo y nivel de detalle."
            , "Flujos, ejemplos y precondiciones."
            , "Limitaciones y decisiones clave."
            , "Huecos de informacion pendientes."
            ]
        , templateQualityBar =
            [ "Debe poder usarse como handoff real."
            , "La estructura debe ser facil de escanear."
            , "No debe afirmar nada no soportado por el contexto."
            ]
        }
    ]

main :: IO ()
main = ensurePromptLibrarySeeded >> mainMenu

mainMenu :: IO ()
mainMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "wm-shared-prompt-main"
            , menuSpecPrompt = "Prompt Lab PDSL"
            , menuSpecArgs = ["-i", "-l", "8"]
            , menuSpecEntries =
                [ menuEntry (iconPrompt ++ "  Crear prompt compuesto") runPromptComposer
                , menuEntry (iconFolder ++ "  Abrir carpeta de subprompts") (openPromptFolder "subprompts")
                , menuEntry (iconFolder ++ "  Abrir carpeta de builds") (openPromptFolder "builds")
                , menuEntry (iconAi ++ "  Abrir proveedor IA") openAiProviderMenu
                ]
            }

runPromptComposer :: IO ()
runPromptComposer = do
    selectedTemplates <- selectTemplates
    if null selectedTemplates
        then mainMenu
        else do
            selectedSubprompts <- selectSavedSubprompts
            buildNameInput <- promptOptional "wm-shared-prompt-build-name" "Nombre del prompt o build" "Se usara para el .pdsl y para identificar el prompt."
            timestamp <- currentTimestamp "%Y%m%d-%H%M%S" "build"
            let buildName = fromMaybe ("prompt-" ++ timestamp) buildNameInput
                objectivePrompt = objectiveLabel selectedTemplates
                contextPrompt = contextLabel selectedTemplates
            objective <- promptRequired "wm-shared-prompt-objective" objectivePrompt "Describe con precision el resultado que quieres del modelo."
            case objective of
                Nothing -> mainMenu
                Just finalObjective -> do
                    source <- chooseContextSource "wm-shared-prompt-context-source"
                    case source of
                        Nothing -> mainMenu
                        Just contextSource -> do
                            context <- gatherContext "wm-shared-prompt-context" contextPrompt contextSource
                            stack <- promptOptional "wm-shared-prompt-stack" "Lenguaje / stack / framework (opcional)" "Ejemplo: Haskell + Rofi + Hyprland, Python 3.12 + FastAPI."
                            constraints <- promptOptional "wm-shared-prompt-constraints" "Restricciones / criterios extra (opcional)" "Performance, estilo, UX, compatibilidad, limite de riesgo, etc."
                            language <- chooseLanguage "wm-shared-prompt-language"
                            depth <- chooseDepth "wm-shared-prompt-depth"
                            let finalDoc = buildPromptDoc buildName language depth finalObjective stack constraints contextSource context selectedTemplates (map savedPromptDoc selectedSubprompts)
                            compileAndPublish finalDoc

selectTemplates :: IO [PromptTemplate]
selectTemplates = loop []
  where
    loop selected = do
        let remaining = filter (\template -> templateId template `notElem` map templateId selected) templates
            entries =
                map (\template -> menuEntry (templateLabel template) (SelectItem template)) remaining
                    ++ [menuEntry (iconPrompt ++ "  Continuar (" ++ show (length selected) ++ ")") SelectDone]
                    ++ if null selected
                        then []
                        else [menuEntry (iconSkip ++ "  Limpiar seleccion") SelectReset]
        action <-
            selectMenuSpec $
                MenuSpec
                    { menuSpecId = "wm-shared-prompt-template-select"
                    , menuSpecPrompt = "Plantillas base"
                    , menuSpecArgs = ["-i", "-l", "12"]
                    , menuSpecEntries = entries
                    }
        case action of
            Nothing -> pure selected
            Just SelectDone ->
                if null selected
                    then do
                        notify "normal" "Prompt Lab" "Selecciona al menos una plantilla base."
                        loop selected
                    else pure selected
            Just SelectReset -> loop []
            Just (SelectItem template) -> loop (selected ++ [template])

selectSavedSubprompts :: IO [SavedPrompt]
selectSavedSubprompts = do
    available <- loadSavedSubprompts
    if null available
        then pure []
        else loop available []
  where
    loop available selected = do
        let remaining = filter (\promptValue -> savedPromptPath promptValue `notElem` map savedPromptPath selected) available
            entries =
                map (\promptValue -> menuEntry (savedPromptLabel promptValue) (SelectItem promptValue)) remaining
                    ++ [menuEntry (iconPrompt ++ "  Continuar (" ++ show (length selected) ++ ")") SelectDone]
                    ++ if null selected
                        then []
                        else [menuEntry (iconSkip ++ "  Limpiar seleccion") SelectReset]
        action <-
            selectMenuSpec $
                MenuSpec
                    { menuSpecId = "wm-shared-prompt-subprompt-select"
                    , menuSpecPrompt = "Subprompts guardados (opcional)"
                    , menuSpecArgs = ["-i", "-l", "12"]
                    , menuSpecEntries = entries
                    }
        case action of
            Nothing -> pure selected
            Just SelectDone -> pure selected
            Just SelectReset -> loop available []
            Just (SelectItem promptValue) -> loop available (selected ++ [promptValue])

buildPromptDoc :: String -> PromptLanguage -> PromptDepth -> String -> Maybe String -> Maybe String -> ContextSource -> Maybe String -> [PromptTemplate] -> [PromptDoc] -> PromptDoc
buildPromptDoc buildName language depth objective stack constraints contextSource context selectedTemplates selectedSubprompts =
    mergePromptDocs rootDoc (map templateDoc selectedTemplates ++ selectedSubprompts)
  where
    rootDoc =
        emptyPromptDoc
            { docKind = FinalPrompt
            , docName = buildName
            , docFormat = FormatPDSL
            , docLanguage = language
            , docDepth = depth
            , docObjective = Just objective
            , docSections =
                catMaybes
                    [ fmap (NamedSection "stack") stack
                    , fmap (NamedSection "constraints") constraints
                    ]
            , docContextArtifacts =
                maybe
                    []
                    (\value -> [ContextArtifact "global-context" contextSource value])
                    context
            , docResponseRules =
                [ "Responde en " ++ languageLabel language ++ "."
                , responseDepthRule depth
                , "Empieza aclarando supuestos si falta informacion critica."
                , "Adapta la respuesta al objetivo y al contexto; evita relleno generico."
                , "Prioriza artefactos reutilizables: pasos, codigo, decisiones, tablas o checklists cuando aporten claridad."
                ]
            }
    templateDoc template =
        emptyPromptDoc
            { docKind = SavedSubprompt
            , docName = templateId template
            , docFormat = FormatPDSL
            , docLanguage = language
            , docDepth = depth
            , docRoles = [templateRole template]
            , docTasks = [templateTask template]
            , docSections = [NamedSection "template_origin" (templateId template)]
            , docInstructions = templateInstructions template
            , docDeliverables = templateDeliverables template
            , docChecklist = templateChecklist template
            , docQualityBar = templateQualityBar template
            }

compileAndPublish :: PromptDoc -> IO ()
compileAndPublish doc = do
    buildPath <- buildArtifactPath (docName doc)
    let serialized = serializePromptDoc doc
    writeTextFile buildPath serialized
    compiled <- compileSavedArtifact buildPath
    case compiled of
        Left errors -> notify "critical" "Prompt Lab" ("PDSL invalido: " ++ intercalate " | " errors)
        Right (compiledDoc, _) -> do
            notifySend
                [ "-u"
                , "normal"
                , "-i"
                , "document-save"
                , "Build PDSL validado"
                , "Fuente de verdad guardada en: " ++ buildPath
                ]
            postGenerationMenu compiledDoc buildPath

postGenerationMenu :: PromptDoc -> FilePath -> IO ()
postGenerationMenu doc buildPath =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "wm-shared-prompt-post"
            , menuSpecPrompt = "Build PDSL listo"
            , menuSpecArgs = ["-i", "-l", "10"]
            , menuSpecEntries =
                [ menuEntry (iconXml ++ "  Compilar y copiar XML") (copyRenderedPrompt doc FormatXml)
                , menuEntry (iconMd ++ "  Compilar y copiar Markdown") (copyRenderedPrompt doc FormatMarkdown)
                , menuEntry (iconPrompt ++ "  Compilar y copiar Hibrido") (copyRenderedPrompt doc FormatHybrid)
                , menuEntry (iconPrompt ++ "  Copiar PDSL fuente") (copyRenderedPrompt doc FormatPDSL)
                , menuEntry (iconPrompt ++ "  Listo") (pure ())
                , menuEntry (iconPrompt ++ "  Crear otro prompt") mainMenu
                , menuEntry (iconSave ++ "  Guardar build actual como subprompt") (saveBuildAsSubprompt doc)
                , menuEntry (iconFolder ++ "  Abrir build .pdsl") (openUrl buildPath)
                , menuEntry (iconFolder ++ "  Abrir carpeta de subprompts") (openPromptFolder "subprompts")
                , menuEntry (iconFolder ++ "  Abrir carpeta de builds") (openPromptFolder "builds")
                ]
                    ++ map providerEntry aiProviders
            }
  where
    providerEntry provider =
        menuEntry
            (iconAi ++ "  Abrir " ++ dropProviderIcon (urlEntryLabel provider))
            (openBrowserUrl ["--new-tab"] (urlEntryValue provider))

saveBuildAsSubprompt :: PromptDoc -> IO ()
saveBuildAsSubprompt doc = do
    nameInput <- promptRequired "wm-shared-prompt-save-subprompt" "Nombre del subprompt" "Usa un nombre corto y reutilizable."
    case nameInput of
        Nothing -> pure ()
        Just subpromptName -> do
            subpromptPath <- subpromptArtifactPath subpromptName
            let subpromptDoc = asSubprompt subpromptName doc
                serialized = serializePromptDoc subpromptDoc
            writeTextFile subpromptPath serialized
            compiled <- compileSavedArtifact subpromptPath
            case compiled of
                Left errors ->
                    notify "critical" "Prompt Lab" ("No se pudo guardar el subprompt: " ++ intercalate " | " errors)
                Right _ ->
                    notifySend ["-u", "normal", "-i", "document-save", "Subprompt guardado", subpromptPath]

loadSavedSubprompts :: IO [SavedPrompt]
loadSavedSubprompts = do
    directory <- promptLibrarySubpromptsDir
    exists <- doesDirectoryExist directory
    if not exists
        then pure []
        else do
            entries <- listDirectory directory
            let pdslFiles = filter (".pdsl" `isSuffixOf`) entries
            fmap catMaybes $
                mapM
                    ( \entry -> do
                        let path = directory </> entry
                        fileExists <- doesFileExist path
                        if not fileExists
                            then pure Nothing
                            else do
                                content <- readTextFile path
                                case parsePromptDoc content of
                                    Left _ -> pure Nothing
                                    Right parsed ->
                                        if docKind parsed == SavedSubprompt && null (validatePromptDoc parsed)
                                            then pure (Just (SavedPrompt path parsed))
                                            else pure Nothing
                    )
                    pdslFiles

savedPromptLabel :: SavedPrompt -> String
savedPromptLabel saved =
    iconSave
        ++ "  "
        ++ docName (savedPromptDoc saved)
        ++ " ["
        ++ intercalate ", " (take 2 (docRoles (savedPromptDoc saved)))
        ++ "]"

objectiveLabel :: [PromptTemplate] -> String
objectiveLabel [template] = templateObjectivePrompt template
objectiveLabel _ = "Que prompt compuesto quieres construir"

contextLabel :: [PromptTemplate] -> String
contextLabel [template] = templateContextPrompt template
contextLabel _ = "Contexto global del prompt compuesto"

chooseContextSource :: String -> IO (Maybe ContextSource)
chooseContextSource menuId =
    selectMenuSpec $
        MenuSpec
            { menuSpecId = menuId
            , menuSpecPrompt = "Fuente del contexto"
            , menuSpecArgs = ["-i", "-l", "3"]
            , menuSpecEntries =
                [ menuEntry (iconClipboard ++ "  Usar portapapeles actual") ContextClipboard
                , menuEntry (iconManual ++ "  Escribir / pegar contexto manualmente") ContextManual
                , menuEntry (iconSkip ++ "  Sin contexto adicional") ContextNone
                ]
            }

gatherContext :: String -> String -> ContextSource -> IO (Maybe String)
gatherContext menuId prompt source =
    case source of
        ContextClipboard -> do
            clipboard <- readClipboardText
            if null clipboard
                then do
                    notify "normal" "Prompt Lab" "El portapapeles esta vacio. Puedes escribir el contexto manualmente."
                    promptOptional menuId (prompt ++ " (opcional)") "Pega codigo, logs, requisitos o notas. Puedes dejarlo vacio."
                else do
                    let clipped = clipContext clipboard
                    when (length clipboard > contextLimit) $
                        notify "normal" "Prompt Lab" "El contexto del portapapeles se recorto para mantener el prompt manejable."
                    pure (Just clipped)
        ContextManual ->
            promptOptional
                menuId
                (prompt ++ " (opcional)")
                "Pega codigo, logs, requisitos o notas. El historial recuerda entradas cortas, no bloques gigantes."
        ContextNone -> pure Nothing
        ContextSaved -> pure Nothing

chooseLanguage :: String -> IO PromptLanguage
chooseLanguage menuId = do
    selected <-
        selectMenuSpec $
            MenuSpec
                { menuSpecId = menuId
                , menuSpecPrompt = "Idioma de salida"
                , menuSpecArgs = ["-i"]
                , menuSpecEntries =
                    [ menuEntry "ES  Responder en espanol" LangSpanish
                    , menuEntry "EN  Respond in English" LangEnglish
                    ]
                }
    pure (fromMaybe LangSpanish selected)

chooseDepth :: String -> IO PromptDepth
chooseDepth menuId = do
    selected <-
        selectMenuSpec $
            MenuSpec
                { menuSpecId = menuId
                , menuSpecPrompt = "Profundidad deseada"
                , menuSpecArgs = ["-i", "-l", "4"]
                , menuSpecEntries =
                    [ menuEntry "Practico  directo y accionable" DepthPractical
                    , menuEntry "Detallado  explica decisiones clave" DepthDetailed
                    , menuEntry "Exhaustivo  cubre riesgos, trade-offs y variantes" DepthExhaustive
                    ]
                }
    pure (fromMaybe DepthDetailed selected)

promptRequired :: String -> String -> String -> IO (Maybe String)
promptRequired menuId prompt hint = do
    value <- rofiSelection menuId prompt ["-i", "-mesg", hint] ""
    let trimmed = normalizeInput value
    pure (if null trimmed then Nothing else Just trimmed)

promptOptional :: String -> String -> String -> IO (Maybe String)
promptOptional menuId prompt hint = do
    value <- rofiSelection menuId prompt ["-i", "-mesg", hint] ""
    let trimmed = normalizeInput value
    pure (if null trimmed then Nothing else Just trimmed)

normalizeInput :: String -> String
normalizeInput = trimWhitespace

dropProviderIcon :: String -> String
dropProviderIcon [] = []
dropProviderIcon (_ : ' ' : rest) = rest
dropProviderIcon (_ : rest) = dropProviderIcon rest

responseDepthRule :: PromptDepth -> String
responseDepthRule DepthPractical = "Se directo: enfocate en acciones concretas y minimo texto accesorio."
responseDepthRule DepthDetailed = "Incluye razonamiento suficiente para justificar decisiones tecnicas importantes."
responseDepthRule DepthExhaustive = "Profundiza en riesgos, trade-offs, variantes y validaciones recomendadas."

copyRenderedPrompt :: PromptDoc -> PromptFormat -> IO ()
copyRenderedPrompt doc target = do
    let rendered = renderPromptDocAs target doc
    copied <- copyToClipboard rendered
    if copied
        then
            notifySend
                [ "-u"
                , "normal"
                , "-i"
                , "edit-copy"
                , "Prompt copiado"
                , "Salida compilada en formato " ++ formatLabel target
                ]
        else notify "critical" "Prompt Lab" "No se encontro una utilidad para copiar al portapapeles."

buildArtifactPath :: String -> IO FilePath
buildArtifactPath name = do
    timestamp <- currentTimestamp "%Y%m%d-%H%M%S" "build"
    directory <- promptLibraryBuildsDir
    createDirectoryIfMissing True directory
    pure (directory </> slugify name ++ "-" ++ timestamp ++ ".pdsl")

subpromptArtifactPath :: String -> IO FilePath
subpromptArtifactPath name = do
    directory <- promptLibrarySubpromptsDir
    createDirectoryIfMissing True directory
    pure (directory </> slugify name ++ ".pdsl")

promptLibraryDir :: IO FilePath
promptLibraryDir = do
    home <- getHomeDirectory
    pure (home </> ".config" </> "wm-shared" </> "prompt-library")

promptLibraryBuildsDir :: IO FilePath
promptLibraryBuildsDir = (</> "builds") <$> promptLibraryDir

promptLibrarySubpromptsDir :: IO FilePath
promptLibrarySubpromptsDir = (</> "subprompts") <$> promptLibraryDir

ensurePromptLibrarySeeded :: IO ()
ensurePromptLibrarySeeded = do
    buildsDir <- promptLibraryBuildsDir
    subpromptsDir <- promptLibrarySubpromptsDir
    createDirectoryIfMissing True buildsDir
    createDirectoryIfMissing True subpromptsDir
    mapM_ (uncurry seedIfMissing) (seedSubpromptArtifacts subpromptsDir ++ seedBuildArtifacts buildsDir)

openPromptFolder :: FilePath -> IO ()
openPromptFolder leaf = do
    base <- promptLibraryDir
    let target = base </> leaf
    createDirectoryIfMissing True target
    openUrl target

openAiProviderMenu :: IO ()
openAiProviderMenu =
    runMenuSpec $
        MenuSpec
            { menuSpecId = "wm-shared-prompt-ai-providers"
            , menuSpecPrompt = "Proveedor IA"
            , menuSpecArgs = ["-i", "-l", "8"]
            , menuSpecEntries = map toEntry aiProviders
            }
  where
    toEntry provider = menuEntry (urlEntryLabel provider) (openBrowserUrl ["--new-tab"] (urlEntryValue provider))

compileSavedArtifact :: FilePath -> IO (Either [String] (PromptDoc, String))
compileSavedArtifact path = do
    resolved <- resolvePromptDocFromFile [] path
    pure $
        case resolved of
            Left errors -> Left errors
            Right doc ->
                let errors = validatePromptDoc doc
                in if null errors
                    then Right (doc, renderPromptDocAs FormatXml doc)
                    else Left errors

resolvePromptDocFromFile :: [FilePath] -> FilePath -> IO (Either [String] PromptDoc)
resolvePromptDocFromFile stack path
    | path `elem` stack = pure (Left ["Ciclo de imports detectado: " ++ intercalate " -> " (reverse (path : stack))])
    | otherwise = do
        content <- readTextFile path
        case parsePromptDoc content of
            Left err -> pure (Left [path ++ ": " ++ err])
            Right parsed -> do
                imported <- mapM (resolveImportDoc (path : stack) path) (map importName (docImports parsed) ++ docExtends parsed)
                pure $ do
                    importedDocs <- sequence imported
                    Right (mergePromptDocs parsed { docImports = [], docExtends = [] } importedDocs)

resolveImportDoc :: [FilePath] -> FilePath -> String -> IO (Either [String] PromptDoc)
resolveImportDoc stack basePath importKey = do
    located <- findImportPath basePath importKey
    case located of
        Nothing -> pure (Left ["No se pudo resolver import `" ++ importKey ++ "` desde " ++ basePath])
        Just path -> resolvePromptDocFromFile stack path

findImportPath :: FilePath -> String -> IO (Maybe FilePath)
findImportPath basePath importKey = firstExistingFile (importCandidates basePath importKey)

importCandidates :: FilePath -> String -> [FilePath]
importCandidates basePath importKey =
    let localDir = takeDirectory basePath
        normalized = map (\c -> if c == '.' then '/' else c) importKey
        filename = normalized ++ ".pdsl"
    in [ localDir </> filename
       , localDir </> (importKey ++ ".pdsl")
       , "/home/elsadeveloper/.config/wm-shared/prompt-library/subprompts/" ++ filename
       , "/home/elsadeveloper/.config/wm-shared/prompt-library/builds/" ++ filename
       , "/home/elsadeveloper/.config/wm-shared/prompt-library/subprompts/" ++ importKey ++ ".pdsl"
       , "/home/elsadeveloper/.config/wm-shared/prompt-library/builds/" ++ importKey ++ ".pdsl"
       ]

firstExistingFile :: [FilePath] -> IO (Maybe FilePath)
firstExistingFile [] = pure Nothing
firstExistingFile (path : rest) = do
    exists <- doesFileExist path
    if exists then pure (Just path) else firstExistingFile rest

copyToClipboard :: String -> IO Bool
copyToClipboard content = tryCommands clipboardWriters
  where
    clipboardWriters =
        [ ("wl-copy", [])
        , ("xclip", ["-selection", "clipboard"])
        , ("xsel", ["--clipboard", "--input"])
        ]
    tryCommands [] = pure False
    tryCommands ((command, args) : rest) = do
        succeeded <- runCommandWithInput command args content
        if succeeded then pure True else tryCommands rest

readClipboardText :: IO String
readClipboardText = tryReaders clipboardReaders
  where
    clipboardReaders =
        [ ("wl-paste", ["-n"])
        , ("xclip", ["-o", "-selection", "clipboard"])
        , ("xsel", ["--clipboard", "--output"])
        ]
    tryReaders [] = pure ""
    tryReaders ((command, args) : rest) = do
        result <- readCommandOutput command args
        if null result then tryReaders rest else pure result

runCommandWithInput :: FilePath -> [String] -> String -> IO Bool
runCommandWithInput command args input = do
    executable <- findExecutable command
    case executable of
        Nothing -> pure False
        Just _ -> do
            result <- try (readProcessWithExitCode command args input) :: IO (Either IOException (ExitCode, String, String))
            pure $ case result of
                Right (ExitSuccess, _, _) -> True
                _ -> False

readCommandOutput :: FilePath -> [String] -> IO String
readCommandOutput command args = do
    executable <- findExecutable command
    case executable of
        Nothing -> pure ""
        Just _ -> do
            result <- try (readProcessWithExitCode command args "") :: IO (Either IOException (ExitCode, String, String))
            pure $ case result of
                Right (ExitSuccess, out, _) -> normalizeInput out
                _ -> ""

writeTextFile :: FilePath -> String -> IO ()
writeTextFile path content = writeFile path content

readTextFile :: FilePath -> IO String
readTextFile path = do
    result <- try (readFile path) :: IO (Either IOException String)
    pure (either (const "") id result)

seedIfMissing :: FilePath -> PromptDoc -> IO ()
seedIfMissing path doc = do
    exists <- doesFileExist path
    unless exists (writeTextFile path (serializePromptDoc doc))

seedSubpromptArtifacts :: FilePath -> [(FilePath, PromptDoc)]
seedSubpromptArtifacts directory =
    [ (directory </> "security-baseline.pdsl", securityBaselineSubprompt)
    , (directory </> "architecture-checklist.pdsl", architectureChecklistSubprompt)
    , (directory </> "review-rules.pdsl", reviewRulesSubprompt)
    , (directory </> "debug-investigation.pdsl", debugInvestigationSubprompt)
    ]

seedBuildArtifacts :: FilePath -> [(FilePath, PromptDoc)]
seedBuildArtifacts directory =
    [ (directory </> "feature-superprompt-example.pdsl", featureSuperpromptExample)
    ]

securityBaselineSubprompt, architectureChecklistSubprompt, reviewRulesSubprompt, debugInvestigationSubprompt, featureSuperpromptExample :: PromptDoc
securityBaselineSubprompt =
    emptyPromptDoc
        { docKind = SavedSubprompt
        , docName = "security-baseline"
        , docFormat = FormatPDSL
        , docLanguage = LangSpanish
        , docDepth = DepthDetailed
        , docRoles = ["Application Security Engineer"]
        , docTasks = ["Anade una capa base de auditoria de seguridad y mitigacion."]
        , docInstructions =
            [ "Revisa trust boundaries, auth, validacion de inputs y manejo de secretos."
            , "Prioriza vulnerabilidades explotables y configuraciones inseguras."
            ]
        , docDeliverables =
            [ "Lista priorizada de riesgos."
            , "Mitigaciones concretas y cambios recomendados."
            ]
        , docChecklist =
            [ "Autenticacion y autorizacion."
            , "Validacion de entradas."
            , "Secretos, tokens y datos sensibles."
            ]
        , docQualityBar =
            [ "Cada riesgo debe incluir impacto."
            , "Cada mitigacion debe ser accionable."
            ]
        , docResponseRules =
            [ "Evita recomendaciones vagas."
            ]
        }

architectureChecklistSubprompt =
    emptyPromptDoc
        { docKind = SavedSubprompt
        , docName = "architecture-checklist"
        , docFormat = FormatPDSL
        , docLanguage = LangSpanish
        , docDepth = DepthDetailed
        , docRoles = ["Principal Software Architect"]
        , docTasks = ["Anade una checklist de arquitectura para superprompts."]
        , docSections =
            [ NamedSection "architecture_focus" "Cubre boundaries, ownership, observabilidad, escalabilidad y trade-offs."
            ]
        , docInstructions =
            [ "Explica componentes, interfaces y decisiones tecnicas."
            ]
        , docDeliverables =
            [ "Mapa de modulos y responsabilidades."
            ]
        , docChecklist =
            [ "Boundaries claros."
            , "Riesgos y mitigaciones."
            , "Escalabilidad y operacion."
            ]
        , docQualityBar =
            [ "La propuesta debe ser implementable por fases."
            ]
        , docResponseRules =
            [ "Declara supuestos si faltan requisitos criticos."
            ]
        }

reviewRulesSubprompt =
    emptyPromptDoc
        { docKind = SavedSubprompt
        , docName = "review-rules"
        , docFormat = FormatPDSL
        , docLanguage = LangSpanish
        , docDepth = DepthDetailed
        , docRoles = ["Principal Code Reviewer"]
        , docTasks = ["Anade criterios de revision de alto valor."]
        , docInstructions =
            [ "Senala solo bugs, riesgos de seguridad, regresiones y deuda con impacto real."
            , "No gastes tiempo en nitpicks de estilo."
            ]
        , docDeliverables =
            [ "Hallazgos priorizados por severidad."
            ]
        , docChecklist =
            [ "Errores logicos."
            , "Edge cases no cubiertos."
            , "Riesgos de mantenimiento."
            ]
        , docQualityBar =
            [ "Cada hallazgo debe incluir impacto y arreglo sugerido."
            ]
        , docResponseRules =
            [ "Maxima densidad de senal, minimo ruido."
            ]
        }

debugInvestigationSubprompt =
    emptyPromptDoc
        { docKind = SavedSubprompt
        , docName = "debug-investigation"
        , docFormat = FormatPDSL
        , docLanguage = LangSpanish
        , docDepth = DepthDetailed
        , docRoles = ["Senior Debugging Engineer"]
        , docTasks = ["Anade una metodologia de investigacion para bugs complejos."]
        , docSections =
            [ NamedSection "investigation_mode" "Separa sintomas, hipotesis, evidencia y causa raiz confirmada."
            ]
        , docInstructions =
            [ "Ordena hipotesis por probabilidad e impacto."
            , "Propone pasos de diagnostico antes de sugerir cambios inseguros."
            ]
        , docDeliverables =
            [ "Plan de diagnostico."
            , "Fix sugerido."
            ]
        , docChecklist =
            [ "Reproduccion."
            , "Logs y stack traces."
            , "Riesgo de regresiones."
            ]
        , docQualityBar =
            [ "No confundas sintoma con causa."
            ]
        , docResponseRules =
            [ "Explica por que la causa raiz propuesta es la mas probable."
            ]
        }

featureSuperpromptExample =
    mergePromptDocs
        ( emptyPromptDoc
            { docKind = FinalPrompt
            , docName = "feature-superprompt-example"
            , docFormat = FormatPDSL
            , docLanguage = LangSpanish
            , docDepth = DepthDetailed
            , docObjective = Just "Disenar e implementar una nueva feature sin perder calidad, seguridad ni revisabilidad."
            , docSections =
                [ NamedSection "stack" "TypeScript + React + Node.js"
                , NamedSection "constraints" "Cambios pequenos, faciles de revisar y sin regresiones funcionales."
                ]
            , docContextArtifacts =
                [ ContextArtifact "product-context" ContextManual "Feature con impacto en frontend y backend; debe mantenerse coherencia entre UX, validaciones y API."
                ]
            , docResponseRules =
                [ "Responde en espanol."
                , responseDepthRule DepthDetailed
                ]
            }
        )
        [ securityBaselineSubprompt
        , reviewRulesSubprompt
        ]

clipContext :: String -> String
clipContext content =
    let trimmed = normalizeInput content
    in if length trimmed <= contextLimit
        then trimmed
        else take contextLimit trimmed ++ "\n\n[context truncated automatically to keep prompts manageable]"

slugify :: String -> String
slugify input =
    let mapped = map normalizeChar input
        compacted = collapseDashes mapped
        cleaned = trimDashes compacted
    in if null cleaned then "prompt" else cleaned
  where
    normalizeChar c
        | isAlphaNumeric c = toLowerAscii c
        | otherwise = '-'
    isAlphaNumeric c = ('a' <= lower && lower <= 'z') || ('0' <= c && c <= '9')
      where
        lower = toLowerAscii c
    toLowerAscii c
        | 'A' <= c && c <= 'Z' = toEnum (fromEnum c + 32)
        | otherwise = c
    collapseDashes [] = []
    collapseDashes ('-' : '-' : rest) = collapseDashes ('-' : rest)
    collapseDashes (c : rest) = c : collapseDashes rest
    trimDashes = reverse . dropWhile (== '-') . reverse . dropWhile (== '-')
