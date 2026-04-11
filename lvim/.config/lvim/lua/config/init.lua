---@diagnostic disable: undefined-global

require("config.core")
require("config.plugins")
require("config.ai")
require("config.lsp")
require("config.tmux")
require("config.mode")
require("config.workspace")
require("config.session")
require("config.setup_info")
require("config.java")
require("config.pdsl")
require("config.ai")
-- Declarative keymaps live in wm-shared/.config/wm-shared/keybinds.yml.
-- Regenerate generated.lua through sync_keybinds.sh; do not hand-edit it.
require("config.keymaps.generated")
require("config.ui")
