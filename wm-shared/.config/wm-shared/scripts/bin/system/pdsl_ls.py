#!/usr/bin/env python3

from __future__ import annotations

import json
import re
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from difflib import get_close_matches
from pathlib import Path
from typing import Any
from urllib.parse import quote, unquote, urlparse


KEYWORD_DOCS: dict[str, str] = {
    "import": "Importa otro archivo `.pdsl` reusable por nombre.",
    "prompt": "Define un prompt o subprompt PDSL.",
    "kind": "Tipo de documento: `final` o `subprompt`.",
    "language": "Idioma principal del prompt, por ejemplo `es` o `en`.",
    "depth": "Profundidad esperada: `practical`, `detailed`, `exhaustive`.",
    "extends": "Compone otro prompt por nombre, igual que un import semántico.",
    "profile": "Perfil semántico libre del prompt para clasificarlo o reutilizarlo.",
    "quality_profile": "Perfil de calidad que ajusta el lint para tipos de prompt como `engineering`, `research`, `security` o `concise`.",
    "tag": "Etiqueta libre para clasificar o encontrar prompts.",
    "owner": "Autor o dueño del prompt.",
    "version": "Versión semántica o editorial del prompt.",
    "compat": "Compatibilidad declarada con una versión del ecosistema PDSL.",
    "deprecated": "Marca el prompt como deprecado si ya no debe reutilizarse.",
    "libraries": "Guarda módulos reutilizables bajo `prompt-library/libraries/...` e impórtalos por namespace con puntos, estilo package.",
    "role": "Rol que debe adoptar el modelo.",
    "task": "Tarea principal o responsabilidades del prompt.",
    "objective": "Objetivo central del prompt final.",
    "section": "Bloque semántico nombrado con contenido multilinea.",
    "context": "Artefacto de contexto con source y kind.",
    "checklist": "Checklist operativo o de revisión.",
    "targets": "Targets de compilación soportados: `xml`, `markdown`, `hybrid`.",
    "instructions": "Instrucciones operativas específicas.",
    "deliverables": "Artefactos esperados en la respuesta.",
    "quality_bar": "Criterios de calidad obligatorios.",
    "response_rules": "Contrato de respuesta del modelo.",
    "assumptions": "Supuestos explícitos que condicionan la respuesta.",
    "non_goals": "Cosas que quedan fuera del alcance del prompt.",
    "risks": "Riesgos y amenazas que el modelo debe considerar.",
    "tradeoffs": "Compromisos o tensiones entre objetivos.",
    "acceptance_criteria": "Criterios verificables que definen éxito.",
    "verification_plan": "Plan para comprobar que la salida cumple el contrato.",
    "examples": "Ejemplos positivos del tipo de respuesta esperada.",
    "anti_patterns": "Ejemplos negativos o comportamientos prohibidos.",
    "evaluation_criteria": "Criterios para evaluar la calidad de la salida.",
    "questions_if_missing": "Preguntas que el modelo debe hacer si falta contexto crítico.",
    "param": "Declara un parámetro reusable del prompt.",
    "type": "Tipo declarado de un parámetro.",
    "required": "Marca un parámetro como obligatorio u opcional.",
    "description": "Descripción de un parámetro o campo.",
    "requires": "Requisitos semánticos legacy que se traducen a reglas SMT.",
    "forbids": "Restricciones negativas legacy que se traducen a reglas SMT.",
    "mutually_exclusive": "Grupo legacy de restricciones incompatibles entre sí.",
    "rules": "Bloque formal de reglas: `must`, `forbid`, `implies`, `exclusive`, `at_least`, `at_most`, `exactly`.",
    "atoms": "Bloque de declaraciones de átomos semánticos tipados. Cada entrada tiene la forma `nombre : tipo [\"descripcion\"]`. Tipos válidos: `behavior`, `obligation`, `hazard`, `format`, `quality`.",
    "exports": "Declara qué átomos semánticos provee este módulo a los consumidores. Cada línea es el nombre de un átomo declarado en `atoms`.",
    "contract": "Contrato de módulo verificado contra el documento resuelto. Usa `requires atom` para exigir que un átomo `must` esté activo, o `forbids atom` para prohibirlo.",
    "must": "Hace obligatorio un átomo lógico del prompt.",
    "forbid": "Prohíbe un átomo lógico del prompt.",
    "implies": "Declara una implicación lógica entre dos átomos.",
    "exclusive": "Declara que varios átomos no pueden coexistir.",
    "at_least": "Exige que al menos N átomos sean verdaderos.",
    "at_most": "Exige que como máximo N átomos sean verdaderos.",
    "exactly": "Exige que exactamente N átomos sean verdaderos.",
}

KEYWORD_COMPLETIONS = sorted(KEYWORD_DOCS.keys())
RULE_COMPLETIONS = ["must", "forbid", "implies", "exclusive", "at_least", "at_most", "exactly"]
VALUE_COMPLETIONS: dict[str, list[str]] = {
    "kind": ["final", "subprompt"],
    "language": ["es", "en"],
    "depth": ["practical", "detailed", "exhaustive"],
    "deprecated": ["true", "false"],
    "required": ["true", "false"],
    "quality_profile": ["engineering", "research", "security", "concise", "quick-response"],
    "profile": ["engineering", "research", "security", "concise", "speed", "evidence", "demo", "z3", "baseline"],
    "type": ["string", "enum", "number", "bool", "path", "prompt-ref"],
    "targets": ["xml", "markdown", "hybrid"],
    "context_source": ["manual", "clipboard", "none", "saved"],
    "atom_type": ["behavior", "obligation", "hazard", "format", "quality"],
}
COMPLETION_TRIGGER_CHARACTERS = sorted(set(list('" .:-/"') + list("abcdefghijklmnopqrstuvwxyz_")))
RE_IMPORT = re.compile(r"^\s*(import|extends)\s+([A-Za-z0-9_.-]+)(?:\s+as\s+([A-Za-z0-9_.-]+))?\s*$")
RE_DOC_LINE = re.compile(r"^(.*?):(\d+):(\d+):\s+(error|warning):\s+(.*)$")
RE_SYMBOLS: list[tuple[re.Pattern[str], int]] = [
    (re.compile(r'^\s*prompt\s+("[^"]+"|[A-Za-z0-9_.-]+)\s*\{'), 5),
    (re.compile(r'^\s*role\s+("[^"]+"|[A-Za-z0-9_.-]+)\s*$'), 12),
    (re.compile(r'^\s*task\s+("[^"]+"|[A-Za-z0-9_.-]+)\s*$'), 12),
    (re.compile(r'^\s*section\s+("[^"]+"|[A-Za-z0-9_.-]+)\s+"""'), 5),
    (re.compile(r'^\s*param\s+("[^"]+"|[A-Za-z0-9_.-]+)\s+\{'), 13),
    (re.compile(r'^\s*context\s+[A-Za-z0-9_.-]+\s+("[^"]+"|[A-Za-z0-9_.-]+)\s+"""'), 6),
    (re.compile(r'^\s*([A-Za-z0-9_-]+)\s*:\s*(behavior|obligation|hazard|format|quality)\b'), 7),
]
TOKEN_TYPES = ["keyword", "string", "comment", "namespace", "parameter", "property"]
TOKEN_MODIFIERS: list[str] = []

SNIPPETS: list[dict[str, Any]] = [
    {
        "label": "prompt-final",
        "detail": "Final prompt skeleton",
        "documentation": "Inserta una plantilla completa para un prompt final.",
        "body": '''prompt ${1:prompt_name} {
  kind final
  language ${2:es}
  depth ${3:detailed}
  deprecated false
  quality_profile "${4:engineering}"

  role "${5:Principal Prompt Engineer.}"
  task "${6:Describe la responsabilidad principal y el resultado esperado.}"

  objective """
    ${7:Define un objetivo observable y evaluable.}
  """

  instructions {
    "${8:Indica la primera instruccion operativa.}"
    "${9:Indica la segunda instruccion operativa.}"
  }

  deliverables {
    "${10:Entrega principal esperada.}"
    "${11:Entrega secundaria esperada.}"
  }

  quality_bar {
    "${12:Criterio de calidad principal.}"
  }

  response_rules {
    "${13:Regla de respuesta principal.}"
  }

  rules {
    must ${14:no-fabricated-context}
  }
}''',
    },
    {
        "label": "prompt-subprompt",
        "detail": "Subprompt skeleton",
        "documentation": "Inserta una plantilla completa para un subprompt reusable.",
        "body": '''prompt ${1:subprompt_name} {
  kind subprompt
  language ${2:es}
  depth ${3:detailed}
  deprecated false
  quality_profile "${4:engineering}"

  role "${5:Reusable Specialist.}"
  task "${6:Define una capacidad reusable y verificable.}"

  instructions {
    "${7:Instruccion reusable 1.}"
    "${8:Instruccion reusable 2.}"
  }

  deliverables {
    "${9:Salida reusable.}"
  }

  quality_bar {
    "${10:Criterio de calidad reusable.}"
  }

  response_rules {
    "${11:Regla de respuesta reusable.}"
  }

  rules {
    must ${12:clear-contract}
  }
}''',
    },
    {
        "label": "quality-profile",
        "detail": "Quality profile metadata",
        "documentation": "Inserta una linea `quality_profile` para activar lint especializado.",
        "body": 'quality_profile "${1:engineering}"',
    },
    {
        "label": "import-library",
        "detail": "Namespaced library import",
        "documentation": "Inserta un import con namespace estilo package.",
        "body": 'import ${1:engineering.core.shared_rules}',
    },
    {
        "label": "rules-block",
        "detail": "Formal rules block",
        "documentation": "Inserta un bloque `rules` con restricciones formales.",
        "body": '''rules {
  must ${1:required-atom}
  implies ${2:required-atom} ${3:dependent-atom}
  forbid ${4:forbidden-atom}
  exclusive ${5:first-atom} ${6:second-atom}
}''',
    },
    {
        "label": "atoms-block",
        "detail": "Typed semantic atoms block",
        "documentation": "Declara los átomos semánticos usados en `rules` con su tipo formal.\nTipos válidos: `behavior`, `obligation`, `hazard`, `format`, `quality`.",
        "body": '''atoms {
  ${1:required-atom} : ${2:obligation} "${3:Descripcion del atomo.}"
  ${4:forbidden-atom} : ${5:hazard} "${6:Descripcion del atomo prohibido.}"
}''',
    },
    {
        "label": "exports-block",
        "detail": "Module exports block",
        "documentation": "Declara los átomos que este subprompt garantiza a los consumidores.",
        "body": '''exports {
  ${1:required-atom}
  ${2:other-atom}
}''',
    },
    {
        "label": "contract-block",
        "detail": "Module contract block",
        "documentation": "Contrato de módulo verificado contra el documento resuelto.\nUsa `requires` para exigir que un átomo `must` esté activo o `forbids` para prohibirlo.",
        "body": '''contract {
  requires ${1:expected-atom}
}''',
    },
    {
        "label": "rules-cardinality",
        "detail": "Cardinality rules block",
        "documentation": "Inserta reglas cardinales para Z3.",
        "body": '''rules {
  at_least ${1:2} ${2:first-atom} ${3:second-atom} ${4:third-atom}
  at_most ${5:1} ${6:first-atom} ${7:second-atom}
  exactly ${8:1} ${9:primary-output} ${10:fallback-output}
}''',
    },
    {
        "label": "objective-block",
        "detail": "Objective block",
        "documentation": "Inserta un bloque `objective` multilinea.",
        "body": '''objective """
  ${1:Define un objetivo observable y evaluable.}
"""''',
    },
    {
        "label": "section-block",
        "detail": "Section block",
        "documentation": "Inserta una `section` multilinea.",
        "body": '''section "${1:section-name}" """
  ${2:Contenido de la seccion.}
"""''',
    },
    {
        "label": "context-block",
        "detail": "Context artifact block",
        "documentation": "Inserta un artefacto de contexto.",
        "body": '''context ${1:manual} "${2:artifact-kind}" """
  ${3:Contexto relevante.}
"""''',
    },
    {
        "label": "param-block",
        "detail": "Parameter block",
        "documentation": "Inserta un bloque `param`.",
        "body": '''param "${1:param_name}" {
  type "${2:string}"
  required ${3:true}
  description "${4:Describe el parametro.}"
}''',
    },
    {
        "label": "prompt-engineering",
        "detail": "Engineering prompt scaffold",
        "documentation": "Plantilla opinionada para prompts de ingenieria con criterios de aceptacion y verificacion.",
        "body": '''prompt ${1:engineering_prompt} {
  kind final
  language ${2:es}
  depth ${3:detailed}
  deprecated false
  profile "engineering"
  quality_profile "engineering"

  role "${4:Staff Software Engineer focused on safe implementation decisions.}"
  task "${5:Define una estrategia de implementacion concreta, validable y mantenible.}"

  objective """
    ${6:Describe un resultado observable para el cambio tecnico.}
  """

  instructions {
    "${7:Respeta patrones existentes y reduce riesgo de integracion.}"
    "${8:Explicita errores, limites y validaciones.}"
  }

  deliverables {
    "${9:Plan de implementacion accionable.}"
    "${10:Criterios de validacion y riesgos principales.}"
  }

  quality_bar {
    "${11:Cada recomendacion debe ser aplicable al contexto real.}"
  }

  response_rules {
    "${12:Evita ambiguedad y relleno generico.}"
  }

  acceptance_criteria {
    "${13:La salida debe ser verificable y coherente con el codigo existente.}"
  }

  verification_plan {
    "${14:Explica como comprobar el cambio y su impacto.}"
  }

  rules {
    must ${15:preserve-existing-patterns}
  }
}''',
    },
    {
        "label": "prompt-research",
        "detail": "Research prompt scaffold",
        "documentation": "Plantilla para prompts con trazabilidad, supuestos y preguntas por contexto faltante.",
        "body": '''prompt ${1:research_prompt} {
  kind final
  language ${2:es}
  depth ${3:detailed}
  deprecated false
  profile "research"
  quality_profile "research"

  role "${4:Evidence-driven researcher.}"
  task "${5:Produce una respuesta trazable y apoyada en evidencia.}"

  objective """
    ${6:Define una conclusion verificable y el criterio de evidencia requerido.}
  """

  instructions {
    "${7:Explicita el nivel de evidencia disponible.}"
    "${8:Relaciona premisas, evidencia y conclusion.}"
  }

  deliverables {
    "${9:Respuesta con trazabilidad explicita.}"
  }

  quality_bar {
    "${10:No debe haber saltos inferenciales sin soporte.}"
  }

  response_rules {
    "${11:Declara limites si falta evidencia suficiente.}"
  }

  assumptions {
    "${12:Supuesto critico explicitado.}"
  }

  questions_if_missing {
    "${13:Que dato critico falta para sostener la conclusion?}"
  }

  rules {
    must ${14:cite-sources}
  }
}''',
    },
    {
        "label": "prompt-security",
        "detail": "Security prompt scaffold",
        "documentation": "Plantilla para prompts con riesgos, anti-patrones y restricciones defensivas.",
        "body": '''prompt ${1:security_prompt} {
  kind final
  language ${2:es}
  depth ${3:detailed}
  deprecated false
  profile "security"
  quality_profile "security"

  role "${4:Security reviewer focused on abuse cases and explicit controls.}"
  task "${5:Evalua riesgos, controles y posibles abusos con criterios verificables.}"

  objective """
    ${6:Describe el objetivo de seguridad y el resultado esperado.}
  """

  instructions {
    "${7:Prioriza escenarios de abuso realistas.}"
    "${8:Explicita controles, riesgos residuales y mitigaciones.}"
  }

  deliverables {
    "${9:Resumen de riesgos y mitigaciones.}"
  }

  quality_bar {
    "${10:Cada recomendacion debe reducir riesgo medible o claramente descrito.}"
  }

  response_rules {
    "${11:No omitas supuestos de amenaza ni riesgos residuales.}"
  }

  risks {
    "${12:Riesgo principal.}"
  }

  anti_patterns {
    "${13:Mitigacion cosmetica sin reducir el riesgo real.}"
  }

  rules {
    forbid ${14:implicit-trust}
  }
}''',
    },
]

