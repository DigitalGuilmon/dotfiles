#!/usr/bin/env python3

"""Generate derived keybind files from wm-shared/.config/wm-shared/keybinds.yml.

Keep LVim bindings declarative in keybinds.yml and regenerate outputs instead of
editing lvim/.config/lvim/lua/config/keymaps/generated.lua by hand.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

import yaml


SECTION_TITLES = {
    "launchers": "Launchers",
    "menus": "Menus",
    "contextual": "Contextual",
    "system": "System",
    "search": "Search",
    "windows": "Windows",
    "workspaces": "Workspaces",
    "scratchpads": "Scratchpads",
    "multimedia": "Multimedia",
    "mouse": "Mouse",
}

MOD_ORDER = ("win", "ctrl", "shift", "alt")
HYPR_MODS = {"win": "$mainMod", "ctrl": "CTRL", "shift": "SHIFT", "alt": "ALT"}
XMONAD_MODS = {"win": "M", "ctrl": "C", "shift": "S", "alt": "A"}
KEY_ALIASES = {"super": "win", "mod": "win", "control": "ctrl"}
HYPR_SPECIAL_KEYS = {
    "enter": "Return",
    "space": "Space",
    "escape": "Escape",
    "tab": "Tab",
    "print": "Print",
    "up": "Up",
    "down": "Down",
    "left": "Left",
    "right": "Right",
    "comma": "comma",
    "period": "period",
}
XMONAD_SPECIAL_KEYS = {
    "enter": "<Return>",
    "space": "<Space>",
    "escape": "<Escape>",
    "tab": "<Tab>",
    "print": "<Print>",
    "up": "<Up>",
    "down": "<Down>",
    "left": "<Left>",
    "right": "<Right>",
    "comma": ",",
    "period": ".",
}
MOUSE_KEYS = {"mouse:left": "mouse:272", "mouse:right": "mouse:273"}
XF86_KEYS = {
    "xf86-audio-raise-volume": "XF86AudioRaiseVolume",
    "xf86-audio-lower-volume": "XF86AudioLowerVolume",
    "xf86-audio-mute": "XF86AudioMute",
    "xf86-audio-mic-mute": "XF86AudioMicMute",
    "xf86-audio-prev": "XF86AudioPrev",
    "xf86-audio-play": "XF86AudioPlay",
    "xf86-audio-next": "XF86AudioNext",
    "xf86-brightness-up": "XF86MonBrightnessUp",
    "xf86-brightness-down": "XF86MonBrightnessDown",
    "xf86-calculator": "XF86Calculator",
}
WORKSPACE_NAMES = {
    1: "1:dev",
    2: "2:web",
    3: "3:term",
    4: "4:db",
    5: "5:api",
    6: "6:chat",
    7: "7:media",
    8: "8:sys",
    9: "9:vm",
    0: "10:misc",
}

HYPR_ACTIONS: dict[str, dict[str, str]] = {
    "terminal": {"dispatcher": "exec", "arg": "$terminal"},
    "launcher-menu": {"dispatcher": "exec", "arg": "$menu"},
    "browser": {"dispatcher": "exec", "arg": "$browser"},
    "editor": {"dispatcher": "exec", "arg": "$editor"},
    "youtube": {"dispatcher": "exec", "arg": "$yt_cmd"},
    "ai-menu": {"dispatcher": "exec", "arg": "$wmScripts/ai/ai_menu.hs"},
    "system-menu": {"dispatcher": "exec", "arg": "$wmScripts/system/system_utils.hs"},
    "multimedia-menu": {"dispatcher": "exec", "arg": "$wmDispatch multimedia-menu"},
    "network-menu": {"dispatcher": "exec", "arg": "$wmScripts/network/network_menu.hs"},
    "screenshot": {"dispatcher": "exec", "arg": "$wmScripts/multimedia/screenshot.hs"},
    "todo-menu": {"dispatcher": "exec", "arg": "$wmScripts/productivity/todo.hs"},
    "window-list": {"dispatcher": "exec", "arg": "$wmScripts/system/window_manager.hs --list"},
    "window-menu": {"dispatcher": "exec", "arg": "$wmScripts/system/window_manager.hs"},
    "close-all-windows": {"dispatcher": "exec", "arg": "$wmScripts/system/window_manager.hs --close-all"},
    "notifications": {"dispatcher": "exec", "arg": "$wmDispatch notifications"},
    "wallpaper": {"dispatcher": "exec", "arg": "$wmScripts/system/wallpaper_universe.hs"},
    "layout-menu": {"dispatcher": "exec", "arg": "$wmScripts/system/layout_menu.hs"},
    "volume-menu": {"dispatcher": "exec", "arg": "$wmScripts/multimedia/volume.hs menu"},
    "steam-menu": {"dispatcher": "exec", "arg": "$wmScripts/multimedia/steam_menu.hs"},
    "docker-menu": {"dispatcher": "exec", "arg": "$wmScripts/system/docker.hs"},
    "calculator": {"dispatcher": "exec", "arg": "$wmScripts/productivity/calculator.hs"},
    "english-menu": {"dispatcher": "exec", "arg": "$wmScripts/productivity/english.hs"},
    "productivity-menu": {"dispatcher": "exec", "arg": "$wmDispatch productivity-menu"},
    "color-picker": {"dispatcher": "exec", "arg": "$wmScripts/productivity/color_picker.hs"},
    "keybind-cheatsheet": {"dispatcher": "exec", "arg": "$wmScripts/system/keybind_cheatsheet.hs"},
    "web-bookmarks": {"dispatcher": "exec", "arg": "$wmScripts/network/web_menu.hs"},
    "yt-dlp-menu": {"dispatcher": "exec", "arg": "$wmScripts/network/yt_dlp_menu.hs"},
    "shell-prompt": {"dispatcher": "exec", "arg": "$wmScripts/system/prompt.hs"},
    "downloads-menu": {"dispatcher": "exec", "arg": "$wmScripts/network/download.hs"},
    "projects-menu": {"dispatcher": "exec", "arg": "$wmDispatch projects-menu"},
    "emoji-picker": {"dispatcher": "exec", "arg": "$wmDispatch emoji-picker"},
    "timer-menu": {"dispatcher": "exec", "arg": "$wmDispatch timer-menu"},
    "system-info": {"dispatcher": "exec", "arg": "$wmDispatch system-info"},
    "clipboard-menu": {"dispatcher": "exec", "arg": "$wmDispatch clipboard-menu"},
    "workspace-menu": {"dispatcher": "exec", "arg": "$wmDispatch workspace-menu"},
    "scratchpad-menu": {"dispatcher": "exec", "arg": "$wmDispatch scratchpad-menu"},
    "session-menu": {"dispatcher": "exec", "arg": "$wmDispatch session-menu"},
    "files-menu": {"dispatcher": "exec", "arg": "$wmDispatch files-menu"},
    "bluetooth-menu": {"dispatcher": "exec", "arg": "$wmDispatch bluetooth-menu"},
    "appearance-menu": {"dispatcher": "exec", "arg": "$wmDispatch appearance-menu"},
    "reload-wm": {"dispatcher": "exec", "arg": "$reload_cmd"},
    "restart-bars-or-wm": {"dispatcher": "exec", "arg": "$bar_reset"},
    "logout": {"dispatcher": "exec", "arg": "$logout"},
    "force-exit": {"dispatcher": "exit"},
    "window-close": {"dispatcher": "killactive"},
    "window-fullscreen": {"dispatcher": "fullscreen"},
    "window-toggle-floating": {"dispatcher": "togglefloating"},
    "window-center": {"dispatcher": "centerwindow"},
    "window-focus-down": {"dispatcher": "movefocus", "arg": "d"},
    "window-focus-up": {"dispatcher": "movefocus", "arg": "u"},
    "window-focus-left": {"dispatcher": "movefocus", "arg": "l"},
    "window-focus-right": {"dispatcher": "movefocus", "arg": "r"},
    "window-move-down": {"dispatcher": "movewindow", "arg": "d"},
    "window-move-up": {"dispatcher": "movewindow", "arg": "u"},
    "window-move-left": {"dispatcher": "movewindow", "arg": "l"},
    "window-move-right": {"dispatcher": "movewindow", "arg": "r"},
    "window-send-to-scratchpad": {"dispatcher": "movetoworkspacesilent", "arg": "special:scratchpad"},
    "window-toggle-scratchpad": {"dispatcher": "togglespecialworkspace", "arg": "scratchpad"},
    "window-resize-right": {"kind": "binde", "dispatcher": "resizeactive", "arg": "30 0"},
    "window-resize-left": {"kind": "binde", "dispatcher": "resizeactive", "arg": "-30 0"},
    "window-resize-up": {"kind": "binde", "dispatcher": "resizeactive", "arg": "0 -30"},
    "window-resize-down": {"kind": "binde", "dispatcher": "resizeactive", "arg": "0 30"},
    "workspace-next": {"dispatcher": "workspace", "arg": "e+1"},
    "volume-up": {"kind": "binde", "dispatcher": "exec", "arg": "$wmScripts/multimedia/volume.hs up"},
    "volume-down": {"kind": "binde", "dispatcher": "exec", "arg": "$wmScripts/multimedia/volume.hs down"},
    "volume-mute": {"kind": "bind", "dispatcher": "exec", "arg": "$wmScripts/multimedia/volume.hs mute"},
    "mic-mute": {"kind": "bind", "dispatcher": "exec", "arg": "$wmScripts/multimedia/volume.hs mic"},
    "media-prev": {"kind": "bind", "dispatcher": "exec", "arg": "playerctl previous"},
    "media-play-pause": {"kind": "bind", "dispatcher": "exec", "arg": "playerctl play-pause"},
    "media-next": {"kind": "bind", "dispatcher": "exec", "arg": "playerctl next"},
    "brightness-up": {"kind": "binde", "dispatcher": "exec", "arg": "$bri_up"},
    "brightness-down": {"kind": "binde", "dispatcher": "exec", "arg": "$bri_down"},
    "mouse-move-window": {"kind": "bindm", "dispatcher": "movewindow"},
    "mouse-resize-window": {"kind": "bindm", "dispatcher": "resizewindow"},
}

XMONAD_ACTIONS = {
    "terminal",
    "launcher-menu",
    "browser",
    "editor",
    "youtube",
    "rofi-window-picker",
    "ai-menu",
    "system-menu",
    "multimedia-menu",
    "network-menu",
    "screenshot",
    "todo-menu",
    "window-list",
    "window-menu",
    "close-all-windows",
    "notifications",
    "wallpaper",
    "layout-menu",
    "volume-menu",
    "steam-menu",
    "docker-menu",
    "calculator",
    "english-menu",
    "productivity-menu",
    "web-bookmarks",
    "yt-dlp-menu",
    "shell-prompt",
    "projects-menu",
    "dev-tools",
    "emoji-picker",
    "timer-menu",
    "system-info",
    "clipboard-menu",
    "workspace-menu",
    "scratchpad-menu",
    "session-menu",
    "files-menu",
    "bluetooth-menu",
    "appearance-menu",
    "reload-wm",
    "restart-bars-or-wm",
    "logout",
    "force-exit",
    "monitor-menu",
    "disable-default-gmrun",
    "search-google",
    "search-youtube",
    "search-man",
    "search-shell",
    "search-window-grid",
    "window-close",
    "window-fullscreen",
    "window-toggle-floating",
    "window-center",
    "window-focus-down",
    "window-focus-up",
    "window-focus-left",
    "window-focus-right",
    "window-focus-master",
    "window-move-down",
    "window-move-up",
    "window-swap-master",
    "window-inc-masters",
    "window-dec-masters",
    "window-refresh",
    "window-send-to-scratchpad",
    "window-toggle-scratchpad",
    "window-sink-all",
    "window-first-layout",
    "window-next-layout",
    "workspace-next",
    "workspace-prev",
    "workspace-next-arrow",
    "workspace-prev-arrow",
    "workspace-shift-next",
    "workspace-shift-prev",
    "scratchpad-vscode",
    "scratchpad-filemanager",
    "scratchpad-btop",
    "scratchpad-notes",
    "volume-up",
    "volume-down",
    "volume-mute",
    "mic-mute",
    "media-prev",
    "media-play-pause",
    "media-next",
    "brightness-up",
    "brightness-down",
}

LVIM_ACTIONS: dict[str, dict[str, Any]] = {
    "notifications": {"command": "<cmd>lua Snacks.picker.notifications()<cr>"},
    "dbui-toggle": {"command": "<cmd>DBUIToggle<cr>", "plugins": ["vim-dadbod-ui"]},
    "dbui-find-buffer": {"command": "<cmd>DBUIFindBuffer<cr>", "plugins": ["vim-dadbod-ui"]},
    "dbui-add-connection": {"command": "<cmd>DBUIAddConnection<cr>", "plugins": ["vim-dadbod-ui"]},
    "trouble-diagnostics": {"command": "<cmd>Trouble diagnostics toggle<cr>", "plugins": ["trouble.nvim"]},
    "trouble-diagnostics-buffer": {"command": "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "plugins": ["trouble.nvim"]},
    "trouble-qflist": {"command": "<cmd>Trouble qflist toggle<cr>", "plugins": ["trouble.nvim"]},
    "trouble-loclist": {"command": "<cmd>Trouble loclist toggle<cr>", "plugins": ["trouble.nvim"]},
    "trouble-lsp": {"command": "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", "plugins": ["trouble.nvim"]},
    "trouble-todo": {"command": "<cmd>Trouble todo toggle<cr>", "plugins": ["trouble.nvim"]},
    "trouble-todo-buffer": {"command": "<cmd>Trouble todo toggle filter.buf=0<cr>", "plugins": ["trouble.nvim"]},
    "aerial-toggle": {"command": "<cmd>AerialToggle<cr>", "plugins": ["aerial.nvim"]},
    "aerial-nav-toggle": {"command": "<cmd>AerialNavToggle<cr>", "plugins": ["aerial.nvim"]},
    "aerial-next": {"command": "<cmd>AerialNext<cr>", "plugins": ["aerial.nvim"]},
    "aerial-prev": {"command": "<cmd>AerialPrev<cr>", "plugins": ["aerial.nvim"]},
    "lean-infoview": {"command": "<cmd>LeanInfoviewToggle<cr>", "plugins": ["lean.nvim"]},
    "obsidian-new": {"command": "<cmd>ObsidianNew<cr>", "plugins": ["obsidian.nvim"]},
    "obsidian-open": {"command": "<cmd>ObsidianOpen<cr>", "plugins": ["obsidian.nvim"]},
    "obsidian-quick-switch": {"command": "<cmd>ObsidianQuickSwitch<cr>", "plugins": ["obsidian.nvim"]},
    "obsidian-search": {"command": "<cmd>ObsidianSearch<cr>", "plugins": ["obsidian.nvim"]},
    "obsidian-vault-search": {
        "lua": 'function() require("snacks").picker.files({ cwd = require("config.env").obsidian_vault_dir() }) end',
        "plugins": ["obsidian.nvim"],
    },
    "obsidian-template-picker": {
        "lua": """function()
  local templates_dir = require("config.env").obsidian_templates_dir()
  require("snacks").picker.files({
    cwd = templates_dir,
    title = "Seleccionar Plantilla",
    confirm = function(picker, item)
      picker:close()
      vim.cmd("ObsidianTemplate " .. item.text)
    end,
  })
