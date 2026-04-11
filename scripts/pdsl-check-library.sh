#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
tool_dir="$repo_root/wm-shared/.config/wm-shared/scripts/bin/system"
library_dir="$repo_root/wm-shared/.config/wm-shared/prompt-library"
invalid_dir="$repo_root/wm-shared/.config/wm-shared/pdsl-fixtures/invalid"
python_bin="$(command -v python3 || command -v python || true)"

if [[ -z "$python_bin" ]]; then
  echo "Expected python3 or python to run PDSL LSP smoke tests" >&2
  exit 1
fi

temp_home="$(mktemp -d)"
cleanup() {
  rm -rf "$temp_home"
}
trap cleanup EXIT

dest_library="$temp_home/.config/wm-shared/prompt-library"
mkdir -p "$dest_library"
cp -R "$library_dir/." "$dest_library/"

lint_file() {
  local file="$1"
  HOME="$temp_home" sh "$tool_dir/pdsl_lint.hs" "$file"
}

format_file() {
  local file="$1"
  HOME="$temp_home" sh "$tool_dir/pdsl_format.hs" "$file"
}

explain_file() {
  local file="$1"
  HOME="$temp_home" sh "$tool_dir/pdsl_explain.hs" "$file" >/dev/null
}

export_file() {
  local file="$1"
  HOME="$temp_home" sh "$tool_dir/pdsl_export.hs" "$file"
}

check_smt_explain() {
  local valid_file="$dest_library/subprompts/software_engineer.pdsl"
  local redundant_file="$dest_library/builds/feature_import_example.pdsl"
  local valid_output redundant_output xml_output
  valid_output="$(HOME="$temp_home" sh "$tool_dir/pdsl_explain.hs" "$valid_file")"
  if [[ "$valid_output" != *"smt-report:"* ]] || [[ "$valid_output" != *"status: SolverSat"* ]] || [[ "$valid_output" != *"witness-atoms:"* ]] || [[ "$valid_output" != *"compiled-xml-preview:"* ]]; then
    echo "Expected SMT report with witness atoms in pdsl_explain output" >&2
    exit 1
  fi
  redundant_output="$(HOME="$temp_home" sh "$tool_dir/pdsl_explain.hs" "$redundant_file")"
  if [[ "$redundant_output" != *"redundant-assertions:"* ]] || [[ "$redundant_output" != *"r1_0"* ]]; then
    echo "Expected SMT redundancy information in pdsl_explain output" >&2
    exit 1
  fi
  xml_output="$(HOME="$temp_home" sh "$tool_dir/pdsl_export.hs" "$redundant_file")"
  if [[ "$xml_output" != *"<prompt version=\"4.0\" kind=\"final\" name=\"feature_import_example\">"* ]] || [[ "$xml_output" != *"<compiled_format>xml</compiled_format>"* ]] || [[ "$xml_output" != *"Feature Delivery Lead for reusable prompt composition."* ]] || [[ "$xml_output" != *"Staff Software Engineer focused on maintainable implementation decisions."* ]]; then
    echo "Expected pdsl_export to emit a resolved super XML artifact with merged prompt content" >&2
    exit 1
  fi
}

