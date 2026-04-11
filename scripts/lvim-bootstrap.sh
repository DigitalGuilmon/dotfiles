#!/usr/bin/env bash
set -euo pipefail

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      export LVIM_PROFILE="$2"
      shift 2
      ;;
    --machine-profile)
      export LVIM_MACHINE_PROFILE="$2"
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

if ! command -v lvim >/dev/null 2>&1; then
  echo "Expected lvim in PATH" >&2
  exit 1
fi

echo "--- lazy sync/clean ---"
lvim --headless "+Lazy! sync" "+Lazy! clean" "+qa"

echo "--- mason tools sync ---"
if ! command -v go >/dev/null 2>&1; then
  echo "Go no está en PATH; el bootstrap de gopls se omitirá intencionalmente."
fi
lvim --headless "+Lazy! load all" "+MasonToolsInstallSync" "+qa"

if [[ "${LVIM_PROFILE:-}" == *"java"* ]]; then
  echo "--- spoon lsp bootstrap ---"
  ./scripts/lvim-prepare-spoon.sh
fi