end""",
        "plugins": ["obsidian.nvim"],
    },
    "obsidian-link": {"command": "<cmd>ObsidianLink<cr>", "plugins": ["obsidian.nvim"]},
    "obsidian-links": {"command": "<cmd>ObsidianLinks<cr>", "plugins": ["obsidian.nvim"]},
    "obsidian-tags": {"command": "<cmd>ObsidianTags<cr>", "plugins": ["obsidian.nvim"]},
    "obsidian-today": {"command": "<cmd>ObsidianToday<cr>", "plugins": ["obsidian.nvim"]},
    "obsidian-dailies": {"command": "<cmd>ObsidianDailies<cr>", "plugins": ["obsidian.nvim"]},
    "obsidian-yesterday": {"command": "<cmd>ObsidianYesterday<cr>", "plugins": ["obsidian.nvim"]},
    "obsidian-tomorrow": {"command": "<cmd>ObsidianTomorrow<cr>", "plugins": ["obsidian.nvim"]},
    "obsidian-backlinks": {"command": "<cmd>ObsidianBacklinks<cr>", "plugins": ["obsidian.nvim"]},
    "obsidian-follow-link": {"command": "<cmd>ObsidianFollowLink<cr>", "plugins": ["obsidian.nvim"]},
    "obsidian-toc": {"command": "<cmd>ObsidianTOC<cr>", "plugins": ["obsidian.nvim"]},
    "obsidian-workspace": {"command": "<cmd>ObsidianWorkspace<cr>", "plugins": ["obsidian.nvim"]},
    "obsidian-paste-img": {"command": "<cmd>ObsidianPasteImg<cr>", "plugins": ["obsidian.nvim"]},
    "obsidian-rename": {"command": "<cmd>ObsidianRename<cr>", "plugins": ["obsidian.nvim"]},
    "noice-dismiss": {"command": "<cmd>Noice dismiss<cr>", "plugins": ["noice.nvim"]},
    "noice-history": {"command": "<cmd>Noice history<cr>", "plugins": ["noice.nvim"]},
    "noice-last": {"command": "<cmd>Noice last<cr>", "plugins": ["noice.nvim"]},
    "noice-errors": {"command": "<cmd>Noice errors<cr>", "plugins": ["noice.nvim"]},
    "noice-all": {"command": "<cmd>Noice all<cr>", "plugins": ["noice.nvim"]},
    "csv-delim": {"command": "<cmd>RainbowDelim<cr>", "plugins": ["rainbow_csv"]},
    "csv-align": {"command": "<cmd>RainbowAlign<cr>", "plugins": ["rainbow_csv"]},
    "csv-shrink": {"command": "<cmd>RainbowShrink<cr>", "plugins": ["rainbow_csv"]},
    "csv-query": {"command": "<cmd>RainbowQuery<cr>", "plugins": ["rainbow_csv"]},
    "csv-lint": {"command": "<cmd>CSVLint<cr>", "plugins": ["rainbow_csv"]},
    "csv-disable": {"command": "<cmd>NoRainbowDelim<cr>", "plugins": ["rainbow_csv"]},
    "csv-cell-left": {"command": "<cmd>RainbowCellGoLeft<cr>", "plugins": ["rainbow_csv"]},
    "csv-cell-down": {"command": "<cmd>RainbowCellGoDown<cr>", "plugins": ["rainbow_csv"]},
    "csv-cell-up": {"command": "<cmd>RainbowCellGoUp<cr>", "plugins": ["rainbow_csv"]},
    "csv-cell-right": {"command": "<cmd>RainbowCellGoRight<cr>", "plugins": ["rainbow_csv"]},
    "todo-next": {"lua": 'function() require("todo-comments").jump_next() end', "plugins": ["todo-comments.nvim"]},
    "todo-prev": {"lua": 'function() require("todo-comments").jump_prev() end', "plugins": ["todo-comments.nvim"]},
    "http-run": {"lua": 'function() require("kulala").run() end', "plugins": ["kulala.nvim"]},
    "dapui-toggle": {"lua": 'function() require("dapui").toggle({ reset = true }) end', "plugins": ["nvim-dap-ui"]},
    "dap-select-config": {"command": "<cmd>LvimDapSelectConfig<cr>", "plugins": ["nvim-dap-ui"]},
    "dap-restart": {"command": "<cmd>LvimDapRestart<cr>", "plugins": ["nvim-dap-ui"]},
    "flash-jump": {"lua": 'function() require("flash").jump() end', "plugins": ["flash.nvim"]},
    "flash-treesitter": {"lua": 'function() require("flash").treesitter() end', "plugins": ["flash.nvim"]},
    "flash-remote": {"lua": 'function() require("flash").remote() end', "plugins": ["flash.nvim"]},
    "flash-treesitter-search": {"lua": 'function() require("flash").treesitter_search() end', "plugins": ["flash.nvim"]},
    "flash-toggle-search": {"lua": 'function() require("flash").toggle() end', "plugins": ["flash.nvim"]},
    "session-save": {"command": "<cmd>LvimSessionSave<cr>", "plugins": ["folke/persistence.nvim"]},
    "session-load-current": {"command": "<cmd>LvimSessionLoad<cr>", "plugins": ["folke/persistence.nvim"]},
    "session-load-last": {"command": "<cmd>LvimSessionLast<cr>", "plugins": ["folke/persistence.nvim"]},
    "session-select": {"command": "<cmd>LvimSessionSelect<cr>", "plugins": ["folke/persistence.nvim"]},
    "session-delete-current": {"command": "<cmd>LvimSessionDelete<cr>", "plugins": ["folke/persistence.nvim"]},
    "session-stop": {"command": "<cmd>LvimSessionStop<cr>", "plugins": ["folke/persistence.nvim"]},
    "workspace-ide-focus": {"command": "<cmd>LvimWorkspaceIDE<cr>", "plugins": ["aerial.nvim", "trouble.nvim"]},
    "workspace-close": {"command": "<cmd>LvimWorkspaceClose<cr>", "plugins": ["aerial.nvim", "trouble.nvim"]},
    "lint-run": {"command": "<cmd>LvimLint<cr>", "plugins": ["mfussenegger/nvim-lint"]},
    "pdsl-completion": {"lua": 'function() require("config.pdsl").show_completion() end', "plugins": ["blink.cmp"]},
    "workspace-focus": {
        "lua": 'function() require("config.workspace").focus_workspace() end',
        "plugins": ["aerial.nvim", "trouble.nvim"],
    },
    "workspace-testing-focus": {
        "lua": 'function() require("config.workspace").focus_testing() end',
        "plugins": ["neotest"],
    },
    "workspace-debug-focus": {
        "lua": 'function() require("config.workspace").focus_debug() end',
        "plugins": ["nvim-dap-ui"],
    },
    "tmux-shell-bottom": {"lua": 'function() require("config.tmux").project_shell("bottom") end'},
    "tmux-shell-right": {"lua": 'function() require("config.tmux").project_shell("right") end'},
    "tmux-nav-left": {"lua": 'function() require("config.tmux").navigate("left") end'},
    "tmux-nav-down": {"lua": 'function() require("config.tmux").navigate("down") end'},
    "tmux-nav-up": {"lua": 'function() require("config.tmux").navigate("up") end'},
    "tmux-nav-right": {"lua": 'function() require("config.tmux").navigate("right") end'},
}


def lua_list(values: list[str]) -> str:
    return "{ " + ", ".join(lua_string(value) for value in values) + " }"


def get_lvim_plugin_aliases(lvim_config: dict[str, Any]) -> dict[str, str]:
    aliases = lvim_config.get("plugin_aliases", {})
    if not isinstance(aliases, dict):
        raise ValueError("lvim.plugin_aliases debe ser un mapa alias -> plugin.")
    normalized: dict[str, str] = {}
    for alias, plugin in aliases.items():
        if not isinstance(alias, str) or not alias.strip():
            raise ValueError(f"Alias LVim inválido: {alias!r}")
        if not isinstance(plugin, str) or not plugin.strip():
            raise ValueError(f"Plugin LVim inválido para alias {alias!r}: {plugin!r}")
        normalized[alias] = plugin
    return normalized


def normalize_lvim_plugins(value: Any, plugin_aliases: dict[str, str]) -> list[str]:
    if value is None:
        return []
    if isinstance(value, str):
        return [plugin_aliases.get(value, value)]
    if isinstance(value, list) and all(isinstance(item, str) for item in value):
        return [plugin_aliases.get(item, item) for item in value]
    raise ValueError(f"plugins LVim inválidos: {value}")


def merge_lvim_plugins(*plugin_sets: list[str]) -> list[str]:
    merged: list[str] = []
    for plugin_set in plugin_sets:
        for plugin in plugin_set:
            if plugin not in merged:
                merged.append(plugin)
    return merged


def find_repo_root(start: Path) -> Path:
    for candidate in [start, *start.parents]:
        if all((candidate / name).exists() for name in ("hypr", "xmonad", "lvim", "wm-shared")):
            return candidate
    raise RuntimeError("No se pudo localizar la raíz del repositorio dotfiles.")


def load_keybinds(repo_root: Path) -> dict[str, Any]:
    keybinds_path = repo_root / "wm-shared/.config/wm-shared/keybinds.yml"
    return yaml.safe_load(keybinds_path.read_text(encoding="utf-8"))


def iter_wm_sections(config: dict[str, Any]) -> list[tuple[str, list[dict[str, Any]]]]:
    wm_config = config["wm"]
    return [(section, wm_config.get(section, [])) for section in config["meta"]["wm_section_order"]]


def normalize_key_token(token: str) -> str:
    normalized = token.strip().lower()
    return KEY_ALIASES.get(normalized, normalized)


def parse_key_spec(spec: str) -> tuple[list[str], str]:
    tokens = [normalize_key_token(token) for token in spec.split("+")]
    modifiers = [token for token in tokens if token in MOD_ORDER]
    keys = [token for token in tokens if token not in MOD_ORDER]
    if len(keys) != 1:
        raise ValueError(f"Key spec inválida: {spec}")
    return modifiers, keys[0]


def hypr_key_name(key: str) -> str:
    if key in MOUSE_KEYS:
        return MOUSE_KEYS[key]
    if key in XF86_KEYS:
        return XF86_KEYS[key]
    if key in HYPR_SPECIAL_KEYS:
        return HYPR_SPECIAL_KEYS[key]
    if len(key) == 1 and key.isalpha():
        return key.upper()
    if len(key) == 1 and key.isdigit():
        return key
    raise ValueError(f"Tecla Hypr no soportada: {key}")


def xmonad_key_name(key: str) -> str | None:
    if key.startswith("mouse:"):
        return None
    if key in XF86_KEYS:
        return f"<{XF86_KEYS[key]}>"
    if key in XMONAD_SPECIAL_KEYS:
        return XMONAD_SPECIAL_KEYS[key]
    if len(key) == 1 and key.isalpha():
        return key.lower()
    if len(key) == 1 and key.isdigit():
        return key
    raise ValueError(f"Tecla XMonad no soportada: {key}")


def to_hypr_binding(key_spec: str, action_spec: dict[str, str]) -> str:
    modifiers, key = parse_key_spec(key_spec)
    mods = " ".join(HYPR_MODS[modifier] for modifier in MOD_ORDER if modifier in modifiers)
    parts = [mods, hypr_key_name(key), action_spec["dispatcher"]]
    if action_spec.get("arg"):
        parts.append(action_spec["arg"])
    return f'{action_spec.get("kind", "bind")} = {", ".join(parts)}'


def to_xmonad_key(key_spec: str) -> str | None:
    modifiers, key = parse_key_spec(key_spec)
    rendered_key = xmonad_key_name(key)
    if rendered_key is None:
        return None
    prefixes = [XMONAD_MODS[modifier] for modifier in MOD_ORDER if modifier in modifiers]
    return rendered_key if not prefixes else "-".join(prefixes + [rendered_key])


def resolve_hypr_action(entry: dict[str, Any]) -> dict[str, str] | None:
    action_name = entry["action"]
    if action_name == "workspace-focus":
        workspace = int(entry["workspace"])
        return {"dispatcher": "workspace", "arg": str(workspace)} if workspace != 0 else None
    if action_name == "workspace-move":
        workspace = int(entry["workspace"])
        return {"dispatcher": "movetoworkspace", "arg": str(workspace)} if workspace != 0 else None
    return HYPR_ACTIONS.get(action_name)


def resolve_xmonad_spec(entry: dict[str, Any]) -> tuple[str, str, str | None] | None:
    key_name = to_xmonad_key(entry["key"])
    if key_name is None:
        return None
    action_name = entry["action"]
    if action_name == "workspace-focus":
        return key_name, action_name, WORKSPACE_NAMES[int(entry["workspace"])]
    if action_name == "workspace-move":
        return key_name, action_name, WORKSPACE_NAMES[int(entry["workspace"])]
    if action_name in XMONAD_ACTIONS:
        return key_name, action_name, None
    return None


def render_hypr(config: dict[str, Any]) -> str:
    lines = [
        "# -----------------------------------------------------------------------------",
        "# Generated from wm-shared/.config/wm-shared/keybinds.yml",
        "# Do not edit manually. Run ~/.config/wm-shared/scripts/bin/system/sync_keybinds.sh --target hypr",
        "# -----------------------------------------------------------------------------",
        "",
    ]
    for section, entries in iter_wm_sections(config):
        rendered: list[str] = []
        for entry in entries:
            action_spec = resolve_hypr_action(entry)
            if not action_spec:
                continue
            if entry.get("description"):
                rendered.append(f'# {entry["description"]}')
            rendered.append(to_hypr_binding(entry["key"], action_spec))
        if rendered:
            lines.extend(
                [
                    "# =============================================================================",
                    f"# {SECTION_TITLES.get(section, section.title())}",
                    "# =============================================================================",
                    *rendered,
                    "",
                ]
            )
    return "\n".join(lines).rstrip() + "\n"


def dump_xmonad_specs(config: dict[str, Any]) -> str:
    lines: list[str] = []
    for _, entries in iter_wm_sections(config):
        for entry in entries:
            spec = resolve_xmonad_spec(entry)
            if not spec:
                continue
            key_name, action_name, arg = spec
            lines.append("\t".join([key_name, action_name, arg or "-"]))
    return "\n".join(lines) + ("\n" if lines else "")


def validate_lvim_target(target: Any, context: str) -> None:
    if target is None:
        return
    if target not in {"m", "vm"}:
        raise ValueError(f"{context}: target LVim inválido: {target!r}")


def validate_lvim_mode(mode: Any, context: str) -> None:
    if isinstance(mode, str) and mode:
        return
    raise ValueError(f"{context}: mode LVim inválido: {mode!r}")


def validate_lvim_filetype(value: Any, context: str) -> None:
    if isinstance(value, str) and value:
        return
    if isinstance(value, list) and value and all(isinstance(item, str) and item for item in value):
        return
    raise ValueError(f"{context}: filetype LVim inválido: {value!r}")


def validate_lvim_plugins(value: Any, context: str) -> None:
    if value is None:
        return
    if isinstance(value, str) and value:
        return
    if isinstance(value, list) and all(isinstance(item, str) and item for item in value):
        return
    raise ValueError(f"{context}: plugins LVim inválidos: {value!r}")


def validate_lvim_entry_payload(entry: dict[str, Any], context: str) -> None:
    payload_keys = [key for key in ("action", "command", "ref", "lua") if key in entry]
    if len(payload_keys) != 1:
        raise ValueError(f"{context}: cada entrada debe tener exactamente uno de action/command/ref/lua.")
    if payload_keys == ["action"] and entry["action"] not in LVIM_ACTIONS:
        raise ValueError(f"{context}: acción LVim no soportada: {entry['action']!r}")


def validate_lvim_entry(entry: Any, context: str, *, allow_filetype: bool = False) -> None:
    if not isinstance(entry, dict):
        raise ValueError(f"{context}: la entrada debe ser un mapa.")
    validate_lvim_plugins(entry.get("plugins"), context)
    if "description" not in entry or not isinstance(entry["description"], str) or not entry["description"]:
        raise ValueError(f"{context}: description es obligatorio.")
    if "filetype" in entry:
        if not allow_filetype:
            raise ValueError(f"{context}: filetype solo está soportado en direct_map.")
        validate_lvim_filetype(entry["filetype"], context)
    validate_lvim_entry_payload(entry, context)


def validate_lvim_item(item: Any, context: str) -> None:
    if not isinstance(item, dict):
        raise ValueError(f"{context} debe ser un mapa.")

    kind = item.get("kind")
    if kind == "section":
        if not isinstance(item.get("title"), str) or not item["title"]:
            raise ValueError(f"{context}: section requiere title.")
        return

    if kind == "binding":
        validate_lvim_target(item.get("target", "m"), context)
        if not isinstance(item.get("key"), str) or not item["key"]:
            raise ValueError(f"{context}: binding requiere key.")
        validate_lvim_entry(item, context)
        return

    if kind == "group":
        writer = item.get("writer", "wk_extend")
        if writer not in {"assign", "wk_extend", "wk_extend_v"}:
            raise ValueError(f"{context}: writer LVim no soportado: {writer}")
        if writer == "assign":
            validate_lvim_target(item.get("target", "m"), context)
        if not isinstance(item.get("key"), str) or not item["key"]:
            raise ValueError(f"{context}: group requiere key.")
        validate_lvim_plugins(item.get("plugins"), context)
        entries = item.get("entries", [])
        if not isinstance(entries, list):
            raise ValueError(f"{context}: entries debe ser una lista.")
        for entry_index, entry in enumerate(entries):
            validate_lvim_entry(entry, f"{context}.entries[{entry_index}]")
            if "key" not in entry or not isinstance(entry["key"], str) or not entry["key"]:
                raise ValueError(f"{context}.entries[{entry_index}]: key es obligatorio.")
        return

    if kind == "direct_map":
        validate_lvim_mode(item.get("mode"), context)
        if not isinstance(item.get("lhs"), str) or not item["lhs"]:
            raise ValueError(f"{context}: direct_map requiere lhs.")
        validate_lvim_entry(item, context, allow_filetype=True)
        return

    raise ValueError(f"{context}: tipo de item LVim no soportado: {kind!r}")


def validate_lvim_config(lvim_config: dict[str, Any]) -> dict[str, str]:
    plugin_aliases = get_lvim_plugin_aliases(lvim_config)
    items = lvim_config.get("items", [])
    keymaps = lvim_config.get("keymaps", [])
    if not isinstance(items, list):
        raise ValueError("lvim.items debe ser una lista.")
    if not isinstance(keymaps, list):
        raise ValueError("lvim.keymaps debe ser una lista.")
    for index, item in enumerate(items):
        validate_lvim_item(item, f"lvim.items[{index}]")
    for index, item in enumerate(keymaps):
        validate_lvim_item(item, f"lvim.keymaps[{index}]")
    return plugin_aliases


def render_lvim(config: dict[str, Any]) -> str:
    lvim_config = config.get("lvim", {})
    if "lua" in lvim_config:
        raise ValueError("lvim.lua ya no está soportado; usa lvim.items y/o lvim.keymaps en keybinds.yml.")
    plugin_aliases = validate_lvim_config(lvim_config)
    items_body = render_lvim_items(lvim_config.get("items", []), plugin_aliases)
    keymaps_body = render_lvim_keymaps(lvim_config.get("keymaps", []), plugin_aliases)
    sections = [section for section in [items_body, keymaps_body] if section]
    body = "\n\n".join(sections)
    return f"""---@diagnostic disable: undefined-global