check_lsp_completion() {
  HOME="$temp_home" "$python_bin" - "$tool_dir/pdsl_ls.py" <<'PY'
import json
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote

server = Path(sys.argv[1])
uri = "file://" + str((Path.home() / ".config" / "wm-shared" / "prompt-library" / "builds" / "lsp_completion_probe.pdsl").resolve())
export_uri = "file://" + str((Path.home() / ".config" / "wm-shared" / "prompt-library" / "builds" / "lsp_export_probe.pdsl").resolve())
messages = []
seed_text = "prompt completion_probe {\n  kind \n}\n"
export_text = '''prompt export_probe {
  kind final
  language es
  depth detailed
  deprecated false
  role "Exporter focused on resolved XML output."
  task "Export a composed prompt as a single XML artifact."

  objective """
    Validate that the PDSL language server can export a fully resolved prompt as super XML.
  """

  instructions {
    "Produce a fully resolved XML artifact."
  }

  deliverables {
    "A resolved super XML file."
  }

  quality_bar {
    "The XML export must be complete and well-formed."
  }

  response_rules {
    "Do not omit required prompt sections."
  }
}
'''
probe_text = '''import strict_evidence as evidence
import software_engineer
import software_engineer

prompt completion_probe {
  kind final
  language es
  depth detailed
  deprecated false
  quality_profile "engineering"
  role "Planner focused on composed prompts."
  task "Validate composed prompts with useful diagnostics."

  objective """
    Validate imports, navigation, code actions and semantic tokens.
  """

  param "target_path" {
    type "path"
    required false
    description "Workspace path under analysis."
  }

  section "notes" """
    Mention inherited constraints and verification steps.
  """

  instructions {
  }

  response_rules {
    "must: audited-output"
  }

  
}
'''
lines = probe_text.splitlines()

def add(payload):
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    messages.append(b"Content-Length: " + str(len(body)).encode("ascii") + b"\r\n\r\n" + body)

def line_numbers(fragment, *, exact=False):
    found = []
    for index, line in enumerate(lines):
        if (exact and line == fragment) or ((not exact) and fragment in line):
            found.append(index)
    if not found:
        raise SystemExit(f"Could not locate fragment: {fragment!r}")
    return found

def line_of(fragment, *, exact=False, occurrence=0):
    matches = line_numbers(fragment, exact=exact)
    if occurrence >= len(matches):
        raise SystemExit(f"Could not locate occurrence {occurrence} of {fragment!r}")
    return matches[occurrence]

def char_of(line_index, fragment):
    return lines[line_index].index(fragment)

first_import_line = line_of("import software_engineer", exact=True, occurrence=0)
second_import_line = line_of("import software_engineer", exact=True, occurrence=1)
alias_line = line_of("import strict_evidence as evidence", exact=True)
prompt_line = line_of("prompt completion_probe {", exact=True)
completion_line = line_of("  ", exact=True)
param_line = line_of('  param "target_path" {', exact=True)
section_line = line_of('  section "notes" """', exact=True)
empty_block_line = line_of("  instructions {", exact=True)

add({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"capabilities": {}}})
add({"jsonrpc": "2.0", "method": "initialized", "params": {}})
add(
    {
        "jsonrpc": "2.0",
        "method": "textDocument/didOpen",
        "params": {
            "textDocument": {
                "uri": uri,
                "languageId": "pdsl",
                "version": 1,
                "text": seed_text,
            }
        },
    }
)
add(
    {
        "jsonrpc": "2.0",
        "id": 2,
        "method": "textDocument/completion",
        "params": {"textDocument": {"uri": uri}, "position": {"line": 1, "character": 7}},
    }
)
add(
    {
        "jsonrpc": "2.0",
        "method": "textDocument/didChange",
        "params": {
            "textDocument": {"uri": uri, "version": 2},
            "contentChanges": [{"text": probe_text}],
        },
    }
)
add(
    {
        "jsonrpc": "2.0",
        "id": 3,
        "method": "textDocument/completion",
        "params": {"textDocument": {"uri": uri}, "position": {"line": completion_line, "character": 2}},
    }
)
add(
    {
        "jsonrpc": "2.0",
        "id": 4,
        "method": "textDocument/definition",
        "params": {"textDocument": {"uri": uri}, "position": {"line": first_import_line, "character": char_of(first_import_line, "software_engineer") + 2}},
    }
)
add(
    {
        "jsonrpc": "2.0",
        "id": 5,
        "method": "textDocument/hover",
        "params": {"textDocument": {"uri": uri}, "position": {"line": first_import_line, "character": char_of(first_import_line, "software_engineer") + 2}},
    }
)
add(
    {
        "jsonrpc": "2.0",
        "id": 6,
        "method": "workspace/symbol",
        "params": {"query": "software_engineer"},
    }
)
add(
    {
        "jsonrpc": "2.0",
        "id": 7,
        "method": "textDocument/codeAction",
        "params": {
            "textDocument": {"uri": uri},
            "range": {"start": {"line": 0, "character": 0}, "end": {"line": len(lines) - 1, "character": 0}},
            "context": {
                "diagnostics": [
                    {
                        "range": {"start": {"line": 0, "character": 0}, "end": {"line": 0, "character": 24}},
                        "message": "No se pudo resolver import `software_engineer_typo`",
                    },
                    {
                        "range": {"start": {"line": 0, "character": 0}, "end": {"line": 0, "character": 31}},
                        "message": "Alias posiblemente no usado: `evidence`",
                    },
                    {
                        "range": {"start": {"line": 0, "character": 0}, "end": {"line": 0, "character": 31}},
                        "message": "La regla `audited-output -> cite-sources` debe cumplirse (rules).",
                    },
                    {
                        "range": {"start": {"line": alias_line, "character": char_of(alias_line, "evidence")}, "end": {"line": alias_line, "character": char_of(alias_line, "evidence") + len("evidence")}},
                        "message": "Alias posiblemente no usado: `evidence`",
                    },
                    {
                        "range": {"start": {"line": second_import_line, "character": char_of(second_import_line, "software_engineer")}, "end": {"line": second_import_line, "character": char_of(second_import_line, "software_engineer") + len("software_engineer")}},
                        "message": "Import duplicado: `software_engineer`.",
                    },
                    {
                        "range": {"start": {"line": empty_block_line, "character": 0}, "end": {"line": empty_block_line + 1, "character": 1}},
                        "message": "Bloque vacio: `instructions`.",
                    }
                ]
            },
        },
    }
)
add(
    {
        "jsonrpc": "2.0",
        "id": 8,
        "method": "textDocument/definition",
        "params": {"textDocument": {"uri": uri}, "position": {"line": alias_line, "character": char_of(alias_line, "evidence") + 1}},
    }
)
add(
    {
        "jsonrpc": "2.0",
        "id": 9,
        "method": "textDocument/documentLink",
        "params": {"textDocument": {"uri": uri}},
    }
)
add(
    {
        "jsonrpc": "2.0",
        "id": 10,
        "method": "textDocument/references",
        "params": {"textDocument": {"uri": uri}, "position": {"line": first_import_line, "character": char_of(first_import_line, "software_engineer") + 2}},
    }
)
add(
    {
        "jsonrpc": "2.0",
        "id": 11,
        "method": "textDocument/rename",
        "params": {"textDocument": {"uri": uri}, "position": {"line": first_import_line, "character": char_of(first_import_line, "software_engineer") + 2}, "newName": "platform_engineer"},
    }
)
add(
    {
        "jsonrpc": "2.0",
        "id": 12,
        "method": "textDocument/documentSymbol",
        "params": {"textDocument": {"uri": uri}},
    }
)
add(
    {
        "jsonrpc": "2.0",
        "id": 13,
        "method": "textDocument/semanticTokens/full",
        "params": {"textDocument": {"uri": uri}},
    }
)
add(
    {
        "jsonrpc": "2.0",
        "id": 14,
        "method": "textDocument/hover",
        "params": {"textDocument": {"uri": uri}, "position": {"line": prompt_line, "character": char_of(prompt_line, "completion_probe") + 2}},
    }
)
add(
    {
        "jsonrpc": "2.0",
        "method": "textDocument/didOpen",
        "params": {
            "textDocument": {
                "uri": export_uri,
                "languageId": "pdsl",
                "version": 1,
                "text": export_text,
            }
        },
    }
)
add(
    {
        "jsonrpc": "2.0",
        "id": 15,
        "method": "workspace/executeCommand",
        "params": {"command": "pdsl.exportSuperXml", "arguments": [export_uri]},
    }
)

