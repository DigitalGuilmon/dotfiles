#!/usr/bin/env bash
set -euo pipefail

profile_override=""
machine_profile_override=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      profile_override="$2"
      shift 2
      ;;
    --profile=*)
      profile_override="${1#*=}"
      shift
      ;;
    --machine-profile)
      machine_profile_override="$2"
      shift 2
      ;;
    --machine-profile=*)
      machine_profile_override="${1#*=}"
      shift
      ;;
    *)
      echo "Usage: $0 [--profile name[,extra]] [--machine-profile name[,extra]]" >&2
      exit 1
      ;;
  esac
done

if [[ -n "$profile_override" ]]; then
  export LVIM_PROFILE="$profile_override"
fi
if [[ -n "$machine_profile_override" ]]; then
  export LVIM_MACHINE_PROFILE="$machine_profile_override"
fi

export LVIM_HEADLESS_SANITY=1

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

if ! command -v lvim >/dev/null 2>&1; then
  echo "Expected lvim in PATH" >&2
  exit 1
fi

config_home="$(mktemp -d)"
mkdir -p "$config_home"
ln -s "$repo_root/lvim/.config/lvim" "$config_home/lvim"
trap 'rm -rf "$config_home"' EXIT

clean_lvim_output() {
  python3 -c 'import sys; text = sys.stdin.read().replace("\r", ""); text = text.replace("vim.tbl_add_reverse_lookup is deprecated. Run \":checkhealth vim.depr", ""); lines = [line for line in text.splitlines() if line.strip()]; compact = []; [compact.append(line) for line in lines if not compact or compact[-1] != line]; sys.stdout.write("\n".join(compact) + ("\n" if compact else ""))'
}

assert_clean_lvim_output() {
  local output="$1"
  if [[ -n "$output" ]]; then
    printf '%s\n' "$output"
  fi

  [[ "$output" != *"Invalid configuration:"* ]] &&
    [[ "$output" != *"Error detected while processing"* ]] &&
    [[ "$output" != *"stack traceback:"* ]] &&
    [[ "$output" != *"E5113:"* ]]
}

run_lvim_cmd() {
  local output
  output="$(env ${profile_override:+LVIM_PROFILE="$profile_override"} ${machine_profile_override:+LVIM_MACHINE_PROFILE="$machine_profile_override"} XDG_CONFIG_HOME="$config_home" lvim --headless "+set shortmess+=F" "$@" "+qa" 2>&1 | clean_lvim_output)"
  assert_clean_lvim_output "$output"
}

if command -v luac5.4 >/dev/null 2>&1; then
  echo "--- lua syntax ---"
  find lvim/.config/lvim/lua -name '*.lua' -print0 | xargs -0 -n1 luac5.4 -p
elif command -v luac >/dev/null 2>&1; then
  echo "--- lua syntax ---"
  find lvim/.config/lvim/lua -name '*.lua' -print0 | xargs -0 -n1 luac -p
fi

run_lvim() {
  local label="$1"
  shift
  echo "--- $label ---"
  run_lvim_cmd "$@"
}

run_probe_file() {
  local label="$1"
  local suffix="$2"
  local content="$3"
  shift 3

  local tmpfile
  tmpfile="$(mktemp "/tmp/lvim-check-XXXXXX.${suffix}")"
  printf '%s\n' "$content" >"$tmpfile"
  trap 'rm -f "$tmpfile"' RETURN
  echo "--- $label ---"
  local output
  output="$(env ${profile_override:+LVIM_PROFILE="$profile_override"} ${machine_profile_override:+LVIM_MACHINE_PROFILE="$machine_profile_override"} XDG_CONFIG_HOME="$config_home" lvim --headless "+set shortmess+=F" "+edit $tmpfile" "+sleep 400m" "+messages" "$@" "+qa" 2>&1 | clean_lvim_output)"
  assert_clean_lvim_output "$output"
  rm -f "$tmpfile"
  trap - RETURN
}

run_lvim "headless"
run_lvim "full load" \
  "+Lazy! load all" \
  "+lua local sanity = require('lvim_ext.sanity'); sanity.check_command_plugins(); sanity.check_testing_stack(); sanity.check_lint_stack(); sanity.check_dap(); sanity.check_session_commands()" \
  "+messages"
run_probe_file "markdown" "md" "# LVim check\n\n- markdown fixture" "+sleep 200m" "+messages"
run_probe_file "typescript" "ts" "const x = 1"
run_probe_file "python" "py" "print(1)"
run_probe_file "lua" "lua" "local x = 1"
run_lvim "pdsl" \
  "+edit wm-shared/.config/wm-shared/prompt-library/examples/inheritance_reuse/base_engineering_review.pdsl" \
  "+sleep 400m" \
  "+lua require('lvim_ext.sanity').check_pdsl(0)" \
  "+messages"
run_lvim "ai commands" \
  "+lua local sanity = require('lvim_ext.sanity'); sanity.check_ai_commands(); sanity.check_ai_persistence(); vim.cmd('LvimAIStatus'); vim.cmd('LvimAIProviders'); vim.cmd('LvimSetupInfo'); require('lvim_ext.health').check()" \
  "+messages"
run_probe_file "obsidian" "md" "# test" \
  "+lua require('lvim_ext.sanity').check_obsidian(0)" \
  "+messages"
run_probe_file "vimtex" "tex" "\\documentclass{article}\n\\begin{document}\nhello\n\\end{document}" \
  "+lua require('lvim_ext.sanity').check_vimtex(0)" \
  "+messages"
run_probe_file "tabular" "csv" "name,value\nalpha,1" \
  "+lua require('lvim_ext.sanity').check_tabular(0)" \
  "+messages"
run_probe_file "science" "py" "print(1)" \
  "+lua require('lvim_ext.sanity').check_science()" \
  "+messages"

active_profile="${profile_override:-${LVIM_PROFILE:-}}"
if [[ -n "$active_profile" ]]; then
  echo "--- profile ---"
  echo "LVIM_PROFILE=$active_profile"
fi
active_machine_profile="${machine_profile_override:-${LVIM_MACHINE_PROFILE:-}}"
if [[ -n "$active_machine_profile" ]]; then
  echo "LVIM_MACHINE_PROFILE=$active_machine_profile"
fi

spoon_jar="${SPOON_JDT_LSP_JAR:-$HOME/dev/spoon-jdt-lsp/target/spoon-jdt-lsp-1.0-SNAPSHOT-jar-with-dependencies.jar}"

if [[ "$active_profile" == *"java"* && -f "$spoon_jar" ]]; then
  run_probe_file "java" "java" "class T {}" \
    "+lua require('lvim_ext.sanity').check_java(0)" \
    "+messages"
elif [[ "$active_profile" == *"java"* ]]; then
  echo "--- java ---"
  echo "Skipping Java probe because Spoon JAR was not found at: $spoon_jar"
fi