BLOCK_TEMPLATES: dict[str, str] = {
    "objective": '''objective """
  ${1:Define un objetivo observable y evaluable.}
"""''',
    "instructions": '''instructions {
  "${1:Instruccion operativa 1.}"
  "${2:Instruccion operativa 2.}"
}''',
    "deliverables": '''deliverables {
  "${1:Entrega principal.}"
  "${2:Entrega secundaria.}"
}''',
    "quality_bar": '''quality_bar {
  "${1:Criterio de calidad principal.}"
}''',
    "response_rules": '''response_rules {
  "${1:Regla de respuesta principal.}"
}''',
    "acceptance_criteria": '''acceptance_criteria {
  "${1:Criterio verificable de exito.}"
}''',
    "verification_plan": '''verification_plan {
  "${1:Paso de verificacion principal.}"
}''',
    "assumptions": '''assumptions {
  "${1:Supuesto critico explicitado.}"
}''',
    "questions_if_missing": '''questions_if_missing {
  "${1:Pregunta a realizar si falta contexto critico.}"
}''',
    "risks": '''risks {
  "${1:Riesgo principal o amenaza relevante.}"
}''',
    "anti_patterns": '''anti_patterns {
  "${1:Comportamiento prohibido o salida invalida.}"
}''',
    "rules": '''rules {
  must ${1:required-atom}
}''',
    "quality_profile": 'quality_profile "${1:engineering}"',
    "role": 'role "${1:Principal Prompt Engineer.}"',
    "task": 'task "${1:Describe la responsabilidad principal y el resultado esperado.}"',
}

ROOT_LINE_TEMPLATES: dict[str, str] = {
    "kind": 'kind ${1:final}',
    "language": 'language ${1:es}',
    "depth": 'depth ${1:detailed}',
    "deprecated": 'deprecated ${1:false}',
    "profile": 'profile "${1:engineering}"',
    "quality_profile": 'quality_profile "${1:engineering}"',
    "owner": 'owner "${1:team-or-owner}"',
    "version": 'version "${1:1.0.0}"',
    "compat": 'compat "${1:pdsl-1}"',
}


@dataclass
class DocumentSnapshot:
    text: str
    lines: list[str]
    structure: dict[str, set[str]]
    document_symbols: list[dict[str, Any]]
    import_occurrences: list[dict[str, Any]]
    alias_occurrences: list[dict[str, Any]]
    prompt_occurrences: list[dict[str, Any]]
    param_occurrences: list[dict[str, Any]]
    section_occurrences: list[dict[str, Any]]
    atom_occurrences: list[dict[str, Any]]
    named_occurrences: list[dict[str, Any]]
    local_rule_atoms: list[str]
    block_stack_by_line: list[tuple[str, ...]]
    empty_blocks: list[dict[str, Any]]


@dataclass
class DirectoryScanEntry:
    expires_at: float
    files: list[Path]


class WorkspaceCache:
    def __init__(self) -> None:
        self.directory_scans: dict[Path, DirectoryScanEntry] = {}
        self.file_snapshots: dict[Path, tuple[int, DocumentSnapshot]] = {}
        self.import_resolution_cache: dict[tuple[str, str], Path | None] = {}
        self.explain_cache: dict[tuple[str, str], str | None] = {}
        self.lint_cache: dict[tuple[str, str], list[dict[str, Any]]] = {}
        self.format_cache: dict[tuple[str, str], str | None] = {}
        self.library_index_loaded = False
        self.library_index: dict[str, Any] = {"files": {}, "symbols": [], "importables": []}

    def index_path(self) -> Path:
        return Path.home() / ".cache" / "pdsl-ls" / "workspace-index.json"

    def load_library_index(self) -> None:
        if self.library_index_loaded:
            return
        path = self.index_path()
        if path.exists():
            try:
                self.library_index = json.loads(path.read_text())
            except Exception:
                self.library_index = {"files": {}, "symbols": [], "importables": []}
        self.library_index_loaded = True

    def save_library_index(self) -> None:
        path = self.index_path()
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(self.library_index, ensure_ascii=False))

    def current_library_file_state(self) -> dict[str, int]:
        state: dict[str, int] = {}
        for path in library_files():
            try:
                state[str(path)] = path.stat().st_mtime_ns
            except Exception:
                continue
        return state

    def rebuild_library_index(self) -> None:
        files_state = self.current_library_file_state()
        symbols: list[dict[str, Any]] = []
        importables: set[str] = set()
        for raw_path in files_state:
            path = Path(raw_path)
            snapshot = self.snapshot_for_file(path)
            if snapshot is None:
                continue
            for directory in prompt_library_dirs():
                try:
                    if path.is_relative_to(directory):
                        importables.add(path.stem)
                        importables.add(namespace_for_library_file(path, directory))
                        break
                except Exception:
                    continue
            for symbol in flatten_document_symbols(snapshot.document_symbols):
                symbols.append(
                    {
                        "name": symbol["name"],
                        "kind": symbol["kind"],
                        "uri": path_to_uri(path),
                        "range": symbol["range"],
                    }
                )
        self.library_index = {"files": files_state, "symbols": symbols, "importables": sorted(importables)}
        self.save_library_index()

    def ensure_library_index(self) -> None:
        self.load_library_index()
        current_state = self.current_library_file_state()
        if self.library_index.get("files") != current_state:
            self.rebuild_library_index()

    def indexed_importables(self) -> list[str]:
        self.ensure_library_index()
        return list(self.library_index.get("importables", []))

    def indexed_symbols(self) -> list[dict[str, Any]]:
        self.ensure_library_index()
        return list(self.library_index.get("symbols", []))

    def invalidate_path(self, path: Path) -> None:
        self.file_snapshots.pop(path, None)
        self.explain_cache = {key: value for key, value in self.explain_cache.items() if key[0] != str(path)}
        self.lint_cache = {key: value for key, value in self.lint_cache.items() if key[0] != str(path)}
        self.format_cache = {key: value for key, value in self.format_cache.items() if key[0] != str(path)}
        self.import_resolution_cache = {
            key: value for key, value in self.import_resolution_cache.items() if not key[0].startswith(str(path.parent))
        }
        self.library_index_loaded = False

    def scan_pdsl_files(self, root: Path, *, ttl_seconds: float = 1.0) -> list[Path]:
        now = time.monotonic()
        cached = self.directory_scans.get(root)
        if cached is not None and cached.expires_at > now:
            return cached.files
        files = sorted(path for path in root.rglob("*.pdsl") if path.is_file()) if root.exists() else []
        self.directory_scans[root] = DirectoryScanEntry(expires_at=now + ttl_seconds, files=files)
        return files

    def snapshot_for_file(self, path: Path) -> DocumentSnapshot | None:
        try:
            stat = path.stat()
        except Exception:
            return None
        cached = self.file_snapshots.get(path)
        if cached is not None and cached[0] == stat.st_mtime_ns:
            return cached[1]
        try:
            text = path.read_text()
        except Exception:
            return None
        snapshot = scan_document(text)
        self.file_snapshots[path] = (stat.st_mtime_ns, snapshot)
        return snapshot


def bundled_tool(name: str) -> Path:
    return Path(__file__).resolve().parent / name


def lint_cmd() -> Path:
    preferred = Path("~/.config/wm-shared/scripts/bin/system/pdsl_lint.hs").expanduser()
    return preferred if preferred.exists() else bundled_tool("pdsl_lint.hs")


def format_cmd() -> Path:
    preferred = Path("~/.config/wm-shared/scripts/bin/system/pdsl_format.hs").expanduser()
    return preferred if preferred.exists() else bundled_tool("pdsl_format.hs")


def export_cmd() -> Path:
    preferred = Path("~/.config/wm-shared/scripts/bin/system/pdsl_export.hs").expanduser()
    return preferred if preferred.exists() else bundled_tool("pdsl_export.hs")


def explain_cmd() -> Path:
    preferred = Path("~/.config/wm-shared/scripts/bin/system/pdsl_explain.hs").expanduser()
    return preferred if preferred.exists() else bundled_tool("pdsl_explain.hs")


def prompt_library_dirs() -> list[Path]:
    base = Path.home() / ".config" / "wm-shared" / "prompt-library"
    return [base / "subprompts", base / "builds", base / "libraries"]


def library_files(cache: WorkspaceCache | None = None) -> list[Path]:
    files: list[Path] = []
    for directory in prompt_library_dirs():
        if cache is not None:
            files.extend(cache.scan_pdsl_files(directory))
        elif directory.exists():
            files.extend(sorted(path for path in directory.rglob("*.pdsl") if path.is_file()))
    return files


def uri_to_path(uri: str) -> Path:
    parsed = urlparse(uri)
    if parsed.scheme != "file":
        raise ValueError(f"Unsupported URI scheme: {parsed.scheme}")
    return Path(unquote(parsed.path))


def path_to_uri(path: Path) -> str:
    return f"file://{quote(str(path))}"


def import_candidates(base_path: Path, import_key: str) -> list[Path]:
    normalized = import_key.replace(".", "/")
    filename = normalized + ".pdsl"
    return [
        base_path.parent / filename,
        base_path.parent / f"{import_key}.pdsl",
        *(directory / filename for directory in prompt_library_dirs()),
        *(directory / f"{import_key}.pdsl" for directory in prompt_library_dirs()),
    ]


def resolve_import_path(base_path: Path, import_key: str, cache: WorkspaceCache | None = None) -> Path | None:
    cache_key = (str(base_path.parent), import_key)
    if cache is not None and cache_key in cache.import_resolution_cache:
        return cache.import_resolution_cache[cache_key]
    for candidate in import_candidates(base_path, import_key):
        if candidate.exists():
            if cache is not None:
                cache.import_resolution_cache[cache_key] = candidate
            return candidate
    if cache is not None:
        cache.import_resolution_cache[cache_key] = None
    return None


def namespace_for_library_file(path: Path, root: Path) -> str:
    relative = path.relative_to(root).with_suffix("")
    return ".".join(relative.parts)


def importable_names(base_path: Path | None = None, cache: WorkspaceCache | None = None) -> list[str]:
    names: set[str] = set()
    if cache is not None:
        names.update(cache.indexed_importables())
    else:
        for directory in prompt_library_dirs():
            for path in (sorted(directory.rglob("*.pdsl")) if directory.exists() else []):
                if not path.is_file():
                    continue
                names.add(path.stem)
                names.add(namespace_for_library_file(path, directory))
    if base_path is not None and base_path.parent.exists():
        local_paths = cache.scan_pdsl_files(base_path.parent, ttl_seconds=0.5) if cache is not None else sorted(base_path.parent.rglob("*.pdsl"))
        for path in local_paths:
            if not path.is_file() or path == base_path:
                continue
            names.add(path.stem)
            try:
                names.add(".".join(path.relative_to(base_path.parent).with_suffix("").parts))
            except ValueError:
                pass
    return sorted(name for name in names if name)


def local_importable_names(base_path: Path | None, cache: WorkspaceCache | None = None) -> set[str]:
    if base_path is None or not base_path.parent.exists():
        return set()
    names: set[str] = set()
    local_paths = cache.scan_pdsl_files(base_path.parent, ttl_seconds=0.5) if cache is not None else sorted(base_path.parent.rglob("*.pdsl"))
    for path in local_paths:
        if not path.is_file() or path == base_path:
            continue
        names.add(path.stem)
        try:
            names.add(".".join(path.relative_to(base_path.parent).with_suffix("").parts))
        except ValueError:
            continue
    return names


def extract_scalar_field(text: str, field_name: str) -> str | None:
    pattern = re.compile(rf'^\s*{re.escape(field_name)}\s+"?([^"\n]+)"?\s*$')
    for raw_line in text.splitlines():
        stripped = strip_comments(raw_line).strip()
        match = pattern.match(stripped)
        if match:
            return match.group(1).strip()
    return None


def collect_import_specs(snapshot: DocumentSnapshot) -> list[dict[str, Any]]:
    specs: list[dict[str, Any]] = []
    for line_index, raw_line in enumerate(snapshot.lines):
        stripped = strip_comments(raw_line)
        match = RE_IMPORT.match(stripped)
        if not match:
            continue
        specs.append(
            {
                "relation": match.group(1),
                "name": match.group(2),
                "alias": match.group(3),
                "line": line_index,
            }
        )
    return specs


def unique_preserving_order(values: list[str]) -> list[str]:
    seen: set[str] = set()
    ordered: list[str] = []
    for value in values:
        if value in seen:
            continue
        seen.add(value)
        ordered.append(value)
    return ordered


def prompt_name_for_snapshot(snapshot: DocumentSnapshot | None) -> str | None:
    if snapshot is None or not snapshot.prompt_occurrences:
        return None
    return snapshot.prompt_occurrences[0]["name"]


def collect_import_chain(
    base_path: Path | None,
    snapshot: DocumentSnapshot,
    *,
    open_documents: dict[str, DocumentSnapshot] | None = None,
    cache: WorkspaceCache | None = None,
    seen: set[Path] | None = None,
    depth: int = 0,
    limit: int = 8,
) -> list[str]:
    if base_path is None or depth >= 3:
        return []
    seen = seen or set()
    if base_path in seen:
        return []
    seen.add(base_path)
    chain: list[str] = []
    for spec in collect_import_specs(snapshot):
        chain.append(spec["name"])
        if len(chain) >= limit:
            break
        target = resolve_import_path(base_path, spec["name"], cache)
        if target is None or target in seen:
            continue
        target_uri = path_to_uri(target)
        target_snapshot = open_documents[target_uri] if open_documents is not None and target_uri in open_documents else (cache.snapshot_for_file(target) if cache is not None else None)
        if target_snapshot is None:
            try:
                target_snapshot = scan_document(target.read_text())
            except Exception:
                continue
        chain.extend(
            collect_import_chain(
                target,
                target_snapshot,
                open_documents=open_documents,
                cache=cache,
                seen=seen,
                depth=depth + 1,
                limit=max(0, limit - len(chain)),
            )
        )
        if len(chain) >= limit:
            break
    return unique_preserving_order(chain)[:limit]


def render_indented_snippet(snippet: str, indent: str = "  ") -> str:
    return indent + snippet.replace("\n", "\n" + indent)


def find_block_range(text: str, block_name: str) -> dict[str, Any] | None:
    lines = text.splitlines()
    for index, raw_line in enumerate(lines):
        stripped = strip_comments(raw_line).strip()
        if not (stripped == f"{block_name} {{" or stripped.startswith(f"{block_name} ")):
            continue
        if stripped.endswith("{"):
            depth = 1
            for inner_index in range(index + 1, len(lines)):
                inner = strip_comments(lines[inner_index]).strip()
                if inner.endswith("{"):
                    depth += 1
                elif inner == "}":
                    depth -= 1
                    if depth == 0:
                        return make_range(index, 0, inner_index, len(lines[inner_index]))
            return make_range(index, 0, index, len(raw_line))
        if '"""' in raw_line:
            in_triple = raw_line.count('"""') % 2 == 1
            if not in_triple:
                return make_range(index, 0, index, len(raw_line))
            for inner_index in range(index + 1, len(lines)):
                if lines[inner_index].count('"""') % 2 == 1:
                    in_triple = not in_triple
                    if not in_triple:
                        return make_range(index, 0, inner_index, len(lines[inner_index]))
            return make_range(index, 0, index, len(raw_line))
        return make_range(index, 0, index, len(raw_line))
    return None