raw = subprocess.run([str(server)], input=b"".join(messages), stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False).stdout
parsed = {}
idx = 0
while idx < len(raw):
    if raw[idx : idx + 16] != b"Content-Length: ":
        idx += 1
        continue
    line_end = raw.find(b"\r\n", idx)
    body_length = int(raw[idx + 16 : line_end])
    body_start = line_end + 4
    body_end = body_start + body_length
    message = json.loads(raw[body_start:body_end])
    if "id" in message:
        parsed[message["id"]] = message["result"]
    idx = body_end

first_labels = {item["label"] for item in parsed.get(2, {}).get("items", [])}
second_items = parsed.get(3, {}).get("items", [])
second_labels = {item["label"] for item in second_items}
definition_uri = parsed.get(4, {}).get("uri", "")
hover_import_value = (((parsed.get(5) or {}).get("contents") or {}).get("value") or "")
workspace_symbols = parsed.get(6, [])
code_actions = parsed.get(7, [])
alias_definition_uri = parsed.get(8, {}).get("uri", "")
document_links = parsed.get(9, [])
references = parsed.get(10, [])
rename_changes = ((parsed.get(11) or {}).get("changes") or {}).get(uri, [])
document_symbols = parsed.get(12, [])
semantic_tokens = ((parsed.get(13) or {}).get("data") or [])
hover_prompt_value = (((parsed.get(14) or {}).get("contents") or {}).get("value") or "")
export_result_uri = ((parsed.get(15) or {}).get("uri") or "")
code_action_titles = {action.get("title") for action in code_actions}
semantic_token_types = set(semantic_tokens[3::5])

