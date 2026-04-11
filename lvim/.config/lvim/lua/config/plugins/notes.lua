local env = require("config.env")

return {
  {
    "epwalsh/obsidian.nvim",
    ft = "markdown",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      workspaces = {
        { name = env.obsidian_workspace_name(), path = env.obsidian_vault_dir() },
      },
      ui = { enabled = false },
      templates = { subdir = "templates", date_format = "%Y-%m-%d", time_format = "%H:%M" },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = env.has_ui(),
    ft = { "markdown", "codecompanion" },
    opts = {
      preset = "obsidian",
      checkbox = { enabled = true },
      latex = { enabled = true },
    },
  },
}
