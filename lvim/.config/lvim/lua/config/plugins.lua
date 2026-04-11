-- =================================================================
-- 📦 PLUGINS (modularizado por dominios)
-- =================================================================

local modules = {
  "config.plugins.ui",
  "config.plugins.ai",
  "config.plugins.notes",
  "config.plugins.languages",
  "config.plugins.science",
  "config.plugins.editing",
}

lvim.plugins = {}

for _, module in ipairs(modules) do
  vim.list_extend(lvim.plugins, require(module))
end