if not {"final", "subprompt"}.issubset(first_labels):
    raise SystemExit("Missing expected `kind` completions from pdsl_ls.py")
if not {"acceptance_criteria", "verification_plan"}.issubset(second_labels):
    raise SystemExit("Missing expected semantic scaffold completions from pdsl_ls.py")
if not any(item.get("label") == "owner" and item.get("detail") == "PDSL root field scaffold" for item in second_items):
    raise SystemExit("Missing expected contextual root field completions from pdsl_ls.py")
if not definition_uri.endswith("/software_engineer.pdsl"):
    raise SystemExit("Definition did not resolve imported prompt")
if "compiled-preview" not in hover_import_value or "**profiles**" not in hover_import_value or "**token-report**" not in hover_import_value or "**compiled-xml-preview**" not in hover_import_value:
    raise SystemExit("Hover did not include compiled preview summary")
if not any(symbol.get("name") == "software_engineer" for symbol in workspace_symbols):
    raise SystemExit("Workspace symbols did not include software_engineer")
if not any(symbol.get("name") == "import software_engineer" for symbol in workspace_symbols):
    raise SystemExit("Workspace symbols did not include hierarchical import symbols")
if "Organizar imports" not in code_action_titles:
    raise SystemExit("Code actions did not include organize imports")
if "Reemplazar import por `software_engineer`" not in code_action_titles:
    raise SystemExit("Code actions did not include unresolved import suggestion")
if "Agregar `must cite-sources`" not in code_action_titles:
    raise SystemExit("Code actions did not include SMT-guided remediation")
if "Completar bloque `instructions`" not in code_action_titles:
    raise SystemExit("Code actions did not include empty block completion")
if "Eliminar alias `evidence`" not in code_action_titles:
    raise SystemExit("Code actions did not include alias cleanup")
if "Eliminar import duplicado `software_engineer`" not in code_action_titles:
    raise SystemExit("Code actions did not include duplicate import cleanup")
if "Extraer reglas embebidas a `rules`" not in code_action_titles:
    raise SystemExit("Code actions did not include embedded-rule extraction")
if "Exportar super XML resuelto" not in code_action_titles:
    raise SystemExit("Code actions did not include super XML export")
if not alias_definition_uri.endswith("/strict_evidence.pdsl"):
    raise SystemExit("Definition did not resolve import alias")
if not any(link.get("target", "").endswith("/software_engineer.pdsl") for link in document_links):
    raise SystemExit("Document links did not resolve imported prompts")
