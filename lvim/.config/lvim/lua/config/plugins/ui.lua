local env = require("config.env")
local u = require("config.utils")
local session = require("config.session")

local function dashboard_action(plugins, rhs)
  return u.lazy_wrap(plugins, rhs)
end

return {
  { "mbbill/undotree", cmd = "UndotreeToggle" },
  {
    "marko-cerovac/material.nvim",
    priority = 1000,
    config = function()
      require("material").setup({
        lualine_style = "stealth",
        async_loading = true,
        custom_colors = function(colors)
          colors.editor.bg = "#0d1117"
        end,
      })
      vim.cmd.colorscheme("material")
    end,
  },
  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    opts = {
      extra_groups = {
        "NormalFloat",
        "NvimTreeNormal",
        "CursorLine",
        "FloatBorder",
        "StatusLine",
        "StatusLineNC",
        "SignColumn",
        "EndOfBuffer",
      },
      on_clear = function()
        local transparent = require("transparent")
        transparent.clear_prefix("BufferLine")
        transparent.clear_prefix("lualine")
        transparent.clear_prefix("Snacks")
        transparent.clear_prefix("Telescope")
        transparent.clear_prefix("Trouble")
        transparent.clear_prefix("Aerial")
        transparent.clear_prefix("Noice")
      end,
    },
    config = function(_, opts)
      vim.g.transparent_enabled = true
      require("transparent").setup(opts)
      require("transparent").clear()
    end,
  },
  {
    "folke/noice.nvim",
    enabled = env.has_ui(),
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      lsp = { override = { ["vim.lsp.util.convert_input_to_markdown_lines"] = true, ["vim.lsp.util.stylize_markdown"] = true } },
      presets = { bottom_search = true, command_palette = true, long_message_to_split = true },
    },
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = function(_, opts)
      opts = opts or {}
      return vim.tbl_deep_extend("force", opts, {
        dashboard = {
          enabled = env.has_ui(),
          width = 52,
          preset = {
            header = [[
Zenith AI
minimal workspace]],
            keys = {
              { icon = " ", key = "f", desc = "Smart Find", action = function() Snacks.picker.smart() end },
              { icon = " ", key = "r", desc = "Recent Files", action = function() Snacks.picker.recent() end },
              { icon = " ", key = "g", desc = "Find Text", action = function() Snacks.picker.grep() end },
              { icon = " ", key = "e", desc = "Ranger Explorer", action = dashboard_action({ "kelly-lin/ranger.nvim" }, function() require("ranger-nvim").open(true) end) },
              { icon = " ", key = "l", desc = "Lazygit", action = function() Snacks.lazygit() end },
              { icon = "󰰶 ", key = "z", desc = "Toggle IDE / Zen", action = "<cmd>LvimModeToggle<cr>" },
              { icon = " ", key = "s", desc = "Restore Last Session", action = function() session.load_last() end },
              { icon = " ", key = "p", desc = "Project Shell (tmux)", action = "<cmd>LvimTmuxShellBottom<cr>" },
              { icon = "󰙅 ", key = "w", desc = "Workspace Panels", action = "<cmd>LvimWorkspaceFocus<cr>" },
              { icon = " ", key = "q", desc = "Quit", action = "<cmd>qa<cr>" },
            },
          },
          sections = {
            { section = "header" },
            { section = "keys", gap = 1, padding = 1 },
            { section = "startup", padding = 1 },
          },
        },
        notifier = { enabled = false },
        input = { enabled = env.has_ui() },
        picker = { enabled = true, ui_select = true },
        indent = { enabled = env.has_ui(), char = "╎", scope = { enabled = env.has_ui(), char = "┃" } },
        scroll = { enabled = env.has_ui() },
        persistence = { enabled = true },
        lazygit = { enabled = env.has_ui() },
        zen = { enabled = env.has_ui() },
        terminal = { enabled = env.has_ui() },
        scratch = { enabled = env.has_ui() },
        image = { enabled = env.has_ui() },
      })
    end,
  },
}
