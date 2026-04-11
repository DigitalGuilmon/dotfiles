# LVim

This repository keeps the LunarVim setup under `lvim/.config/lvim`.

## Profiles

- `LVIM_PROFILE` stacks comma-separated logical overlays on top of `base`, e.g. `personal,java`.
- `LVIM_MACHINE_PROFILE` stacks machine overlays after the logical profiles, e.g. `workstation`, `laptop`, `mac_air_m4`, `ryzen_9_5950x`.
- Inspect the active setup inside LVim with `:LvimSetupInfo` and `:checkhealth lvim_ext`.
- Useful overlays include `frontend`, `backend`, `writing`, `debug`, `research`, `challenge`, and `java`.
- Common stacks:
  - `LVIM_PROFILE=personal,frontend`
  - `LVIM_PROFILE=personal,backend`
  - `LVIM_PROFILE=personal,writing`
  - `LVIM_PROFILE=personal,debug`
  - `LVIM_PROFILE=personal,research`

## Maintenance commands

1. `./scripts/lvim-bootstrap.sh [--profile ...] [--machine-profile ...]` installs/syncs plugins and Mason tools without running the full sanity suite.
2. `./scripts/lvim-check.sh [--profile ...] [--machine-profile ...]` runs the LVim smoke checks.
3. `./scripts/lvim-refresh.sh [--profile ...] [--machine-profile ...]` bootstraps first and then runs the sanity suite.

For deterministic headless checks, prefer `lvim-bootstrap.sh` before `lvim-check.sh`.

## Built-in workflow commands

- `:LvimLint` runs the configured buffer linter when one is available.
- `:LvimDapSelectConfig` picks a DAP launch config for the current filetype.
- `:LvimDapRestart` restarts the last DAP session when supported.
- `:LvimSessionSave`, `:LvimSessionLoad`, `:LvimSessionLast`, `:LvimSessionSelect`, `:LvimSessionDelete`, `:LvimSessionStop` manage sessions explicitly.
- `:LvimWorkspaceIDE`, `:LvimWorkspaceFocus`, `:LvimWorkspaceTests`, `:LvimWorkspaceDebug`, `:LvimWorkspaceClose` control the IDE/testing/debug panel layouts.

## Optional dependencies by feature

| Feature | What enables it |
| --- | --- |
| AI providers | `GEMINI_API_KEY`, `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, or plugin-managed auth for Copilot / GitHub Models |
| Obsidian | `OBSIDIAN_VAULT_DIR`, `OBSIDIAN_WORKSPACE_NAME` |
| Iron / Molten images | ImageMagick plus either `ueberzugpp` or tmux passthrough when relevant |
| Go bootstrap | `go` in `PATH` |
| VimTeX | `latexmk` plus a PDF viewer such as `zathura`, `skim`, `open`, or `xdg-open` |
| Spoon Java LSP | `LVIM_PROFILE=personal,java` plus either `SPOON_JDT_LSP_JAR` or `SPOON_JDT_LSP_DIR` |

## Spoon Java LSP

LVim can launch Spoon from either:

1. A prebuilt jar pointed to by `SPOON_JDT_LSP_JAR`.
2. A source checkout pointed to by `SPOON_JDT_LSP_DIR`, as long as it has already been built.

The recommended source tree is the public `DigitalGuilmon/lsp_base` repository, under `spoon-jdt-lsp/`.

Use:

```bash
./scripts/lvim-prepare-spoon.sh
```

That script clones `DigitalGuilmon/lsp_base` into a temp/dev directory when needed and builds `spoon-jdt-lsp` with Maven so the Java profile can be validated locally and in CI.