def iter_workspace_documents(
    base_path: Path | None,
    current_uri: str | None = None,
    current_text: str | None = None,
    *,
    open_documents: dict[str, DocumentSnapshot] | None = None,
    cache: WorkspaceCache | None = None,
) -> list[tuple[Path, DocumentSnapshot]]:
    seen: set[Path] = set()
    documents: list[tuple[Path, DocumentSnapshot]] = []

    def append_document(path: Path, snapshot: DocumentSnapshot) -> None:
        if path in seen:
            return
        seen.add(path)
        documents.append((path, snapshot))

    if base_path is not None:
        if current_uri is not None and open_documents is not None and current_uri in open_documents:
            append_document(base_path, open_documents[current_uri])
        elif current_text is not None:
            append_document(base_path, scan_document(current_text))
        else:
            snapshot = cache.snapshot_for_file(base_path) if cache is not None else scan_document(base_path.read_text()) if base_path.exists() else None
            if snapshot is not None:
                append_document(base_path, snapshot)
        if base_path.parent.exists():
            local_paths = cache.scan_pdsl_files(base_path.parent, ttl_seconds=0.5) if cache is not None else sorted(base_path.parent.rglob("*.pdsl"))
            for path in local_paths:
                if not path.is_file():
                    continue
                uri = path_to_uri(path)
                if open_documents is not None and uri in open_documents:
                    append_document(path, open_documents[uri])
                    continue
                snapshot = cache.snapshot_for_file(path) if cache is not None else scan_document(path.read_text())
                if snapshot is not None:
                    append_document(path, snapshot)
    for path in library_files(cache):
        uri = path_to_uri(path)
        if open_documents is not None and uri in open_documents:
            append_document(path, open_documents[uri])
            continue
        snapshot = cache.snapshot_for_file(path) if cache is not None else scan_document(path.read_text())
        if snapshot is not None:
            append_document(path, snapshot)
    return documents


def extract_prompt_structure(text: str) -> dict[str, set[str]]:
    present: set[str] = set()
    profiles: set[str] = set()
    prompt_names: set[str] = set()
    line_fields = {
        "kind",
        "language",
        "depth",
        "deprecated",
        "quality_profile",
        "profile",
        "owner",
        "version",
        "compat",
        "role",
        "task",
        "targets",
    }
    block_fields = {
        "objective",
        "instructions",
        "deliverables",
        "quality_bar",
        "response_rules",
        "acceptance_criteria",
        "verification_plan",
        "assumptions",
        "questions_if_missing",
        "risks",
        "anti_patterns",
        "rules",
        "atoms",
        "exports",
        "contract",
    }
    brace_depth = 0
    in_triple = False
    for raw_line in text.splitlines():
        line = strip_comments(raw_line).strip()
        if not line:
            continue
        triple_count = raw_line.count('"""')
        if triple_count % 2 == 1:
            in_triple = not in_triple
        if line.startswith("prompt "):
            parts = line.split()
            if len(parts) >= 2:
                prompt_names.add(parts[1].strip('"'))
        if brace_depth == 1 and not in_triple:
            keyword = line.split()[0]
            if keyword in line_fields or keyword in block_fields:
                present.add(keyword)
            if keyword in {"quality_profile", "profile"}:
                match = re.match(r'^\s*(?:quality_profile|profile)\s+"?([A-Za-z0-9_.-]+)"?\s*$', line)
                if match:
                    profiles.add(match.group(1))
        if line.endswith("{"):
            brace_depth += 1
        if line == "}":
            brace_depth = max(0, brace_depth - 1)
    return {"present": present, "profiles": profiles, "prompt_names": prompt_names}


def semantic_structure_templates(text: str) -> list[tuple[str, str]]:
    structure = extract_prompt_structure(text)
    present = structure["present"]
    profiles = structure["profiles"]
    suggestions: list[tuple[str, str]] = []
    base_fields = [
        "kind",
        "language",
        "depth",
        "deprecated",
        "quality_profile",
        "role",
        "task",
        "objective",
        "instructions",
        "deliverables",
        "quality_bar",
        "response_rules",
        "rules",
    ]
    for field in base_fields:
        if field not in present and field in BLOCK_TEMPLATES:
            suggestions.append((field, BLOCK_TEMPLATES[field]))
    profile_fields = {
        "engineering": ["acceptance_criteria", "verification_plan"],
        "research": ["assumptions", "questions_if_missing"],
        "security": ["risks", "anti_patterns"],
    }
    for profile, fields in profile_fields.items():
        if profile not in profiles:
            continue
        for field in fields:
            if field not in present:
                suggestions.append((field, BLOCK_TEMPLATES[field]))
    return suggestions


def current_word_bounds(line: str, character: int) -> tuple[int, int]:
    left = min(max(0, character), len(line))
    right = left
    while left > 0 and re.match(r"[A-Za-z0-9_.-]", line[left - 1]):
        left -= 1
    while right < len(line) and re.match(r"[A-Za-z0-9_.-]", line[right]):
        right += 1
    return left, right


def replace_range(line_number: int, line: str, character: int) -> dict[str, Any]:
    start, end = current_word_bounds(line, character)
    return {
        "start": {"line": line_number, "character": start},
        "end": {"line": line_number, "character": end},
    }


def in_quoted_value(line: str, character: int) -> bool:
    prefix = line[: min(max(0, character), len(line))]
    return prefix.count('"') % 2 == 1 and '"""' not in prefix


def block_stack_until(text: str, line_number: int) -> list[str]:
    stack: list[str] = []
    for raw_line in text.splitlines()[: line_number + 1]:
        stripped = strip_comments(raw_line).strip()
        if stripped.endswith("{"):
            stack.append(stripped.split()[0])
        elif stripped == "}" and stack:
            stack.pop()
    return stack


def active_block_name(text: str, line_number: int) -> str | None:
    stack = block_stack_until(text, line_number)
    return stack[-1] if stack else None


def collect_block_values(text: str, block_name: str) -> list[str]:
    values: list[str] = []
    current: str | None = None
    for raw_line in text.splitlines():
        stripped = strip_comments(raw_line).strip()
        if stripped.endswith("{"):
            current = stripped.split()[0]
            continue
        if stripped == "}":
            current = None
            continue
        if current == block_name:
            match = re.match(r'^"(.+)"$', stripped)
            if match:
                values.append(match.group(1))
    return values


def gather_rule_atoms_from_text(text: str) -> list[str]:
    atoms: set[str] = set()
    current_block: str | None = None
    for raw_line in text.splitlines():
        stripped = strip_comments(raw_line).strip()
        if stripped.endswith("{"):
            current_block = stripped.split()[0]
            continue
        if stripped == "}":
            current_block = None
            continue
        if current_block in {"requires", "forbids", "mutually_exclusive"}:
            match = re.match(r'^"(.+)"$', stripped)
            if match:
                atoms.add(normalize_atom(match.group(1)))
        if current_block == "atoms":
            # Atom declarations: name : type ["description"]
            atom_match = re.match(r'^([A-Za-z0-9_.-]+)\s*:', stripped)
            if atom_match:
                atoms.add(atom_match.group(1))
        if current_block == "exports":
            # Export lines: bare or quoted atom name
            export_match = re.match(r'^"?([A-Za-z0-9_.-]+)"?$', stripped)
            if export_match:
                atoms.add(export_match.group(1))
        parts = stripped.split()
        if not parts:
            continue
        keyword = parts[0]
        if keyword == "must" and len(parts) >= 2:
            atoms.add(parts[1])
        elif keyword == "forbid" and len(parts) >= 2:
            atoms.add(parts[1])
        elif keyword == "implies" and len(parts) >= 3:
            atoms.add(parts[1])
            atoms.add(parts[2])
        elif keyword == "exclusive":
            atoms.update(parts[1:])
        elif keyword in {"at_least", "at_most", "exactly"} and len(parts) >= 4:
            atoms.update(parts[2:])
        elif keyword == "requires" and current_block == "contract" and len(parts) >= 2:
            atoms.add(parts[1])
        elif keyword == "forbids" and current_block == "contract" and len(parts) >= 2:
            atoms.add(parts[1])
        for embedded in re.finditer(r"\b(must|forbid):\s*([A-Za-z0-9_.-]+)", stripped):
            atoms.add(embedded.group(2))
        for embedded in re.finditer(r"\bimplies:\s*([A-Za-z0-9_.-]+)\s*->\s*([A-Za-z0-9_.-]+)", stripped):
            atoms.add(embedded.group(1))
            atoms.add(embedded.group(2))
        for embedded in re.finditer(r"\bexclusive:\s*([A-Za-z0-9_.\-\s]+)", stripped):
            atoms.update(token for token in embedded.group(1).split() if token)
    return sorted(atom for atom in atoms if atom)


def collect_rule_atoms(base_path: Path | None, text: str, seen: set[Path] | None = None) -> list[str]:
    atoms = set(gather_rule_atoms_from_text(text))
    if base_path is None:
        return sorted(atoms)
    seen = seen or set()
    if base_path in seen:
        return sorted(atoms)
    seen.add(base_path)
    for raw_line in text.splitlines():
        match = RE_IMPORT.match(strip_comments(raw_line))
        if not match:
            continue
        target = resolve_import_path(base_path, match.group(2))
        if target is None or target in seen:
            continue
        try:
            imported = target.read_text()
        except Exception:
            continue
        atoms.update(collect_rule_atoms(target, imported, seen))
    return sorted(atoms)


def collect_rule_atoms_cached(
    base_path: Path | None,
    snapshot: DocumentSnapshot,
    *,
    open_documents: dict[str, DocumentSnapshot] | None = None,
    cache: WorkspaceCache | None = None,
    seen: set[Path] | None = None,
) -> list[str]:
    atoms = set(snapshot.local_rule_atoms)
    if base_path is None:
        return sorted(atoms)
    seen = seen or set()
    if base_path in seen:
        return sorted(atoms)
    seen.add(base_path)
    for occurrence in snapshot.import_occurrences:
        target = resolve_import_path(base_path, occurrence["name"], cache)
        if target is None or target in seen:
            continue
        target_uri = path_to_uri(target)
        if open_documents is not None and target_uri in open_documents:
            imported_snapshot = open_documents[target_uri]
        else:
            imported_snapshot = cache.snapshot_for_file(target) if cache is not None else None
            if imported_snapshot is None:
                try:
                    imported_snapshot = scan_document(target.read_text())
                except Exception:
                    continue
        atoms.update(collect_rule_atoms_cached(target, imported_snapshot, open_documents=open_documents, cache=cache, seen=seen))
    return sorted(atoms)


def make_simple_diagnostic(message: str, line: int, severity: int) -> dict[str, Any]:
    return {
        "range": {
            "start": {"line": max(0, line), "character": 0},
            "end": {"line": max(0, line), "character": 200},
        },
        "severity": severity,
        "source": "pdsl-ls",
        "message": message,
    }


def run_process(command: list[str], *, input_text: str | None = None) -> tuple[int, str, str]:
    proc = subprocess.run(command, input=input_text, text=True, capture_output=True, timeout=15, check=False)
    return proc.returncode, proc.stdout, proc.stderr


def diagnostics_from_linter(path: Path, text: str, *, cache: WorkspaceCache | None = None) -> list[dict[str, Any]]:
    cache_key = (str(path), text)
    if cache is not None and cache_key in cache.lint_cache:
        return cache.lint_cache[cache_key]
    try:
        returncode, stdout, _ = run_process(["sh", str(lint_cmd()), "--stdin", "--path", str(path)], input_text=text)
    except Exception as exc:
        return [make_simple_diagnostic(f"No se pudo ejecutar pdsl_lint.hs: {exc}", 0, 1)]

    diagnostics: list[dict[str, Any]] = []
    for raw_line in stdout.splitlines():
        match = RE_DOC_LINE.match(raw_line.strip())
        if not match:
            continue
        _, line_no, column, severity_name, message = match.groups()
        diagnostics.append(
            {
                "range": {
                    "start": {"line": max(0, int(line_no) - 1), "character": max(0, int(column) - 1)},
                    "end": {"line": max(0, int(line_no) - 1), "character": max(0, int(column) + 120)},
                },
                "severity": 1 if severity_name == "error" else 2,
                "source": "pdsl-lint",
                "message": message,
            }
        )
    if not diagnostics and returncode not in (0, 1):
        diagnostics.append(make_simple_diagnostic("pdsl_lint.hs devolvio un error inesperado.", 0, 1))
    if cache is not None:
        cache.lint_cache[cache_key] = diagnostics
    return diagnostics


def format_via_cli(path: Path, text: str, *, cache: WorkspaceCache | None = None) -> str | None:
    cache_key = (str(path), text)
    if cache is not None and cache_key in cache.format_cache:
        return cache.format_cache[cache_key]
    try:
        returncode, stdout, _ = run_process(["sh", str(format_cmd()), "--stdin", "--path", str(path)], input_text=text)
    except Exception:
        return None
    if returncode != 0:
        return None
    if cache is not None:
        cache.format_cache[cache_key] = stdout
    return stdout


def export_super_xml(path: Path, text: str) -> tuple[Path, str]:
    target_path = path.with_suffix(".super.xml")
    temp_path: Path | None = None
    export_target = path
    try:
        if not path.exists() or path.read_text() != text:
            temp_dir = str(path.parent) if path.parent.exists() else None
            with tempfile.NamedTemporaryFile("w", suffix=".pdsl", dir=temp_dir, delete=False) as handle:
                handle.write(text)
                temp_path = Path(handle.name)
                export_target = temp_path
        returncode, stdout, stderr = run_process(["sh", str(export_cmd()), str(export_target)])
        if returncode != 0:
            detail = stderr.strip() or stdout.strip() or "pdsl_export fallo sin detalle."
            raise RuntimeError(detail)
        target_path.write_text(stdout)
        return target_path, stdout
    finally:
        if temp_path is not None:
            try:
                temp_path.unlink(missing_ok=True)
            except Exception:
                pass


def strip_comments(line: str) -> str:
    return line.split("#", 1)[0].rstrip()


def extract_import_at_position(text: str, line: int) -> str | None:
    lines = text.splitlines()
    if line < 0 or line >= len(lines):
        return None
    match = RE_IMPORT.match(strip_comments(lines[line]))
    return match.group(2) if match else None


def word_at_position(line: str, character: int) -> str:
    if not line:
        return ""
    left = character
    right = character
    while left > 0 and re.match(r"[A-Za-z0-9_.-]", line[left - 1]):
        left -= 1
    while right < len(line) and re.match(r"[A-Za-z0-9_.-]", line[right]):
        right += 1
    return line[left:right]


def occurrences_in_text(text: str, word: str) -> list[dict[str, Any]]:
    if not word:
        return []
    pattern = re.compile(rf"(?<![A-Za-z0-9_.-]){re.escape(word)}(?![A-Za-z0-9_.-])")
    occurrences: list[dict[str, Any]] = []
    for line_index, line in enumerate(text.splitlines()):
        for match in pattern.finditer(line):
            occurrences.append(
                {
                    "range": {
                        "start": {"line": line_index, "character": match.start()},
                        "end": {"line": line_index, "character": match.end()},
                    }
                }
            )
    return occurrences


def find_prompt_name(text: str) -> str | None:
    for line in text.splitlines():
        stripped = strip_comments(line).strip()
        if stripped.startswith("prompt "):
            parts = stripped.split()
            if len(parts) >= 2:
                return parts[1].strip('"')
    return None


def make_snippet_completion(snippet: dict[str, Any]) -> dict[str, Any]:
    return {
        "label": snippet["label"],
        "kind": 15,
        "detail": snippet["detail"],
        "documentation": {"kind": "markdown", "value": snippet["documentation"]},
        "insertText": snippet["body"],
        "insertTextFormat": 2,
        "sortText": "90_" + snippet["label"],
    }


