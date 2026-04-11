local env = require("config.env")
local image_info = env.image_backend_info()
local image_backend = image_info.backend
local warned_image_backend = false

local function maybe_warn_image_backend()
  if warned_image_backend or image_backend or not image_info.reason or #vim.api.nvim_list_uis() == 0 then
    return
  end
  warned_image_backend = true
  vim.schedule(function()
    vim.notify(image_info.reason, vim.log.levels.WARN, { title = "LVim Molten" })
  end)
end

return {
  {
    "3rd/image.nvim",
    build = false,
    enabled = image_backend ~= nil,
    ft = { "markdown", "python", "quarto" },
    opts = function()
      return {
        backend = image_backend,
        processor = "magick_cli",
        integrations = {
          markdown = {
            clear_in_insert_mode = false,
            download_remote_images = true,
            enabled = true,
            filetypes = { "markdown", "quarto" },
            only_render_image_at_cursor = false,
          },
        },
        max_height_window_percentage = 40,
        max_width_window_percentage = 60,
      }
    end,
  },
  {
    "benlubas/molten-nvim",
    enabled = env.feature_enabled("notebook_tools"),
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    dependencies = image_backend and { "3rd/image.nvim" } or {},
    ft = { "python", "quarto", "markdown" },
    init = function()
      vim.g.molten_image_provider = image_backend and "image.nvim" or "none"
      vim.g.molten_auto_open_output = false
      vim.g.molten_output_win_max_height = 20
      maybe_warn_image_backend()
    end,
  },
  {
    "Vigemus/iron.nvim",
    enabled = env.feature_enabled("repl_tools"),
    cmd = { "IronRepl", "IronRestart", "IronFocus", "IronHide" },
    config = function()
      require("iron.core").setup({
        config = {
          scratch_repl = true,
          repl_definition = {
            sh = { command = { env.preferred_shell() } },
            python = { command = { env.preferred_repl_python() } },
          },
          repl_open_cmd = require("iron.view").split.vertical.botright(50),
        },
      })
    end,
  },
}