if len(references) < 2:
    raise SystemExit("References did not include repeated import occurrences")
if len(rename_changes) < 2:
    raise SystemExit("Rename did not include repeated import occurrences")
if not document_symbols or document_symbols[0].get("name") != "completion_probe":
    raise SystemExit("Document symbols did not expose the prompt root")
child_names = {child.get("name") for child in document_symbols[0].get("children", [])}
if not {"import software_engineer", "target_path", "notes"}.issubset(child_names):
    raise SystemExit("Document symbols did not include expected hierarchical children")
if not {3, 4, 5}.issubset(semantic_token_types):
    raise SystemExit("Semantic tokens did not include namespace, parameter and property types")
if "import-chain" not in hover_prompt_value or "witness-by-type" not in hover_prompt_value:
    raise SystemExit("Prompt hover did not include type-aware SMT summary")
if not export_result_uri.endswith("/lsp_export_probe.super.xml"):
    raise SystemExit("ExecuteCommand did not export a super XML artifact")
exported_xml = Path(unquote(export_result_uri.removeprefix("file://"))).read_text()
if "<prompt version=\"4.0\" kind=\"final\" name=\"export_probe\">" not in exported_xml or "<compiled_format>xml</compiled_format>" not in exported_xml:
    raise SystemExit("Exported super XML artifact did not contain expected resolved XML content")
PY
}

check_lsp_benchmarks() {
  HOME="$temp_home" "$python_bin" - "$tool_dir/pdsl_ls.py" <<'PY'
import importlib.util
import os
import sys
import time
from pathlib import Path

server_path = Path(__import__('sys').argv[1])
spec = importlib.util.spec_from_file_location("pdsl_ls", server_path)
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)

cache = module.WorkspaceCache()
index_path = cache.index_path()
cold_start = time.perf_counter()
symbols1 = cache.indexed_symbols()
cold = time.perf_counter() - cold_start
hot_start = time.perf_counter()
symbols2 = cache.indexed_symbols()
hot = time.perf_counter() - hot_start

probe_path = Path.home() / ".config" / "wm-shared" / "prompt-library" / "builds" / "feature_import_example.pdsl"
snapshot = module.scan_document(probe_path.read_text())
completion_cold_start = time.perf_counter()
module.render_completion_items(snapshot, 42 if len(snapshot.lines) > 42 else 0, 10, probe_path, cache=cache)
completion_cold = time.perf_counter() - completion_cold_start
completion_hot_start = time.perf_counter()
for _ in range(25):
    module.render_completion_items(snapshot, 42 if len(snapshot.lines) > 42 else 0, 10, probe_path, cache=cache)
completion_hot = (time.perf_counter() - completion_hot_start) / 25.0

if not index_path.exists():
    raise SystemExit("Persistent workspace index was not created")
if not symbols1 or not symbols2:
    raise SystemExit("Persistent workspace index did not contain symbols")
if hot > cold * 1.25:
    raise SystemExit(f"Hot indexed_symbols path regressed: cold={cold:.6f}s hot={hot:.6f}s")
if completion_hot > completion_cold * 1.10:
    raise SystemExit(f"Hot completion path regressed: cold={completion_cold:.6f}s hot={completion_hot:.6f}s")
PY
}

while IFS= read -r -d '' file; do
  lint_file "$file"
  formatted="$(format_file "$file")"
  expected="$(cat "$file")"
  if [[ "$formatted"$'\n' != "$expected"$'\n' ]]; then
    echo "Formatter drift detected in $file" >&2
    exit 1
  fi
  explain_file "$file"
done < <(find "$library_dir" -type f -name '*.pdsl' -print0 | sort -z)

while IFS= read -r -d '' file; do
  if lint_file "$file"; then
    echo "Expected lint failure for invalid fixture: $file" >&2
    exit 1
  fi
done < <(find "$invalid_dir" -type f -name '*.pdsl' -print0 | sort -z)

check_lsp_completion
check_lsp_benchmarks
check_smt_explain