def make_template_completion(
    label: str,
    template: str,
    line_number: int,
    line: str,
    character: int,
    *,
    detail: str = "PDSL semantic scaffold",
    documentation: str | None = None,
    sort_prefix: str = "03_",
) -> dict[str, Any]:
    item = {
        "label": label,
        "kind": 15,
        "detail": detail,
        "documentation": {"kind": "markdown", "value": documentation or KEYWORD_DOCS.get(label, detail)},
        "insertText": template,
        "insertTextFormat": 2,
        "sortText": sort_prefix + label,
    }
    text_edit = completion_text_edit(line_number, line, character, template)
    if text_edit is not None:
        item["textEdit"] = text_edit
    return item


def completion_text_edit(line_number: int | None, line: str | None, character: int | None, new_text: str) -> dict[str, Any] | None:
    if line_number is None or line is None or character is None:
        return None
    return {"range": replace_range(line_number, line, character), "newText": new_text}


def apply_completion_edit(item: dict[str, Any], line_number: int | None, line: str | None, character: int | None, new_text: str) -> dict[str, Any]:
    text_edit = completion_text_edit(line_number, line, character, new_text)
    item["insertText"] = new_text
    item["filterText"] = new_text
    if text_edit is not None:
        item["textEdit"] = text_edit
    return item


def make_keyword_completion(keyword: str, line_number: int | None = None, line: str | None = None, character: int | None = None) -> dict[str, Any]:
    return apply_completion_edit(
        {
        "label": keyword,
        "kind": 14,
        "detail": "PDSL keyword",
        "documentation": {"kind": "markdown", "value": KEYWORD_DOCS.get(keyword, f"PDSL keyword `{keyword}`.")},
        "sortText": "20_" + keyword,
        },
        line_number,
        line,
        character,
        keyword,
    )


def make_import_completion(
    name: str,
    line_number: int | None = None,
    line: str | None = None,
    character: int | None = None,
    *,
    detail: str = "Importable PDSL module",
    documentation: str | None = None,
    sort_prefix: str = "10_",
    insert_text: str | None = None,
) -> dict[str, Any]:
    return apply_completion_edit(
        {
        "label": name,
        "kind": 9,
        "detail": detail,
        "documentation": {"kind": "markdown", "value": documentation or f"Importa o extiende el modulo `{name}`."},
        "sortText": sort_prefix + name,
        },
        line_number,
        line,
        character,
        insert_text or name,
    )


def make_value_completion(label: str, detail: str, line_number: int, line: str, character: int) -> dict[str, Any]:
    return apply_completion_edit(
        {
        "label": label,
        "kind": 12,
        "detail": detail,
        "documentation": {"kind": "markdown", "value": detail},
        "sortText": "05_" + label,
        },
        line_number,
        line,
        character,
        label,
    )


def make_atom_completion(label: str, line_number: int, line: str, character: int) -> dict[str, Any]:
    return apply_completion_edit(
        {
        "label": label,
        "kind": 6,
        "detail": "PDSL rule atom",
        "documentation": {"kind": "markdown", "value": f"Atomo logico reusable: `{label}`."},
        "sortText": "08_" + label,
        },
        line_number,
        line,
        character,
        label,
    )


def complete_field_values(field_name: str, line_number: int, line: str, character: int) -> list[dict[str, Any]]:
    values = VALUE_COMPLETIONS.get(field_name, [])
    return [make_value_completion(value, f"Valor valido para `{field_name}`.", line_number, line, character) for value in values]


def completion_items_for_targets(line_number: int, line: str, character: int) -> list[dict[str, Any]]:
    return [make_value_completion(value, "Target de compilacion soportado.", line_number, line, character) for value in VALUE_COMPLETIONS["targets"]]


def completion_items_for_rule_atoms(
    base_path: Path | None,
    snapshot: DocumentSnapshot,
    line_number: int,
    line: str,
    character: int,
    *,
    open_documents: dict[str, DocumentSnapshot] | None = None,
    cache: WorkspaceCache | None = None,
) -> list[dict[str, Any]]:
    atoms = collect_rule_atoms_cached(base_path, snapshot, open_documents=open_documents, cache=cache)
    return [make_atom_completion(atom, line_number, line, character) for atom in atoms]


def context_source_completions(line_number: int, line: str, character: int) -> list[dict[str, Any]]:
    return [make_value_completion(value, "Origen valido para `context`.", line_number, line, character) for value in VALUE_COMPLETIONS["context_source"]]


def matches_field(prefix: str, field_name: str) -> bool:
    return re.match(rf"^\s*{re.escape(field_name)}\s+", prefix) is not None


def completing_context_source(prefix: str) -> bool:
    parts = prefix.strip().split()
    return len(parts) <= 2 and prefix.lstrip().startswith("context ")


def import_completion_items(base_path: Path | None, line_number: int, line: str, character: int, *, cache: WorkspaceCache | None = None) -> list[dict[str, Any]]:
    local_names = local_importable_names(base_path, cache)
    items: list[dict[str, Any]] = []
    for name in importable_names(base_path, cache):
        is_local = name in local_names
        items.append(
            make_import_completion(
                name,
                line_number,
                line,
                character,
                detail="Local PDSL module" if is_local else "Prompt-library module",
                documentation=f"Importa o extiende el modulo `{name}` desde {'el workspace actual' if is_local else 'la prompt-library'}.",
                sort_prefix="08_" if is_local else "10_",
            )
        )
    return items


def suggest_import_alias(import_name: str) -> str:
    alias = re.sub(r"[^A-Za-z0-9_]+", "_", import_name.split(".")[-1]).strip("_").lower()
    return alias or "module_ref"


def import_alias_completion_items(import_name: str, line_number: int, line: str, character: int) -> list[dict[str, Any]]:
    alias = suggest_import_alias(import_name)
    return [
        make_import_completion(
            alias,
            line_number,
            line,
            character,
            detail="Suggested alias",
            documentation=f"Sugiere `as {alias}` para reutilizar `{import_name}` con un alias corto.",
            sort_prefix="07_",
            insert_text=alias,
        )
    ]


def missing_root_line_completions(snapshot: DocumentSnapshot, line_number: int, line: str, character: int) -> list[dict[str, Any]]:
    present = snapshot.structure["present"]
    return [
        make_template_completion(
            field_name,
            template,
            line_number,
            line,
            character,
            detail="PDSL root field scaffold",
            documentation=f"Agrega la linea faltante `{field_name}`.",
            sort_prefix="02_",
        )
        for field_name, template in ROOT_LINE_TEMPLATES.items()
        if field_name not in present
    ]