-- -----------------------------------------------------------------------------
-- Generated from wm-shared/.config/wm-shared/keybinds.yml
-- Do not edit manually. Run ~/.config/wm-shared/scripts/bin/system/sync_keybinds.sh --target lvim
-- -----------------------------------------------------------------------------

local u = require("config.utils")
local m = u.m
local vm = u.vm
local map = u.map

{body}
"""


def lua_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def render_lua_key(key: str) -> str:
    return key if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key) else f"[{lua_string(key)}]"


def resolve_lvim_payload_value(entry: dict[str, Any]) -> str:
    if "command" in entry:
        return lua_string(entry["command"])
    if "ref" in entry:
        return entry["ref"]
    if "lua" in entry:
        return entry["lua"]
    raise ValueError(f"Entrada LVim inválida, falta command/ref/lua: {entry}")


def resolve_lvim_entry(entry: dict[str, Any], plugin_aliases: dict[str, str]) -> tuple[str, list[str]]:
    if "action" in entry:
        action_name = entry["action"]
        resolved = LVIM_ACTIONS.get(action_name)
        if not resolved:
            raise ValueError(f"Acción LVim no soportada: {action_name}")
        value = resolve_lvim_payload_value(resolved)
        plugins = normalize_lvim_plugins(resolved.get("plugins"), plugin_aliases)
        return value, plugins
    value = resolve_lvim_payload_value(entry)
    plugins = normalize_lvim_plugins(entry.get("plugins"), plugin_aliases)
    return value, plugins


def wrap_lvim_entry_value(value: str, plugins: list[str]) -> str:
    if not plugins:
        return value
    return f"u.lazy_wrap({lua_list(plugins)}, {value})"


def render_lvim_section(title: str) -> str:
    return "\n".join(
        [
            "-- =================================================================",
            f"-- {title}",
            "-- =================================================================",
        ]
    )


def render_lvim_binding(item: dict[str, Any], plugin_aliases: dict[str, str]) -> str:
    target = item.get("target", "m")
    value, entry_plugins = resolve_lvim_entry(item, plugin_aliases)
    plugins = merge_lvim_plugins(entry_plugins, normalize_lvim_plugins(item.get("plugins"), plugin_aliases))
    value = wrap_lvim_entry_value(value, plugins)
    description = lua_string(item["description"])
    return f"u.wk_assign({lua_string(target)}, {lua_string(item['key'])}, {{ {value}, {description} }})"


def render_lvim_group(group: dict[str, Any], plugin_aliases: dict[str, str]) -> str:
    writer = group.get("writer", "wk_extend")
    if writer not in {"assign", "wk_extend", "wk_extend_v"}:
        raise ValueError(f"Writer LVim no soportado: {writer}")

    if writer == "assign":
        target = group.get("target", "m")
        lines = [f'u.wk_assign({lua_string(target)}, {lua_string(group["key"])}, {{']
    else:
        lines = [f'u.{writer}({lua_string(group["key"])}, {{']
    group_plugins = normalize_lvim_plugins(group.get("plugins"), plugin_aliases)
    if group.get("name"):
        lines.append(f'  name = {lua_string(group["name"])},')
    for entry in group.get("entries", []):
        value, entry_plugins = resolve_lvim_entry(entry, plugin_aliases)
        plugins = merge_lvim_plugins(group_plugins, entry_plugins, normalize_lvim_plugins(entry.get("plugins"), plugin_aliases))
        value = wrap_lvim_entry_value(value, plugins)
        description = lua_string(entry["description"])
        lines.append(f"  {render_lua_key(entry['key'])} = {{ {value}, {description} }},")
    lines.append("})")
    return "\n".join(lines)


def render_lvim_direct_map(item: dict[str, Any], plugin_aliases: dict[str, str]) -> str:
    value, entry_plugins = resolve_lvim_entry(item, plugin_aliases)
    plugins = merge_lvim_plugins(entry_plugins, normalize_lvim_plugins(item.get("plugins"), plugin_aliases))
    value = wrap_lvim_entry_value(value, plugins)
    description = lua_string(item["description"])
    if "filetype" in item:
        filetype = item["filetype"]
        filetype_expr = lua_string(filetype) if isinstance(filetype, str) else lua_list(filetype)
        return f"u.filetype_direct_map({filetype_expr}, {lua_string(item['mode'])}, {lua_string(item['lhs'])}, {value}, {description})"
    return f"u.direct_map({lua_string(item['mode'])}, {lua_string(item['lhs'])}, {value}, {description})"


def render_lvim_item(item: dict[str, Any], plugin_aliases: dict[str, str]) -> str:
    kind = item["kind"]
    if kind == "section":
        return render_lvim_section(item["title"])
    if kind == "binding":
        return render_lvim_binding(item, plugin_aliases)
    if kind == "group":
        return render_lvim_group(item, plugin_aliases)
    if kind == "direct_map":
        return render_lvim_direct_map(item, plugin_aliases)
    raise ValueError(f"Tipo de item LVim no soportado: {kind}")


def render_lvim_items(items: list[dict[str, Any]], plugin_aliases: dict[str, str]) -> str:
    if not items:
        return ""
    return "\n\n".join(render_lvim_item(item, plugin_aliases) for item in items)


def render_lvim_keymaps(groups: list[dict[str, Any]], plugin_aliases: dict[str, str]) -> str:
    if not groups:
        return ""
    return "\n\n".join(render_lvim_group(group, plugin_aliases) for group in groups)


def write_if_changed(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text(encoding="utf-8") == content:
        return
    path.write_text(content, encoding="utf-8")


def generate_targets(repo_root: Path, config: dict[str, Any], targets: set[str]) -> None:
    if "hypr" in targets:
        write_if_changed(repo_root / "hypr/.config/hypr/conf/keybinds/generated.conf", render_hypr(config))
    if "lvim" in targets:
        write_if_changed(repo_root / "lvim/.config/lvim/lua/config/keymaps/generated.lua", render_lvim(config))


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate Hyprland, XMonad and LunarVim keybind outputs.")
    parser.add_argument("--target", action="append", choices=("all", "hypr", "xmonad", "lvim"), help="Target(s) to generate. Defaults to all.")
    parser.add_argument("--dump-xmonad-specs", action="store_true", help="Print xmonad keybind specs derived directly from keybinds.yml.")
    args = parser.parse_args()

    repo_root = find_repo_root(Path(__file__).resolve())
    config = load_keybinds(repo_root)

    if args.dump_xmonad_specs:
        sys.stdout.write(dump_xmonad_specs(config))
        return

    requested = set(args.target or ["all"])
    targets = {"hypr", "xmonad", "lvim"} if "all" in requested else requested
    generate_targets(repo_root, config, targets)


if __name__ == "__main__":
    main()
