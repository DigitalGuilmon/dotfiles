#!/usr/bin/env bash
set -euo pipefail

source_dir="${SPOON_JDT_LSP_DIR:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-dir)
      source_dir="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

if ! command -v java >/dev/null 2>&1; then
  echo "Expected java in PATH" >&2
  exit 1
fi

if [[ -n "${SPOON_JDT_LSP_JAR:-}" && -f "${SPOON_JDT_LSP_JAR}" ]]; then
  echo "Using prebuilt Spoon JDT LSP jar: ${SPOON_JDT_LSP_JAR}"
  exit 0
fi

if ! command -v mvn >/dev/null 2>&1; then
  echo "Expected mvn in PATH to build spoon-jdt-lsp from source" >&2
  exit 1
fi

if [[ -z "$source_dir" ]]; then
  if [[ -n "${RUNNER_TEMP:-}" ]]; then
    source_dir="${RUNNER_TEMP}/lsp_base/spoon-jdt-lsp"
  else
    source_dir="$HOME/dev/lsp_base/spoon-jdt-lsp"
  fi
fi

if [[ ! -f "$source_dir/pom.xml" ]]; then
  checkout_root="$(dirname "$source_dir")"
  if [[ -e "$checkout_root" ]]; then
    echo "Expected spoon-jdt-lsp source under $source_dir, but $checkout_root already exists without the expected layout." >&2
    exit 1
  fi
  mkdir -p "$(dirname "$checkout_root")"
  git clone --depth=1 https://github.com/DigitalGuilmon/lsp_base.git "$checkout_root"
fi

if [[ ! -f "$source_dir/pom.xml" ]]; then
  echo "Expected spoon-jdt-lsp pom.xml at: $source_dir" >&2
  exit 1
fi

echo "Building Spoon JDT LSP from source: $source_dir"
(
  cd "$source_dir"
  mvn -q -DskipTests package dependency:copy-dependencies
)

jar_path="$(find "$source_dir/target" -maxdepth 1 -name '*jar-with-dependencies.jar' | head -n 1)"
if [[ -z "$jar_path" ]]; then
  echo "Could not find a jar-with-dependencies artifact under $source_dir/target" >&2
  exit 1
fi

echo "Spoon JDT LSP ready:"
echo "  SPOON_JDT_LSP_DIR=$source_dir"
echo "  SPOON_JDT_LSP_JAR=$jar_path"