def dedupe_completion_items(items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    seen: set[tuple[str, str]] = set()
    unique: list[dict[str, Any]] = []
    for item in items:
        key = (str(item.get("label", "")), str(item.get("insertText", item.get("label", ""))))
        if key in seen:
            continue
        seen.add(key)
        unique.append(item)
    return unique


def current_completion_prefix(line: str, character: int) -> str:
    start, end = current_word_bounds(line, character)
    cursor = min(max(start, character), end)
    return line[start:cursor].strip()


def completion_matches_prefix(label: str, prefix: str) -> bool:
    if not prefix:
        return True
    lowered_label = label.lower()
    lowered_prefix = prefix.lower()
    if lowered_label.startswith(lowered_prefix):
        return True
    return any(part.startswith(lowered_prefix) for part in re.split(r"[._-]+", lowered_label) if part)


def filter_completion_items(items: list[dict[str, Any]], prefix: str) -> list[dict[str, Any]]:
    if not prefix:
        return items
    return [item for item in items if completion_matches_prefix(str(item.get("label", "")), prefix)]


def inside_prompt_root(text: str, line_number: int) -> bool:
    stack = block_stack_until(text, line_number)
    return stack == ["prompt"]


def semantic_template_completions(snapshot: DocumentSnapshot, line_number: int, line: str, character: int) -> list[dict[str, Any]]:
    return [
        make_template_completion(
            label,
            template,
            line_number,
            line,
            character,
            detail="PDSL semantic scaffold",
            documentation=f"Agrega la estructura faltante `{label}`.",
        )
        for label, template in semantic_structure_templates(snapshot.text)
    ]


def render_completion_items(
    snapshot: DocumentSnapshot,
    line_number: int,
    character: int,
    base_path: Path | None,
    *,
    open_documents: dict[str, DocumentSnapshot] | None = None,
    cache: WorkspaceCache | None = None,
) -> list[dict[str, Any]]:
    line = snapshot.lines[line_number] if line_number < len(snapshot.lines) else ""
    prefix = line[: min(max(0, character), len(line))]
    stripped = prefix.lstrip()
    completion_prefix = current_completion_prefix(line, character)
    current_stack = snapshot.block_stack_by_line[line_number] if line_number < len(snapshot.block_stack_by_line) else ()
    current_block = current_stack[-1] if current_stack else None
    import_items = import_completion_items(base_path, line_number, line, character, cache=cache)
    keyword_items = [make_keyword_completion(keyword, line_number, line, character) for keyword in KEYWORD_COMPLETIONS]
    rule_items = [make_keyword_completion(keyword, line_number, line, character) for keyword in RULE_COMPLETIONS]
    snippet_items = [make_snippet_completion(snippet) for snippet in SNIPPETS]
    alias_match = re.match(r"^\s*(?:import|extends)\s+([A-Za-z0-9_.-]+)\s+as\s+[A-Za-z0-9_.-]*$", prefix)

    if alias_match:
        return import_alias_completion_items(alias_match.group(1), line_number, line, character)
    if stripped.startswith("import ") or stripped.startswith("extends "):
        return filter_completion_items(import_items, completion_prefix)
    if matches_field(prefix, "kind"):
        return complete_field_values("kind", line_number, line, character)
    if matches_field(prefix, "language"):
        return complete_field_values("language", line_number, line, character)
    if matches_field(prefix, "depth"):
        return complete_field_values("depth", line_number, line, character)
    if matches_field(prefix, "deprecated"):
        return complete_field_values("deprecated", line_number, line, character)
    if matches_field(prefix, "required"):
        return complete_field_values("required", line_number, line, character)
    if matches_field(prefix, "quality_profile"):
        return complete_field_values("quality_profile", line_number, line, character)
    if matches_field(prefix, "profile"):
        return complete_field_values("profile", line_number, line, character)
    if matches_field(prefix, "type"):
        return complete_field_values("type", line_number, line, character)
    if current_block == "targets" or matches_field(prefix, "targets"):
        return completion_items_for_targets(line_number, line, character)
    if completing_context_source(prefix):
        return context_source_completions(line_number, line, character)
    if stripped.startswith(tuple(keyword + " " for keyword in RULE_COMPLETIONS)):
        return completion_items_for_rule_atoms(base_path, snapshot, line_number, line, character, open_documents=open_documents, cache=cache) + rule_items
    if current_block == "rules":
        return dedupe_completion_items(filter_completion_items(
            completion_items_for_rule_atoms(base_path, snapshot, line_number, line, character, open_documents=open_documents, cache=cache)
            + rule_items
            + import_items
            + [make_snippet_completion(SNIPPETS[4]), make_snippet_completion(SNIPPETS[5])],
            completion_prefix,
        ))
    if current_block == "atoms":
        atom_type_items = [
            {
                "label": t,
                "kind": 21,
                "detail": "PDSL atom type",
                "documentation": KEYWORD_DOCS.get("atoms", ""),
            }
            for t in VALUE_COMPLETIONS["atom_type"]
        ]
        return filter_completion_items(atom_type_items, completion_prefix)
    if current_block in ("exports", "contract"):
        atom_name_items = completion_items_for_rule_atoms(base_path, snapshot, line_number, line, character, open_documents=open_documents, cache=cache)
        contract_kw_items = (
            [make_keyword_completion(k, line_number, line, character) for k in ["requires", "forbids"]]
            if current_block == "contract"
            else []
        )
        return dedupe_completion_items(filter_completion_items(atom_name_items + contract_kw_items, completion_prefix))
    semantic_items = semantic_template_completions(snapshot, line_number, line, character) if current_stack == ("prompt",) else []
    root_line_items = missing_root_line_completions(snapshot, line_number, line, character) if current_stack == ("prompt",) else []
    if prompt_exists(snapshot.text):
        return dedupe_completion_items(
            filter_completion_items(root_line_items + semantic_items + keyword_items + import_items + rule_items, completion_prefix)
            + filter_completion_items(snippet_items, completion_prefix)
        )
    return dedupe_completion_items(filter_completion_items(keyword_items + import_items + rule_items, completion_prefix) + filter_completion_items(snippet_items, completion_prefix))


def inside_rules_block(text: str, line_number: int) -> bool:
    lines = text.splitlines()[: line_number + 1]
    balance = 0
    for raw_line in lines:
        line = strip_comments(raw_line).strip()
        if line == "rules {":
            balance += 1
        elif line == "}" and balance > 0:
            balance -= 1
    return balance > 0


def make_symbol(name: str, kind: int, line: int, end_character: int) -> dict[str, Any]:
    return {
        "name": name,
        "kind": kind,
        "range": {
            "start": {"line": line, "character": 0},
            "end": {"line": line, "character": max(1, end_character)},
        },
        "selectionRange": {
            "start": {"line": line, "character": 0},
            "end": {"line": line, "character": max(1, end_character)},
        },
    }


def make_document_symbol(
    name: str,
    kind: int,
    selection_range: dict[str, Any],
    *,
    full_range: dict[str, Any] | None = None,
    children: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    symbol = {
        "name": name,
        "kind": kind,
        "range": full_range or selection_range,
        "selectionRange": selection_range,
    }
    if children:
        symbol["children"] = children
    return symbol


def flatten_document_symbols(symbols: list[dict[str, Any]]) -> list[dict[str, Any]]:
    flattened: list[dict[str, Any]] = []
    for symbol in symbols:
        flattened.append({"name": symbol["name"], "kind": symbol["kind"], "range": symbol["range"]})
        children = symbol.get("children", [])
        if children:
            flattened.extend(flatten_document_symbols(children))
    return flattened


def collect_document_symbols(text: str) -> list[dict[str, Any]]:
    prompt_occurrences = scan_prompt_occurrences(text)
    import_occurrences = scan_import_occurrences(text)
    alias_occurrences = scan_import_alias_occurrences(text)
    param_occurrences = scan_param_occurrences(text)
    section_occurrences = scan_section_occurrences(text)
    atom_occurrences = scan_rule_atom_occurrences(text)
    if prompt_occurrences:
        prompt_occurrence = prompt_occurrences[0]
        prompt_range = find_block_range(text, "prompt") or prompt_occurrence["range"]
        children: list[dict[str, Any]] = []
        for occurrence in sorted(import_occurrences, key=lambda entry: (entry["range"]["start"]["line"], entry["range"]["start"]["character"])):
            children.append(make_document_symbol(f"import {occurrence['name']}", 3, occurrence["range"]))
        for occurrence in sorted(alias_occurrences, key=lambda entry: (entry["range"]["start"]["line"], entry["range"]["start"]["character"])):
            children.append(make_document_symbol(f"alias {occurrence['name']}", 13, occurrence["range"]))
        for occurrence in sorted(param_occurrences, key=lambda entry: (entry["range"]["start"]["line"], entry["range"]["start"]["character"])):
            children.append(make_document_symbol(occurrence["name"], 13, occurrence["range"]))
        for occurrence in sorted(section_occurrences, key=lambda entry: (entry["range"]["start"]["line"], entry["range"]["start"]["character"])):
            children.append(make_document_symbol(occurrence["name"], 5, occurrence["range"]))
        for occurrence in sorted(atom_occurrences, key=lambda entry: (entry["range"]["start"]["line"], entry["range"]["start"]["character"])):
            children.append(make_document_symbol(f"atom {occurrence['name']}", 14, occurrence["range"]))
        return [make_document_symbol(prompt_occurrence["name"], 5, prompt_occurrence["range"], full_range=prompt_range, children=children)]

    symbols: list[dict[str, Any]] = []
    for index, raw_line in enumerate(text.splitlines()):
        stripped = strip_comments(raw_line)
        if not stripped:
            continue
        for pattern, kind in RE_SYMBOLS:
            match = pattern.match(stripped)
            if match:
                base = make_symbol(match.group(1).strip('"'), kind, index, len(stripped))
                symbols.append(make_document_symbol(base["name"], base["kind"], base["selectionRange"], full_range=base["range"]))
                break
    return symbols


def collect_workspace_symbols(query: str, *, cache: WorkspaceCache | None = None) -> list[dict[str, Any]]:
    query_lower = query.lower()
    results: list[dict[str, Any]] = []
    if cache is not None:
        source_symbols = cache.indexed_symbols()
    else:
        source_symbols = []
        for path in library_files():
            try:
                snapshot = scan_document(path.read_text())
            except Exception:
                continue
            for symbol in flatten_document_symbols(snapshot.document_symbols):
                source_symbols.append(
                    {
                        "name": symbol["name"],
                        "kind": symbol["kind"],
                        "location": {"uri": path_to_uri(path), "range": symbol["range"]},
                    }
                )
    for symbol in source_symbols:
        if cache is not None:
            if query_lower and query_lower not in symbol["name"].lower():
                continue
            results.append(
                {
                    "name": symbol["name"],
                    "kind": symbol["kind"],
                    "location": {"uri": symbol["uri"], "range": symbol["range"]},
                }
            )
        else:
            if query_lower and query_lower not in symbol["name"].lower():
                continue
            results.append(symbol)
    return results[:200]


def make_named_occurrence(name: str, line: int, start: int, end: int, kind: str) -> dict[str, Any]:
    return {"name": name, "kind": kind, "range": make_range(line, start, line, end)}


def range_contains(position: dict[str, Any], occurrence_range: dict[str, Any]) -> bool:
    line = position["line"]
    character = position["character"]
    start = occurrence_range["start"]
    end = occurrence_range["end"]
    return start["line"] == line == end["line"] and start["character"] <= character <= end["character"]


def scan_import_occurrences(text: str) -> list[dict[str, Any]]:
    occurrences: list[dict[str, Any]] = []
    for line_index, raw_line in enumerate(text.splitlines()):
        stripped = strip_comments(raw_line)
        match = RE_IMPORT.match(stripped)
        if not match:
            continue
        name = match.group(2)
        start = raw_line.find(name)
        if start >= 0:
            occurrences.append(make_named_occurrence(name, line_index, start, start + len(name), "import"))
    return occurrences


def scan_import_alias_occurrences(text: str) -> list[dict[str, Any]]:
    occurrences: list[dict[str, Any]] = []
    for line_index, raw_line in enumerate(text.splitlines()):
        stripped = strip_comments(raw_line)
        match = RE_IMPORT.match(stripped)
        if not match or match.group(3) is None:
            continue
        alias = match.group(3)
        start = raw_line.rfind(alias)
        if start >= 0:
            occurrences.append(make_named_occurrence(alias, line_index, start, start + len(alias), "alias"))
    return occurrences


def scan_prompt_occurrences(text: str) -> list[dict[str, Any]]:
    occurrences: list[dict[str, Any]] = []
    for line_index, raw_line in enumerate(text.splitlines()):
        stripped = strip_comments(raw_line)
        match = re.match(r'^\s*prompt\s+("[^"]+"|[A-Za-z0-9_.-]+)\s*\{', stripped)
        if not match:
            continue
        name = match.group(1).strip('"')
        start = raw_line.find(match.group(1))
        if start >= 0:
            occurrences.append(make_named_occurrence(name, line_index, start, start + len(match.group(1)), "prompt"))
    return occurrences


def scan_param_occurrences(text: str) -> list[dict[str, Any]]:
    occurrences: list[dict[str, Any]] = []
    for line_index, raw_line in enumerate(text.splitlines()):
        stripped = strip_comments(raw_line)
        match = re.match(r'^\s*param\s+("[^"]+"|[A-Za-z0-9_.-]+)\s+\{', stripped)
        if not match:
            continue
        name = match.group(1).strip('"')
        start = raw_line.find(match.group(1))
        if start >= 0:
            occurrences.append(make_named_occurrence(name, line_index, start, start + len(match.group(1)), "param"))
    return occurrences


def scan_section_occurrences(text: str) -> list[dict[str, Any]]:
    occurrences: list[dict[str, Any]] = []
    for line_index, raw_line in enumerate(text.splitlines()):
        stripped = strip_comments(raw_line)
        match = re.match(r'^\s*section\s+("[^"]+"|[A-Za-z0-9_.-]+)\s+"""', stripped)
        if not match:
            continue
        name = match.group(1).strip('"')
        start = raw_line.find(match.group(1))
        if start >= 0:
            occurrences.append(make_named_occurrence(name, line_index, start, start + len(match.group(1)), "section"))
    return occurrences


def scan_rule_atom_occurrences(text: str) -> list[dict[str, Any]]:
    occurrences: list[dict[str, Any]] = []
    current_block: str | None = None
    for line_index, raw_line in enumerate(text.splitlines()):
        stripped = strip_comments(raw_line).strip()
        if stripped.endswith("{"):
            current_block = stripped.split()[0]
        elif stripped == "}":
            current_block = None
            continue
        if current_block == "rules":
            for match in re.finditer(r'\b(?:must|forbid)\s+([A-Za-z0-9_.-]+)', raw_line):
                atom = match.group(1)
                occurrences.append(make_named_occurrence(atom, line_index, match.start(1), match.end(1), "atom"))
            for match in re.finditer(r'\bimplies\s+([A-Za-z0-9_.-]+)\s+([A-Za-z0-9_.-]+)', raw_line):
                occurrences.append(make_named_occurrence(match.group(1), line_index, match.start(1), match.end(1), "atom"))
                occurrences.append(make_named_occurrence(match.group(2), line_index, match.start(2), match.end(2), "atom"))
            for match in re.finditer(r'\b(?:exclusive|at_least|at_most|exactly)\b[^\n#"]*', raw_line):
                body = match.group(0)
                for token in re.finditer(r'[A-Za-z0-9_.-]+', body):
                    value = token.group(0)
                    if value in RULE_COMPLETIONS or value.isdigit():
                        continue
                    occurrences.append(make_named_occurrence(value, line_index, match.start() + token.start(), match.start() + token.end(), "atom"))
        for match in re.finditer(r'\b(?:must|forbid):\s*([A-Za-z0-9_.-]+)', raw_line):
            occurrences.append(make_named_occurrence(match.group(1), line_index, match.start(1), match.end(1), "atom"))
        for match in re.finditer(r'\bimplies:\s*([A-Za-z0-9_.-]+)\s*->\s*([A-Za-z0-9_.-]+)', raw_line):
            occurrences.append(make_named_occurrence(match.group(1), line_index, match.start(1), match.end(1), "atom"))
            occurrences.append(make_named_occurrence(match.group(2), line_index, match.start(2), match.end(2), "atom"))
    return occurrences


def all_named_occurrences(text: str) -> list[dict[str, Any]]:
    return (
        scan_import_occurrences(text)
        + scan_import_alias_occurrences(text)
        + scan_prompt_occurrences(text)
        + scan_param_occurrences(text)
        + scan_section_occurrences(text)
        + scan_rule_atom_occurrences(text)
    )


def build_block_stack_by_line(lines: list[str]) -> list[tuple[str, ...]]:
    stack: list[str] = []
    snapshots: list[tuple[str, ...]] = []
    for raw_line in lines:
        stripped = strip_comments(raw_line).strip()
        if stripped == "}" and stack:
            stack.pop()
        snapshots.append(tuple(stack))
        if stripped.endswith("{"):
            stack.append(stripped.split()[0])
    return snapshots


def scan_empty_blocks(lines: list[str]) -> list[dict[str, Any]]:
    empty_blocks: list[dict[str, Any]] = []
    for index, raw_line in enumerate(lines[:-1]):
        stripped = strip_comments(raw_line).strip()
        if not stripped.endswith("{"):
            continue
        next_line = strip_comments(lines[index + 1]).strip()
        if next_line == "}":
            block_name = stripped.split()[0]
            empty_blocks.append({"name": block_name, "range": make_range(index, 0, index + 1, len(lines[index + 1]))})
    return empty_blocks


def scan_document(text: str) -> DocumentSnapshot:
    lines = text.splitlines()
    structure = extract_prompt_structure(text)
    import_occurrences = scan_import_occurrences(text)
    alias_occurrences = scan_import_alias_occurrences(text)
    prompt_occurrences = scan_prompt_occurrences(text)
    param_occurrences = scan_param_occurrences(text)
    section_occurrences = scan_section_occurrences(text)
    atom_occurrences = scan_rule_atom_occurrences(text)
    named_occurrences = import_occurrences + alias_occurrences + prompt_occurrences + param_occurrences + section_occurrences + atom_occurrences
    return DocumentSnapshot(
        text=text,
        lines=lines,
        structure=structure,
        document_symbols=collect_document_symbols(text),
        import_occurrences=import_occurrences,
        alias_occurrences=alias_occurrences,
        prompt_occurrences=prompt_occurrences,
        param_occurrences=param_occurrences,
        section_occurrences=section_occurrences,
        atom_occurrences=atom_occurrences,
        named_occurrences=named_occurrences,
        local_rule_atoms=gather_rule_atoms_from_text(text),
        block_stack_by_line=build_block_stack_by_line(lines),
        empty_blocks=scan_empty_blocks(lines),
    )


def symbol_context_at_position(snapshot: DocumentSnapshot, position: dict[str, Any]) -> dict[str, Any] | None:
    line_text = snapshot.lines[position["line"]] if position["line"] < len(snapshot.lines) else ""
    word = word_at_position(line_text, position["character"])
    for occurrence in snapshot.named_occurrences:
        if range_contains(position, occurrence["range"]):
            return occurrence
    if word in KEYWORD_DOCS:
        return {"name": word, "kind": "keyword", "range": replace_range(position["line"], line_text, position["character"])}
    return None


def resolve_alias_import_name(snapshot: DocumentSnapshot, alias_name: str) -> str | None:
    for raw_line in snapshot.lines:
        match = RE_IMPORT.match(strip_comments(raw_line))
        if match and match.group(3) == alias_name:
            return match.group(2)
    return None


def make_location(uri: str, occurrence_range: dict[str, Any]) -> dict[str, Any]:
    return {"uri": uri, "range": occurrence_range}


def collect_document_links(
    base_path: Path | None,
    snapshot: DocumentSnapshot,
    *,
    cache: WorkspaceCache | None = None,
) -> list[dict[str, Any]]:
    if base_path is None:
        return []
    links: list[dict[str, Any]] = []
    for occurrence in snapshot.import_occurrences:
        target = resolve_import_path(base_path, occurrence["name"], cache)
        if target is None:
            continue
        line_number = occurrence["range"]["start"]["line"]
        line_text = snapshot.lines[line_number] if line_number < len(snapshot.lines) else ""
        relation = "extends" if line_text.lstrip().startswith("extends") else "import"
        target_snapshot = cache.snapshot_for_file(target) if cache is not None else None
        target_prompt = prompt_name_for_snapshot(target_snapshot) or target.name
        links.append(
            {
                "range": occurrence["range"],
                "target": path_to_uri(target),
                "tooltip": f"Abrir {relation} `{occurrence['name']}` -> {target_prompt}",
            }
        )
    return links


def prompt_definition_location(path: Path, *, cache: WorkspaceCache | None = None, open_documents: dict[str, DocumentSnapshot] | None = None) -> dict[str, Any]:
    target_uri = path_to_uri(path)
    snapshot = open_documents[target_uri] if open_documents is not None and target_uri in open_documents else (cache.snapshot_for_file(path) if cache is not None else None)
    if snapshot is None:
        snapshot = scan_document(path.read_text())
    occurrence = snapshot.prompt_occurrences[0] if snapshot.prompt_occurrences else None
    return {"uri": target_uri, "range": occurrence["range"] if occurrence is not None else make_range(0, 0, 0, 0)}


def prompt_hover_header(
    title: str,
    path: Path | None,
    snapshot: DocumentSnapshot,
    *,
    open_documents: dict[str, DocumentSnapshot] | None = None,
    cache: WorkspaceCache | None = None,
) -> list[str]:
    profiles = sorted(snapshot.structure["profiles"])
    imports = collect_import_specs(snapshot)
    import_chain = collect_import_chain(path, snapshot, open_documents=open_documents, cache=cache) if path is not None else []
    lines = [title, ""]
    if path is not None:
        lines.append(f"- **path**: `{path}`")
    kind = extract_scalar_field(snapshot.text, "kind")
    if kind is not None:
        lines.append(f"- **kind**: `{kind}`")
    if profiles:
        lines.append(f"- **profiles**: `{', '.join(profiles)}`")
    if imports:
        rendered = ", ".join(f"{spec['relation']} {spec['name']}" + (f" as {spec['alias']}" if spec['alias'] else "") for spec in imports[:6])
        lines.append(f"- **imports**: `{rendered}`")
    if import_chain:
        lines.append(f"- **import-chain**: `{' -> '.join(import_chain[:6])}`")
    if snapshot.local_rule_atoms:
        lines.append(f"- **local-atoms**: `{', '.join(snapshot.local_rule_atoms[:8])}`")
    return lines


def workspace_symbol_occurrences(
    base_path: Path | None,
    current_uri: str,
    current_snapshot: DocumentSnapshot,
    context: dict[str, Any],
    *,
    open_documents: dict[str, DocumentSnapshot] | None = None,
    cache: WorkspaceCache | None = None,
) -> list[dict[str, Any]]:
    kind = context["kind"]
    name = context["name"]
    results: list[dict[str, Any]] = []
    for path, snapshot in iter_workspace_documents(base_path, current_uri, current_snapshot.text, open_documents=open_documents, cache=cache):
        uri = current_uri if base_path is not None and path == base_path else path_to_uri(path)
        occurrences = snapshot.named_occurrences
        if kind == "prompt":
            relevant = [entry for entry in occurrences if (entry["kind"] == "prompt" and entry["name"] == name) or (entry["kind"] == "import" and entry["name"] == name)]
        elif kind == "import":
            relevant = [entry for entry in occurrences if entry["kind"] == "import" and entry["name"] == name]
        elif kind == "alias":
            relevant = [entry for entry in occurrences if entry["kind"] == "alias" and entry["name"] == name]
        elif kind == "atom":
            relevant = [entry for entry in occurrences if entry["kind"] == "atom" and entry["name"] == name]
        elif kind in {"param", "section"}:
            if base_path is None or path != base_path:
                continue
            relevant = [entry for entry in occurrences if entry["kind"] == kind and entry["name"] == name]
        else:
            relevant = []
        results.extend(make_location(uri, entry["range"]) for entry in relevant)
    return results


def rename_workspace_occurrences(
    base_path: Path | None,
    current_uri: str,
    current_snapshot: DocumentSnapshot,
    context: dict[str, Any],
    new_name: str,
    *,
    open_documents: dict[str, DocumentSnapshot] | None = None,
    cache: WorkspaceCache | None = None,
) -> dict[str, Any] | None:
    if not new_name:
        return None
    changes: dict[str, list[dict[str, Any]]] = {}
    for location in workspace_symbol_occurrences(base_path, current_uri, current_snapshot, context, open_documents=open_documents, cache=cache):
        changes.setdefault(location["uri"], []).append({"range": location["range"], "newText": new_name})
    return {"changes": changes} if changes else None


def parse_explain_output(stdout: str) -> str | None:
    if not stdout.strip():
        return None
    lines = stdout.splitlines()
    sections: dict[str, list[str]] = {}
    current: str | None = None
    for line in lines:
        if line.endswith(":") and not line.startswith("  - "):
            current = line[:-1]
            sections.setdefault(current, [])
            continue
        if current is not None:
            sections[current].append(line)
    header_lines = []
    for key in ["name", "kind", "imports", "quality-profiles", "targets"]:
        matching = next((line.split(": ", 1)[1] for line in lines if line.startswith(f"{key}: ")), None)
        if matching is not None:
            header_lines.append(f"- **{key}**: `{matching}`")
    effective_rules = [line.strip() for line in sections.get("effective-rules", []) if line.strip()]
    token_lines = [line.strip() for line in sections.get("token-report", []) if line.strip()]
    smt_lines = [line.strip() for line in sections.get("smt-report", []) if line.strip()]
    xml_preview_lines = [line for line in sections.get("compiled-xml-preview", []) if line.strip()][:18]
    preview_lines = [line for line in sections.get("compiled-markdown-preview", []) if line.strip()][:18]
    body: list[str] = []
    if header_lines:
        body.extend(header_lines)
    if effective_rules:
        body.append("\n**effective-rules**")
        body.extend(f"- {line.removeprefix('- ').strip()}" for line in effective_rules[:8])
    if token_lines:
        body.append("\n**token-report**")
        body.extend(f"- `{line}`" for line in token_lines[:8])
    if smt_lines:
        body.append("\n**smt-report**")
        body.extend(f"- {line.removeprefix('- ').strip()}" for line in smt_lines[:10])
    if xml_preview_lines:
        body.append("\n**compiled-xml-preview**")
        body.append("```xml")
        body.extend(xml_preview_lines)
        body.append("```")
    if preview_lines:
        body.append("\n**compiled-preview**")
        body.append("```markdown")
        body.extend(preview_lines)
        body.append("```")
    return "\n".join(body) if body else None


def explain_summary_for_document(path: Path, text: str, *, cache: WorkspaceCache | None = None) -> str | None:
    cache_key = (str(path), text)
    if cache is not None and cache_key in cache.explain_cache:
        return cache.explain_cache[cache_key]
    temp_path: Path | None = None
    explain_target = path
    try:
        if not path.exists() or path.read_text() != text:
            temp_dir = str(path.parent) if path.parent.exists() else None
            with tempfile.NamedTemporaryFile("w", suffix=".pdsl", dir=temp_dir, delete=False) as handle:
                handle.write(text)
                temp_path = Path(handle.name)
                explain_target = temp_path
        returncode, stdout, _ = run_process(["sh", str(explain_cmd()), str(explain_target)])
    except Exception:
        return None
    finally:
        if temp_path is not None:
            try:
                temp_path.unlink(missing_ok=True)
            except Exception:
                pass
    if returncode not in (0, 1):
        return None
    summary = parse_explain_output(stdout)
    if cache is not None:
        cache.explain_cache[cache_key] = summary
    return summary


def fast_structural_diagnostics(
    path: Path,
    snapshot: DocumentSnapshot,
    *,
    open_documents: dict[str, DocumentSnapshot] | None = None,
    cache: WorkspaceCache | None = None,
) -> list[dict[str, Any]]:
    diagnostics: list[dict[str, Any]] = []
    seen_imports: dict[str, dict[str, int]] = {}
    seen_sections: dict[str, dict[str, int]] = {}
    seen_params: dict[str, dict[str, int]] = {}
    seen_atoms: dict[str, dict[str, int]] = {}
    for occurrence in snapshot.import_occurrences:
        seen_imports.setdefault(occurrence["name"], occurrence["range"]["start"])
        if occurrence["name"] in seen_imports and seen_imports[occurrence["name"]] != occurrence["range"]["start"]:
            diagnostics.append(
                {
                    "range": occurrence["range"],
                    "severity": 2,
                    "source": "pdsl-ls",
                    "message": f"Import duplicado: `{occurrence['name']}`.",
                }
            )
        if resolve_import_path(path, occurrence["name"], cache) is None:
            diagnostics.append(
                {
                    "range": occurrence["range"],
                    "severity": 1,
                    "source": "pdsl-ls",
                    "message": f"No se pudo resolver import `{occurrence['name']}`.",
                }
            )
    for occurrence, seen in (
        *[(entry, seen_sections) for entry in snapshot.section_occurrences],
        *[(entry, seen_params) for entry in snapshot.param_occurrences],
        *[(entry, seen_atoms) for entry in snapshot.atom_occurrences],
    ):
        if occurrence["name"] in seen:
            diagnostics.append(
                {
                    "range": occurrence["range"],
                    "severity": 2,
                    "source": "pdsl-ls",
                    "message": f"{occurrence['kind']} duplicado: `{occurrence['name']}`.",
                }
            )
        else:
            seen[occurrence["name"]] = occurrence["range"]["start"]
    for occurrence in snapshot.alias_occurrences:
        if len(occurrences_in_text(snapshot.text, occurrence["name"])) <= 1:
            diagnostics.append(
                {
                    "range": occurrence["range"],
                    "severity": 2,
                    "source": "pdsl-ls",
                    "message": f"Alias posiblemente no usado: `{occurrence['name']}`.",
                }
            )
    for occurrence in snapshot.param_occurrences:
        if len(occurrences_in_text(snapshot.text, occurrence["name"])) <= 1:
            diagnostics.append(
                {
                    "range": occurrence["range"],
                    "severity": 2,
                    "source": "pdsl-ls",
                    "message": f"Parametro posiblemente no usado: `{occurrence['name']}`.",
                }
            )
    for occurrence in snapshot.section_occurrences:
        if len(occurrences_in_text(snapshot.text, occurrence["name"])) <= 1:
            diagnostics.append(
                {
                    "range": occurrence["range"],
                    "severity": 2,
                    "source": "pdsl-ls",
                    "message": f"Seccion posiblemente no usada: `{occurrence['name']}`.",
                }
            )
    for block in snapshot.empty_blocks:
        diagnostics.append(
            {
                "range": block["range"],
                "severity": 2,
                "source": "pdsl-ls",
                "message": f"Bloque vacio: `{block['name']}`.",
            }
        )
    for line_index, raw_line in enumerate(snapshot.lines):
        for match in re.finditer(r"\b(?:must|forbid|implies|exclusive|at_least|at_most|exactly):", raw_line):
            diagnostics.append(
                {
                    "range": make_range(line_index, match.start(), line_index, match.end()),
                    "severity": 2,
                    "source": "pdsl-ls",
                    "message": "Conviene mover reglas embebidas de `response_rules` a un bloque `rules` formal.",
                }
            )
    if "rules" in snapshot.structure["present"] and not snapshot.atom_occurrences:
        diagnostics.append(
            {
                "range": find_block_range(snapshot.text, "rules") or make_range(0, 0, 0, 0),
                "severity": 2,
                "source": "pdsl-ls",
                "message": "El bloque `rules` existe pero no contiene atomos detectables.",
            }
        )
    return diagnostics


def dedupe_lsp_diagnostics(diagnostics: list[dict[str, Any]]) -> list[dict[str, Any]]:
    seen: set[tuple[Any, ...]] = set()
    unique: list[dict[str, Any]] = []
    for diagnostic in diagnostics:
        start = diagnostic.get("range", {}).get("start", {})
        key = (start.get("line"), start.get("character"), diagnostic.get("severity"), diagnostic.get("message"))
        if key in seen:
            continue
        seen.add(key)
        unique.append(diagnostic)
    return unique

def document_has_block(text: str, block_name: str) -> bool:
    if block_name in {"role", "task"}:
        return any(strip_comments(line).strip().startswith(f"{block_name} ") for line in text.splitlines())
    if block_name == "objective":
        return any(strip_comments(line).strip().startswith("objective ") for line in text.splitlines())
    return any(strip_comments(line).strip() == f"{block_name} {{" for line in text.splitlines())


def prompt_exists(text: str) -> bool:
    return any(strip_comments(line).strip().startswith("prompt ") for line in text.splitlines())


def find_closing_brace_line(text: str) -> int:
    lines = text.splitlines()
    for index in range(len(lines) - 1, -1, -1):
        if lines[index].strip() == "}":
            return index
    return len(lines)


def find_metadata_insert_line(text: str) -> int:
    lines = text.splitlines()
    for index, line in enumerate(lines):
        stripped = strip_comments(line).strip()
        if stripped.startswith(("role ", "task ", "objective ", "instructions {", "deliverables {")):
            return index
    return min(len(lines), 4)


def normalize_insert_text(text: str, *, leading_blank: bool = True) -> str:
    prefix = "\n" if leading_blank else ""
    return prefix + "  " + text.replace("\n", "\n  ") + "\n"


def make_workspace_edit(uri: str, line: int, character: int, new_text: str) -> dict[str, Any]:
    return {
        "changes": {
            uri: [
                {
                    "range": {
                        "start": {"line": line, "character": character},
                        "end": {"line": line, "character": character},
                    },
                    "newText": new_text,
                }
            ]
        }
    }


def append_block_action(uri: str, text: str, block_name: str, title: str) -> dict[str, Any]:
    closing_line = find_closing_brace_line(text)
    snippet = BLOCK_TEMPLATES[block_name]
    return {
        "title": title,
        "kind": "quickfix",
        "edit": make_workspace_edit(uri, closing_line, 0, normalize_insert_text(snippet)),
    }


def insert_metadata_action(uri: str, text: str, block_name: str, title: str) -> dict[str, Any]:
    insert_line = find_metadata_insert_line(text)
    snippet = "  " + BLOCK_TEMPLATES[block_name] + "\n"
    return {
        "title": title,
        "kind": "quickfix",
        "edit": make_workspace_edit(uri, insert_line, 0, snippet),
    }


def materialize_legacy_rules_action(uri: str, text: str) -> dict[str, Any] | None:
    rules = synthesize_rules_from_legacy(text)
    if not rules:
        return None
    return {
        "title": "Materializar restricciones legacy en `rules`",
        "kind": "refactor.rewrite",
        "edit": make_workspace_edit(uri, find_closing_brace_line(text), 0, normalize_insert_text("rules {\n" + rules + "\n}")),
    }


def materialize_embedded_rules_action(uri: str, text: str) -> dict[str, Any] | None:
    rules = synthesize_rules_from_embedded(text)
    if not rules:
        return None
    return {
        "title": "Extraer reglas embebidas a `rules`",
        "kind": "refactor.extract",
        "edit": make_workspace_edit(uri, find_closing_brace_line(text), 0, normalize_insert_text("rules {\n" + rules + "\n}")),
    }


def synthesize_rules_from_legacy(text: str) -> str:
    lines = text.splitlines()
    chunks: list[str] = []
    requires = collect_list_block(lines, "requires")
    forbids = collect_list_block(lines, "forbids")
    mutually_exclusive = collect_list_block(lines, "mutually_exclusive")
    for value in requires:
        chunks.append(f"  must {normalize_atom(value)}")
    for value in forbids:
        chunks.append(f"  forbid {normalize_atom(value)}")
    if len(mutually_exclusive) >= 2:
        chunks.append("  exclusive " + " ".join(normalize_atom(value) for value in mutually_exclusive))
    return "\n".join(chunks)


def synthesize_rules_from_embedded(text: str) -> str:
    chunks: list[str] = []
    seen: set[str] = set()
    for raw_line in text.splitlines():
        stripped = strip_comments(raw_line).strip().strip('"')
        for match in re.finditer(r"\b(must|forbid):\s*([A-Za-z0-9_.-]+)", stripped):
            rendered = f"  {match.group(1)} {match.group(2)}"
            if rendered not in seen:
                seen.add(rendered)
                chunks.append(rendered)
        for match in re.finditer(r"\bimplies:\s*([A-Za-z0-9_.-]+)\s*->\s*([A-Za-z0-9_.-]+)", stripped):
            rendered = f"  implies {match.group(1)} {match.group(2)}"
            if rendered not in seen:
                seen.add(rendered)
                chunks.append(rendered)
        for match in re.finditer(r"\bexclusive:\s*([A-Za-z0-9_.\-\s]+)", stripped):
            atoms = " ".join(token for token in match.group(1).split() if token)
            if atoms:
                rendered = f"  exclusive {atoms}"
                if rendered not in seen:
                    seen.add(rendered)
                    chunks.append(rendered)
    return "\n".join(chunks)


def collect_list_block(lines: list[str], block_name: str) -> list[str]:
    values: list[str] = []
    inside = False
    for raw_line in lines:
        stripped = strip_comments(raw_line).strip()
        if stripped == f"{block_name} {{":
            inside = True
            continue
        if inside and stripped == "}":
            break
        if inside:
            match = re.match(r'^"(.+)"$', stripped)
            if match:
                values.append(match.group(1))
    return values


def normalize_atom(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9]+", "-", value.strip()).strip("-").lower() or "unnamed-atom"


def format_document_action(uri: str, path: Path | None, text: str, *, cache: WorkspaceCache | None = None) -> dict[str, Any] | None:
    if path is None:
        return None
    formatted = format_via_cli(path, text, cache=cache)
    if formatted is None or formatted == text:
        return None
    return {
        "title": "Normalizar documento con `pdsl_format`",
        "kind": "source.fixAll",
        "edit": {"changes": {uri: [{"range": full_document_range(text), "newText": formatted}]}},
    }


def export_super_xml_action(uri: str, path: Path | None) -> dict[str, Any] | None:
    if path is None:
        return None
    return {
        "title": "Exportar super XML resuelto",
        "kind": "source",
        "command": {
            "title": "Exportar super XML resuelto",
            "command": "pdsl.exportSuperXml",
            "arguments": [uri],
        },
    }


def profile_remediation_actions(uri: str, text: str) -> list[dict[str, Any]]:
    actions: list[dict[str, Any]] = []
    profiles = extract_prompt_structure(text)["profiles"]
    missing_by_profile = {
        "engineering": {"acceptance_criteria": "Agregar `acceptance_criteria`", "verification_plan": "Agregar `verification_plan`"},
        "research": {"assumptions": "Agregar `assumptions`", "questions_if_missing": "Agregar `questions_if_missing`"},
        "security": {"risks": "Agregar `risks`", "anti_patterns": "Agregar `anti_patterns`"},
    }
    for profile, fields in missing_by_profile.items():
        if profile not in profiles:
            continue
        for field_name, title in fields.items():
            if not document_has_block(text, field_name):
                actions.append(append_block_action(uri, text, field_name, title))
    return actions


def unresolved_import_actions(
    uri: str,
    path: Path | None,
    text: str,
    diagnostics: list[dict[str, Any]],
    *,
    cache: WorkspaceCache | None = None,
) -> list[dict[str, Any]]:
    if path is None:
        return []
    actions: list[dict[str, Any]] = []
    known_imports = importable_names(path, cache)
    import_ranges = {entry["name"]: entry["range"] for entry in scan_import_occurrences(text)}
    for diagnostic in diagnostics:
        message = diagnostic.get("message", "")
        match = re.search(r"No se pudo resolver import `([^`]+)`", message)
        if not match:
            continue
        missing_name = match.group(1)
        target_range = import_ranges.get(missing_name, diagnostic.get("range"))
        for suggestion in get_close_matches(missing_name, known_imports, n=3, cutoff=0.45):
            actions.append(
                {
                    "title": f"Reemplazar import por `{suggestion}`",
                    "kind": "quickfix",
                    "edit": {
                        "changes": {
                            uri: [
                                {
                                    "range": target_range,
                                    "newText": suggestion,
                                }
                            ]
                        }
                    },
                }
            )
    return actions


def organized_import_lines(text: str) -> list[str] | None:
    lines = text.splitlines()
    import_lines = [strip_comments(line).strip() for line in lines if strip_comments(line).strip().startswith(("import ", "extends "))]
    if not import_lines:
        return None
    deduped = sorted(dict.fromkeys(import_lines))
    return deduped if deduped != import_lines else None


def import_block_range(text: str) -> dict[str, Any] | None:
    lines = text.splitlines()
    matching = [index for index, line in enumerate(lines) if strip_comments(line).strip().startswith(("import ", "extends "))]
    if not matching:
        return None
    start = matching[0]
    end = matching[-1]
    return make_range(start, 0, end, len(lines[end]) if end < len(lines) else 0)


def organize_imports_action(uri: str, text: str) -> dict[str, Any] | None:
    organized = organized_import_lines(text)
    block_range = import_block_range(text)
    if organized is None or block_range is None:
        return None
    replacement = "\n".join(organized)
    lines = text.splitlines()
    next_index = block_range["end"]["line"] + 1
    if next_index < len(lines) and lines[next_index].strip():
        replacement += "\n"
    return {
        "title": "Organizar imports",
        "kind": "source.organizeImports",
        "edit": {"changes": {uri: [{"range": block_range, "newText": replacement}]}},
    }


def remove_empty_block_actions(uri: str, text: str, diagnostics: list[dict[str, Any]]) -> list[dict[str, Any]]:
    actions: list[dict[str, Any]] = []
    lines = text.splitlines()
    for diagnostic in diagnostics:
        message = diagnostic.get("message", "")
        match = re.search(r"Bloque vacio: `([^`]+)`", message)
        if not match:
            continue
        block_name = match.group(1)
        for index, raw_line in enumerate(lines[:-1]):
            if strip_comments(raw_line).strip() != f"{block_name} {{":
                continue
            if strip_comments(lines[index + 1]).strip() != "}":
                continue
            actions.append(
                {
                    "title": f"Eliminar bloque vacio `{block_name}`",
                    "kind": "quickfix",
                    "edit": {
                        "changes": {
                            uri: [
                                {
                                    "range": make_range(index, 0, index + 1, len(lines[index + 1])),
                                    "newText": "",
                                }
                            ]
                        }
                    },
                }
            )
            break
    return actions


def complete_empty_block_actions(uri: str, text: str, diagnostics: list[dict[str, Any]]) -> list[dict[str, Any]]:
    actions: list[dict[str, Any]] = []
    lines = text.splitlines()
    for diagnostic in diagnostics:
        message = diagnostic.get("message", "")
        match = re.search(r"Bloque vacio: `([^`]+)`", message)
        if not match:
            continue
        block_name = match.group(1)
        if block_name not in BLOCK_TEMPLATES:
            continue
        for index, raw_line in enumerate(lines[:-1]):
            if strip_comments(raw_line).strip() != f"{block_name} {{":
                continue
            if strip_comments(lines[index + 1]).strip() != "}":
                continue
            indent = raw_line[: len(raw_line) - len(raw_line.lstrip())]
            actions.append(
                {
                    "title": f"Completar bloque `{block_name}`",
                    "kind": "quickfix",
                    "edit": {
                        "changes": {
                            uri: [
                                {
                                    "range": make_range(index, 0, index + 1, len(lines[index + 1])),
                                    "newText": render_indented_snippet(BLOCK_TEMPLATES[block_name], indent) + "\n",
                                }
                            ]
                        }
                    },
                }
            )
            break
    return actions


def remove_unused_alias_actions(uri: str, text: str, diagnostics: list[dict[str, Any]]) -> list[dict[str, Any]]:
    actions: list[dict[str, Any]] = []
    lines = text.splitlines()
    for diagnostic in diagnostics:
        message = diagnostic.get("message", "")
        match = re.search(r"Alias posiblemente no usado: `([^`]+)`", message)
        if not match:
            continue
        alias = match.group(1)
        for index, raw_line in enumerate(lines):
            stripped = strip_comments(raw_line)
            import_match = RE_IMPORT.match(stripped)
            if not import_match or import_match.group(3) != alias:
                continue
            alias_start = raw_line.rfind(" as ")
            if alias_start < 0:
                continue
            actions.append(
                {
                    "title": f"Eliminar alias `{alias}`",
                    "kind": "quickfix",
                    "edit": {
                        "changes": {
                            uri: [
                                {
                                    "range": make_range(index, alias_start, index, alias_start + len(" as " + alias)),
                                    "newText": "",
                                }
                            ]
                        }
                    },
                }
            )
            break
    return actions


def remove_duplicate_import_actions(uri: str, text: str, diagnostics: list[dict[str, Any]]) -> list[dict[str, Any]]:
    actions: list[dict[str, Any]] = []
    lines = text.splitlines()
    for diagnostic in diagnostics:
        message = diagnostic.get("message", "")
        match = re.search(r"Import duplicado: `([^`]+)`", message)
        if not match:
            continue
        import_name = match.group(1)
        occurrence_range = diagnostic.get("range")
        if not occurrence_range:
            continue
        line_index = occurrence_range["start"]["line"]
        end_line = line_index + 1 if line_index + 1 < len(lines) else line_index
        end_char = 0 if line_index + 1 < len(lines) else len(lines[line_index])
        actions.append(
            {
                "title": f"Eliminar import duplicado `{import_name}`",
                "kind": "quickfix",
                "edit": {
                    "changes": {
                        uri: [
                            {
                                "range": make_range(line_index, 0, end_line, end_char),
                                "newText": "",
                            }
                        ]
                    }
                },
            }
        )
    return actions


def delete_rule_line_action(uri: str, text: str, title: str, matcher: re.Pattern[str]) -> dict[str, Any] | None:
    lines = text.splitlines()
    for index, raw_line in enumerate(lines):
        stripped = strip_comments(raw_line).strip()
        if matcher.fullmatch(stripped):
            end_line = index + 1 if index + 1 < len(lines) else index
            end_char = 0 if index + 1 < len(lines) else len(lines[index])
            return {
                "title": title,
                "kind": "quickfix",
                "edit": {"changes": {uri: [{"range": make_range(index, 0, end_line, end_char), "newText": ""}]}},
            }
    return None


def append_rule_line_action(uri: str, text: str, title: str, rule_line: str) -> dict[str, Any]:
    lines = text.splitlines()
    in_rules = False
    for index, raw_line in enumerate(lines):
        stripped = strip_comments(raw_line).strip()
        if stripped == "rules {":
            in_rules = True
            continue
        if in_rules and stripped == "}":
            return {
                "title": title,
                "kind": "quickfix",
                "edit": make_workspace_edit(uri, index, 0, "  " + rule_line + "\n"),
            }
    return {
        "title": title,
        "kind": "quickfix",
        "edit": make_workspace_edit(uri, find_closing_brace_line(text), 0, normalize_insert_text(f"rules {{\n  {rule_line}\n}}")),
    }


def solver_guided_actions(uri: str, text: str, diagnostics: list[dict[str, Any]]) -> list[dict[str, Any]]:
    actions: list[dict[str, Any]] = []
    for diagnostic in diagnostics:
        message = diagnostic.get("message", "")
        implied = re.search(r"La regla `([^`]+) -> ([^`]+)` debe cumplirse", message)
        if implied:
            left_atom, right_atom = implied.groups()
            removal = delete_rule_line_action(uri, text, f"Eliminar regla `implies {left_atom} {right_atom}`", re.compile(rf"implies\s+{re.escape(left_atom)}\s+{re.escape(right_atom)}"))
            if removal is not None:
                actions.append(removal)
            actions.append(append_rule_line_action(uri, text, f"Agregar `must {right_atom}`", f"must {right_atom}"))
        required = re.search(r"El atomo `([^`]+)` es obligatorio", message)
        if required:
            atom = required.group(1)
            removal = delete_rule_line_action(uri, text, f"Eliminar regla `must {atom}`", re.compile(rf"must\s+{re.escape(atom)}"))
            if removal is not None:
                actions.append(removal)
        forbidden = re.search(r"El atomo `([^`]+)` esta prohibido", message)
        if forbidden:
            atom = forbidden.group(1)
            removal = delete_rule_line_action(uri, text, f"Eliminar regla `forbid {atom}`", re.compile(rf"forbid\s+{re.escape(atom)}"))
            if removal is not None:
                actions.append(removal)
        redundant_required = re.search(r"es redundante: El atomo `([^`]+)` es obligatorio", message)
        if redundant_required:
            atom = redundant_required.group(1)
            removal = delete_rule_line_action(uri, text, f"Eliminar regla redundante `must {atom}`", re.compile(rf"must\s+{re.escape(atom)}"))
            if removal is not None:
                actions.append(removal)
    return actions


def full_skeleton_action(uri: str, snippet_index: int, title: str) -> dict[str, Any]:
    return {
        "title": title,
        "kind": "refactor.rewrite",
        "edit": {
            "changes": {
                uri: [
                    {
                        "range": {
                            "start": {"line": 0, "character": 0},
                            "end": {"line": 0, "character": 0},
                        },
                        "newText": SNIPPETS[snippet_index]["body"] + "\n",
                    }
                ]
            }
        },
    }


def extract_code_actions(uri: str, text: str, diagnostics: list[dict[str, Any]], *, cache: WorkspaceCache | None = None) -> list[dict[str, Any]]:
    actions: list[dict[str, Any]] = []
    messages = [diagnostic.get("message", "") for diagnostic in diagnostics]
    try:
        path = uri_to_path(uri)
    except Exception:
        path = None

    if not prompt_exists(text):
        return [
            full_skeleton_action(uri, 0, "Insertar skeleton de prompt final"),
            full_skeleton_action(uri, 1, "Insertar skeleton de subprompt reusable"),
            full_skeleton_action(uri, 10, "Insertar scaffold de prompt engineering"),
            full_skeleton_action(uri, 11, "Insertar scaffold de prompt research"),
            full_skeleton_action(uri, 12, "Insertar scaffold de prompt security"),
        ]

    block_message_map = {
        "objective": "Agregar bloque `objective`",
        "instructions": "Agregar bloque `instructions`",
        "deliverables": "Agregar bloque `deliverables`",
        "quality_bar": "Agregar bloque `quality_bar`",
        "response_rules": "Agregar bloque `response_rules`",
        "rules": "Agregar bloque `rules`",
    }
    metadata_map = {"role": "Agregar linea `role`", "task": "Agregar linea `task`"}

    for block_name, title in block_message_map.items():
        if (not document_has_block(text, block_name)) and any(block_name in message for message in messages):
            actions.append(append_block_action(uri, text, block_name, title))
    for field_name, title in metadata_map.items():
        if (not document_has_block(text, field_name)) and any(field_name in message for message in messages):
            actions.append(insert_metadata_action(uri, text, field_name, title))
    if not any(line.strip().startswith("quality_profile ") for line in text.splitlines()) and any("quality_profile" in message for message in messages):
        actions.append(insert_metadata_action(uri, text, "quality_profile", "Agregar linea `quality_profile`"))
    if not document_has_block(text, "rules") and not any(action.get("title") == "Agregar bloque `rules`" for action in actions):
        actions.append(append_block_action(uri, text, "rules", "Insertar scaffold de `rules`"))
    legacy_action = materialize_legacy_rules_action(uri, text)
    if legacy_action is not None:
        actions.append(legacy_action)
    embedded_action = materialize_embedded_rules_action(uri, text)
    if embedded_action is not None:
        actions.append(embedded_action)
    actions.extend(profile_remediation_actions(uri, text))
    actions.extend(unresolved_import_actions(uri, path, text, diagnostics, cache=cache))
    actions.extend(remove_unused_alias_actions(uri, text, diagnostics))
    actions.extend(remove_duplicate_import_actions(uri, text, diagnostics))
    actions.extend(complete_empty_block_actions(uri, text, diagnostics))
    actions.extend(remove_empty_block_actions(uri, text, diagnostics))
    actions.extend(solver_guided_actions(uri, text, diagnostics))
    organize_action = organize_imports_action(uri, text)
    if organize_action is not None:
        actions.append(organize_action)
    format_action = format_document_action(uri, path, text, cache=cache)
    if format_action is not None:
        actions.append(format_action)
    export_action = export_super_xml_action(uri, path)
    if export_action is not None:
        actions.append(export_action)
    actions.append({"title": "Insertar snippet de reglas cardinales", "kind": "refactor.rewrite", "edit": make_workspace_edit(uri, find_closing_brace_line(text), 0, normalize_insert_text(SNIPPETS[5]["body"]))})
    return dedupe_actions(actions)


def dedupe_actions(actions: list[dict[str, Any]]) -> list[dict[str, Any]]:
    seen: set[str] = set()
    unique: list[dict[str, Any]] = []
    for action in actions:
        title = action.get("title", "")
        if title in seen:
            continue
        seen.add(title)
        unique.append(action)
    return unique


def collect_folding_ranges(text: str) -> list[dict[str, Any]]:
    lines = text.splitlines()
    ranges: list[dict[str, Any]] = []
    stack: list[tuple[int, str]] = []
    triple_start: int | None = None
    for index, raw_line in enumerate(lines):
        stripped = strip_comments(raw_line).strip()
        if '"""' in raw_line:
            if triple_start is None:
                triple_start = index
            else:
                if index > triple_start:
                    ranges.append({"startLine": triple_start, "endLine": index, "kind": "region"})
                triple_start = None
        if stripped.endswith("{"):
            stack.append((index, "region"))
        elif stripped == "}" and stack:
            start, kind = stack.pop()
            if index > start:
                ranges.append({"startLine": start, "endLine": index, "kind": kind})
    return ranges


def token_type_index(name: str) -> int:
    return TOKEN_TYPES.index(name)


def collect_semantic_tokens(text: str) -> list[int]:
    raw_tokens: set[tuple[int, int, int, int, int]] = set()
    snapshot = scan_document(text)
    keyword_pattern = re.compile(r"\b(" + "|".join(re.escape(keyword) for keyword in KEYWORD_COMPLETIONS) + r")\b")
    string_pattern = re.compile(r'"[^"]*"')
    comment_pattern = re.compile(r"#.*$")
    for line_index, raw_line in enumerate(text.splitlines()):
        for match in comment_pattern.finditer(raw_line):
            raw_tokens.add((line_index, match.start(), match.end() - match.start(), token_type_index("comment"), 0))
        for match in string_pattern.finditer(raw_line):
            raw_tokens.add((line_index, match.start(), match.end() - match.start(), token_type_index("string"), 0))
        for match in keyword_pattern.finditer(raw_line):
            raw_tokens.add((line_index, match.start(), match.end() - match.start(), token_type_index("keyword"), 0))
    for occurrence in snapshot.import_occurrences + snapshot.alias_occurrences + snapshot.prompt_occurrences:
        start = occurrence["range"]["start"]
        end = occurrence["range"]["end"]
        raw_tokens.add((start["line"], start["character"], end["character"] - start["character"], token_type_index("namespace"), 0))
    for occurrence in snapshot.param_occurrences:
        start = occurrence["range"]["start"]
        end = occurrence["range"]["end"]
        raw_tokens.add((start["line"], start["character"], end["character"] - start["character"], token_type_index("parameter"), 0))
    for occurrence in snapshot.section_occurrences + snapshot.atom_occurrences:
        start = occurrence["range"]["start"]
        end = occurrence["range"]["end"]
        raw_tokens.add((start["line"], start["character"], end["character"] - start["character"], token_type_index("property"), 0))
    sorted_tokens = sorted(raw_tokens)
    encoded: list[int] = []
    previous_line = 0
    previous_start = 0
    for line, start, length, token_type, modifiers in sorted_tokens:
        delta_line = line - previous_line
        delta_start = start - previous_start if delta_line == 0 else start
        encoded.extend([delta_line, delta_start, length, token_type, modifiers])
        previous_line = line
        previous_start = start
    return encoded


def make_range(start_line: int, start_char: int, end_line: int, end_char: int) -> dict[str, Any]:
    return {
        "start": {"line": start_line, "character": start_char},
        "end": {"line": end_line, "character": end_char},
    }


def full_document_range(text: str) -> dict[str, Any]:
    lines = text.splitlines()
    if not lines:
        return make_range(0, 0, 0, 0)
    return make_range(0, 0, len(lines) - 1, len(lines[-1]))


def hover_for_context(
    path: Path | None,
    snapshot: DocumentSnapshot,
    context: dict[str, Any],
    *,
    open_documents: dict[str, DocumentSnapshot] | None = None,
    cache: WorkspaceCache | None = None,
    allow_heavy: bool = True,
) -> str | None:
    kind = context["kind"]
    name = context["name"]
    if kind == "keyword":
        return KEYWORD_DOCS.get(name)
    if kind == "import" and path is not None:
        target = resolve_import_path(path, name, cache)
        if target is None:
            return f"Import `{name}` no resuelto."
        try:
            target_uri = path_to_uri(target)
            target_snapshot = open_documents[target_uri] if open_documents is not None and target_uri in open_documents else (cache.snapshot_for_file(target) if cache is not None else None)
            target_text = target_snapshot.text if target_snapshot is not None else target.read_text()
            target_snapshot = target_snapshot or scan_document(target_text)
            summary = explain_summary_for_document(target, target_text, cache=cache) if allow_heavy or (cache is not None and (str(target), target_text) in cache.explain_cache) else None
        except Exception:
            target_snapshot = None
            summary = None
        body = prompt_hover_header(f"**import `{name}`**", target, target_snapshot or snapshot, open_documents=open_documents, cache=cache) if target_snapshot is not None else [f"**import `{name}`**", "", f"- **path**: `{target}`"]
        if summary:
            body.extend(["", summary])
        return "\n".join(body)
    if kind == "alias" and path is not None:
        import_name = resolve_alias_import_name(snapshot, name)
        if import_name is None:
            return f"Alias `{name}`."
        target = resolve_import_path(path, import_name, cache)
        if target is None:
            return f"Alias `{name}` para import no resuelto `{import_name}`."
        target_uri = path_to_uri(target)
        target_snapshot = open_documents[target_uri] if open_documents is not None and target_uri in open_documents else (cache.snapshot_for_file(target) if cache is not None else None)
        if target_snapshot is None:
            target_snapshot = scan_document(target.read_text())
        body = prompt_hover_header(f"**alias `{name}`**", target, target_snapshot, open_documents=open_documents, cache=cache)
        body.insert(2, f"- **alias-of**: `{import_name}`")
        return "\n".join(body)
    if kind == "prompt":
        if path is not None:
            summary = explain_summary_for_document(path, snapshot.text, cache=cache) if allow_heavy or (cache is not None and (str(path), snapshot.text) in cache.explain_cache) else None
            body = prompt_hover_header(f"**prompt `{name}`**", path, snapshot, open_documents=open_documents, cache=cache)
            if summary:
                body.extend(["", summary])
            return "\n".join(body)
        return f"Prompt principal `{name}`."
    if kind == "atom":
        atoms = workspace_symbol_occurrences(path, path_to_uri(path) if path is not None else "file:///untitled.pdsl", snapshot, context, open_documents=open_documents, cache=cache) if path is not None else []
        count = len(atoms) if atoms else len([entry for entry in snapshot.atom_occurrences if entry["name"] == name])
        return f"Atomo logico reusable `{name}`.\n\nApariciones detectadas: **{count}**."
    if kind == "param":
        return f"Parametro reusable `{name}`."
    if kind == "section":
        return f"Seccion semantica `{name}`."
    return None


def definition_for_context(
    base_path: Path | None,
    current_uri: str,
    current_snapshot: DocumentSnapshot,
    context: dict[str, Any],
    *,
    open_documents: dict[str, DocumentSnapshot] | None = None,
    cache: WorkspaceCache | None = None,
) -> dict[str, Any] | None:
    if context["kind"] == "import" and base_path is not None:
        target = resolve_import_path(base_path, context["name"], cache)
        if target is not None:
            return prompt_definition_location(target, cache=cache, open_documents=open_documents)
    if context["kind"] == "alias" and base_path is not None:
        import_name = resolve_alias_import_name(current_snapshot, context["name"])
        if import_name is not None:
            target = resolve_import_path(base_path, import_name, cache)
            if target is not None:
                return prompt_definition_location(target, cache=cache, open_documents=open_documents)
    for location in workspace_symbol_occurrences(base_path, current_uri, current_snapshot, context, open_documents=open_documents, cache=cache):
        return location
    return None


def rename_occurrences(uri: str, text: str, old_word: str, new_word: str) -> dict[str, Any] | None:
    occurrences = occurrences_in_text(text, old_word)
    if not occurrences:
        return None
    edits = [{"range": occurrence["range"], "newText": new_word} for occurrence in occurrences]
    return {"changes": {uri: edits}}


class LSPServer:
    def __init__(self) -> None:
        self.documents: dict[str, str] = {}
        self.snapshots: dict[str, DocumentSnapshot] = {}
        self.cache = WorkspaceCache()
        self.last_change_at: dict[str, float] = {}
        self.heavy_debounce_seconds = 0.25

    def snapshot_for_uri(self, uri: str) -> DocumentSnapshot:
        snapshot = self.snapshots.get(uri)
        if snapshot is not None:
            return snapshot
        text = self.documents.get(uri, "")
        snapshot = scan_document(text)
        self.snapshots[uri] = snapshot
        return snapshot

    def update_document(self, uri: str, text: str) -> None:
        self.documents[uri] = text
        self.snapshots[uri] = scan_document(text)
        self.last_change_at[uri] = time.monotonic()
        try:
            path = uri_to_path(uri)
        except Exception:
            return
        self.cache.invalidate_path(path)

    def should_run_heavy(self, uri: str, *, force: bool = False) -> bool:
        if force:
            return True
        last_change = self.last_change_at.get(uri)
        if last_change is None:
            return True
        return (time.monotonic() - last_change) >= self.heavy_debounce_seconds

    def send(self, payload: dict[str, Any]) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        header = f"Content-Length: {len(body)}\r\n\r\n".encode("ascii")
        sys.stdout.buffer.write(header + body)
        sys.stdout.buffer.flush()

    def send_response(self, message_id: Any, result: Any = None) -> None:
        self.send({"jsonrpc": "2.0", "id": message_id, "result": result})

    def send_notification(self, method: str, params: Any) -> None:
        self.send({"jsonrpc": "2.0", "method": method, "params": params})

    def publish_diagnostics(self, uri: str, *, force_heavy: bool = False) -> None:
        text = self.documents.get(uri, "")
        snapshot = self.snapshot_for_uri(uri)
        try:
            path = uri_to_path(uri)
        except Exception:
            path = Path("/tmp/untitled.pdsl")
        diagnostics = fast_structural_diagnostics(path, snapshot, open_documents=self.snapshots, cache=self.cache)
        if self.should_run_heavy(uri, force=force_heavy):
            diagnostics += diagnostics_from_linter(path, text, cache=self.cache)
        diagnostics = dedupe_lsp_diagnostics(diagnostics)
        self.send_notification("textDocument/publishDiagnostics", {"uri": uri, "diagnostics": diagnostics})

    def handle_initialize(self, message_id: Any) -> None:
        self.send_response(
            message_id,
            {
                "capabilities": {
                    "textDocumentSync": 1,
                    "hoverProvider": True,
                    "definitionProvider": True,
                    "documentLinkProvider": {"resolveProvider": False},
                    "referencesProvider": True,
                    "renameProvider": True,
                    "documentFormattingProvider": True,
                    "documentSymbolProvider": True,
                    "workspaceSymbolProvider": True,
                    "foldingRangeProvider": True,
                    "semanticTokensProvider": {
                        "legend": {"tokenTypes": TOKEN_TYPES, "tokenModifiers": TOKEN_MODIFIERS},
                        "full": True,
                    },
                    "codeActionProvider": True,
                    "executeCommandProvider": {"commands": ["pdsl.exportSuperXml"]},
                    "completionProvider": {
                        "resolveProvider": False,
                        "triggerCharacters": COMPLETION_TRIGGER_CHARACTERS,
                    },
                },
                "serverInfo": {"name": "pdsl-ls", "version": "0.8.0"},
            },
        )

    def handle_completion(self, message_id: Any, params: dict[str, Any]) -> None:
        uri = params["textDocument"]["uri"]
        position = params["position"]
        snapshot = self.snapshot_for_uri(uri)
        try:
            path = uri_to_path(uri)
        except Exception:
            path = None
        items = render_completion_items(snapshot, position["line"], position["character"], path, open_documents=self.snapshots, cache=self.cache)
        self.send_response(message_id, {"isIncomplete": False, "items": items})

    def handle_hover(self, message_id: Any, params: dict[str, Any]) -> None:
        uri = params["textDocument"]["uri"]
        position = params["position"]
        snapshot = self.snapshot_for_uri(uri)
        try:
            path = uri_to_path(uri)
        except Exception:
            path = None
        context = symbol_context_at_position(snapshot, position)
        doc = hover_for_context(
            path,
            snapshot,
            context,
            open_documents=self.snapshots,
            cache=self.cache,
            allow_heavy=True,
        ) if context is not None else None
        self.send_response(message_id, {"contents": {"kind": "markdown", "value": doc}} if doc else None)

    def handle_definition(self, message_id: Any, params: dict[str, Any]) -> None:
        uri = params["textDocument"]["uri"]
        snapshot = self.snapshot_for_uri(uri)
        position = params["position"]
        try:
            base_path = uri_to_path(uri)
        except Exception:
            base_path = None
        context = symbol_context_at_position(snapshot, position)
        self.send_response(
            message_id,
            definition_for_context(base_path, uri, snapshot, context, open_documents=self.snapshots, cache=self.cache) if context is not None else None,
        )

    def handle_document_links(self, message_id: Any, params: dict[str, Any]) -> None:
        uri = params["textDocument"]["uri"]
        snapshot = self.snapshot_for_uri(uri)
        try:
            base_path = uri_to_path(uri)
        except Exception:
            base_path = None
        self.send_response(message_id, collect_document_links(base_path, snapshot, cache=self.cache))

    def handle_references(self, message_id: Any, params: dict[str, Any]) -> None:
        uri = params["textDocument"]["uri"]
        snapshot = self.snapshot_for_uri(uri)
        position = params["position"]
        try:
            base_path = uri_to_path(uri)
        except Exception:
            base_path = None
        context = symbol_context_at_position(snapshot, position)
        references = workspace_symbol_occurrences(base_path, uri, snapshot, context, open_documents=self.snapshots, cache=self.cache) if context is not None else []
        self.send_response(message_id, references)

    def handle_rename(self, message_id: Any, params: dict[str, Any]) -> None:
        uri = params["textDocument"]["uri"]
        snapshot = self.snapshot_for_uri(uri)
        position = params["position"]
        new_name = params.get("newName", "")
        try:
            base_path = uri_to_path(uri)
        except Exception:
            base_path = None
        context = symbol_context_at_position(snapshot, position)
        self.send_response(
            message_id,
            rename_workspace_occurrences(base_path, uri, snapshot, context, new_name, open_documents=self.snapshots, cache=self.cache) if context is not None else None,
        )

    def handle_formatting(self, message_id: Any, params: dict[str, Any]) -> None:
        uri = params["textDocument"]["uri"]
        text = self.documents.get(uri, "")
        try:
            path = uri_to_path(uri)
        except Exception:
            path = Path("/tmp/untitled.pdsl")
        formatted = format_via_cli(path, text, cache=self.cache)
        if formatted is None or formatted == text:
            self.send_response(message_id, [])
            return
        self.send_response(message_id, [{"range": full_document_range(text), "newText": formatted}])

    def handle_document_symbols(self, message_id: Any, params: dict[str, Any]) -> None:
        uri = params["textDocument"]["uri"]
        snapshot = self.snapshot_for_uri(uri)
        self.send_response(message_id, snapshot.document_symbols)

    def handle_workspace_symbols(self, message_id: Any, params: dict[str, Any]) -> None:
        query = params.get("query", "")
        self.send_response(message_id, collect_workspace_symbols(query, cache=self.cache))

    def handle_code_actions(self, message_id: Any, params: dict[str, Any]) -> None:
        uri = params["textDocument"]["uri"]
        text = self.documents.get(uri, "")
        diagnostics = params.get("context", {}).get("diagnostics", [])
        self.send_response(message_id, extract_code_actions(uri, text, diagnostics, cache=self.cache))

    def handle_execute_command(self, message_id: Any, params: dict[str, Any]) -> None:
        command = params.get("command", "")
        arguments = params.get("arguments", [])
        if command != "pdsl.exportSuperXml" or not arguments:
            self.send_response(message_id, None)
            return
        uri = arguments[0]
        text = self.documents.get(uri, "")
        try:
            path = uri_to_path(uri)
            target_path, _ = export_super_xml(path, text)
            self.send_notification(
                "window/showMessage",
                {
                    "type": 3,
                    "message": f"PDSL exportado como super XML en {target_path}",
                },
            )
            self.send_response(message_id, {"uri": path_to_uri(target_path)})
        except Exception as exc:
            self.send_notification(
                "window/showMessage",
                {
                    "type": 1,
                    "message": f"No se pudo exportar el super XML: {exc}",
                },
            )
            self.send_response(message_id, None)

    def handle_folding_ranges(self, message_id: Any, params: dict[str, Any]) -> None:
        uri = params["textDocument"]["uri"]
        text = self.documents.get(uri, "")
        self.send_response(message_id, collect_folding_ranges(text))

    def handle_semantic_tokens(self, message_id: Any, params: dict[str, Any]) -> None:
        uri = params["textDocument"]["uri"]
        text = self.documents.get(uri, "")
        self.send_response(message_id, {"data": collect_semantic_tokens(text)})

    def handle_message(self, message: dict[str, Any]) -> None:
        method = message.get("method")
        message_id = message.get("id")
        params = message.get("params", {})

        if method == "initialize":
            self.handle_initialize(message_id)
        elif method == "initialized":
            return
        elif method == "shutdown":
            self.send_response(message_id, None)
        elif method == "exit":
            raise SystemExit(0)
        elif method == "textDocument/didOpen":
            document = params["textDocument"]
            self.update_document(document["uri"], document.get("text", ""))
            self.publish_diagnostics(document["uri"], force_heavy=True)
        elif method == "textDocument/didChange":
            document = params["textDocument"]
            changes = params.get("contentChanges", [])
            if changes:
                self.update_document(document["uri"], changes[-1].get("text", ""))
                self.publish_diagnostics(document["uri"])
        elif method == "textDocument/didSave":
            uri = params["textDocument"]["uri"]
            if "text" in params:
                self.update_document(uri, params["text"])
            self.publish_diagnostics(uri, force_heavy=True)
        elif method == "textDocument/completion":
            self.handle_completion(message_id, params)
        elif method == "textDocument/hover":
            self.handle_hover(message_id, params)
        elif method == "textDocument/definition":
            self.handle_definition(message_id, params)
        elif method == "textDocument/documentLink":
            self.handle_document_links(message_id, params)
        elif method == "textDocument/references":
            self.handle_references(message_id, params)
        elif method == "textDocument/rename":
            self.handle_rename(message_id, params)
        elif method == "textDocument/formatting":
            self.handle_formatting(message_id, params)
        elif method == "textDocument/documentSymbol":
            self.handle_document_symbols(message_id, params)
        elif method == "workspace/symbol":
            self.handle_workspace_symbols(message_id, params)
        elif method == "textDocument/codeAction":
            self.handle_code_actions(message_id, params)
        elif method == "workspace/executeCommand":
            self.handle_execute_command(message_id, params)
        elif method == "textDocument/foldingRange":
            self.handle_folding_ranges(message_id, params)
        elif method == "textDocument/semanticTokens/full":
            self.handle_semantic_tokens(message_id, params)
        elif method and message_id is not None:
            self.send_response(message_id, None)

    def run(self) -> None:
        while True:
            message = read_message()
            if message is None:
                break
            self.handle_message(message)


def read_message() -> dict[str, Any] | None:
    headers: dict[str, str] = {}
    while True:
        line = sys.stdin.buffer.readline()
        if not line:
            return None
        if line in (b"\r\n", b"\n"):
            break
        key, value = line.decode("ascii").split(":", 1)
        headers[key.strip().lower()] = value.strip()
    length = int(headers.get("content-length", "0"))
    if length <= 0:
        return None
    body = sys.stdin.buffer.read(length)
    if not body:
        return None
    return json.loads(body.decode("utf-8"))


if __name__ == "__main__":
    LSPServer().run()
