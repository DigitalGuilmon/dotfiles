-- =================================================================
-- 🎨 REFINAMIENTO VISUAL FINAL
-- =================================================================
local env = require("config.env")

local function set_visual_polish()
  local hl = vim.api.nvim_set_hl

  -- Paleta Material Deep Ocean
  local material_blue = "#82aaff"
  local material_cyan = "#89ddff"
  local material_bg_alt = "#1a1e2a"

  -- Fix Cabeceras Markdown
  hl(0, "RenderMarkdownH1", { fg = material_blue, bold = true })
  hl(0, "RenderMarkdownH1Bg", { bg = "#1e2332", fg = material_blue, bold = true })
  hl(0, "RenderMarkdownH2", { fg = material_cyan, bold = true })
  hl(0, "RenderMarkdownH3", { fg = "#addbff", bold = true })

  -- Treesitter Highlighting
  hl(0, "@markup.heading.1.markdown", { fg = material_blue, bold = true })
  hl(0, "@markup.heading.2.markdown", { fg = material_cyan, bold = true })

  -- UI y Ventanas
  hl(0, "NormalFloat", { bg = "none" })
  hl(0, "FloatBorder", { fg = material_blue, bg = "none" })
  hl(0, "CursorLine", { bg = material_bg_alt })
  hl(0, "CursorLineNr", { fg = "#c792ea", bold = true })

  hl(0, "BlinkCmpMenu", { bg = "#0d1117" })
  hl(0, "DiagnosticVirtualTextError", { fg = "#ff5370", italic = true })
end

-- Ejecución y Autocmds
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_visual_polish })
set_visual_polish()

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.conceallevel = 2
  end,
})
