#!/usr/bin/env bash
set -euo pipefail

bootstrap_args=()
check_args=()
profile_override=""
machine_profile_override=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      profile_override="$2"
      bootstrap_args+=("--profile" "$2")
      check_args+=("--profile" "$2")
      shift 2
      ;;
    --profile=*)
      profile_override="${1#*=}"
      bootstrap_args+=("--profile" "$profile_override")
      check_args+=("--profile" "$profile_override")
      shift
      ;;
    --machine-profile)
      machine_profile_override="$2"
      bootstrap_args+=("--machine-profile" "$2")
      check_args+=("--machine-profile" "$2")
      shift 2
      ;;
    --machine-profile=*)
      machine_profile_override="${1#*=}"
      bootstrap_args+=("--machine-profile" "$machine_profile_override")
      check_args+=("--machine-profile" "$machine_profile_override")
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

./scripts/lvim-bootstrap.sh "${bootstrap_args[@]}"

echo "--- sanity check ---"

./scripts/lvim-check.sh "${check_args[@]}"

if [[ -n "$profile_override" || -n "$machine_profile_override" ]]; then
  exit 0
fi

spoon_jar="${SPOON_JDT_LSP_JAR:-$HOME/dev/spoon-jdt-lsp/target/spoon-jdt-lsp-1.0-SNAPSHOT-jar-with-dependencies.jar}"

for profile in minimal challenge research; do
  echo "--- profile sanity: $profile ---"
  ./scripts/lvim-check.sh --profile "$profile"
done

if [[ -f "$spoon_jar" ]]; then
  echo "--- profile sanity: personal,java ---"
  ./scripts/lvim-check.sh --profile "personal,java"
fi

for machine_profile in laptop workstation mac_air_m4 ryzen_9_5950x; do
  echo "--- machine profile sanity: $machine_profile ---"
  ./scripts/lvim-check.sh --profile personal --machine-profile "$machine_profile"
done
