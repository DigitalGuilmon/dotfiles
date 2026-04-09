-- =================================================================
-- 🎨 REFINAMIENTO VISUAL FINAL
-- =================================================================
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


-- Configuración para tu LSP personalizado de Spoon
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    local jar_path = vim.fn.expand("~/dev/spoon-jdt-lsp/target/spoon-jdt-lsp-1.0-SNAPSHOT-jar-with-dependencies.jar")
    if vim.fn.filereadable(jar_path) == 0 then
      vim.notify("Spoon LSP JAR no encontrado: " .. jar_path, vim.log.levels.WARN)
      return
    end

    -- Comando para iniciar el servidor
    local cmd = { "java", "-jar", jar_path }
    local root_marker = vim.fs.find({ 'pom.xml', '.git' }, { upward = true })[1]
    if not root_marker then
      vim.notify("No se encontró root_dir para spoon-lsp (pom.xml/.git).", vim.log.levels.WARN)
      return
    end

    -- Iniciar el cliente LSP
    vim.lsp.start({
      name = "spoon-lsp",
      cmd = cmd,
      root_dir = vim.fs.dirname(root_marker),
      settings = {},
    })
  end,
})
