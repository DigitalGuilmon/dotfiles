-- =================================================================
-- 📝 OBSIDIAN
-- =================================================================
local m = require("config.utils").m


m["o"] = {
  name = "Obsidian",
  n = { "<cmd>ObsidianNew<cr>", "Nueva Nota" },
  t = {
    function()
      local templates_dir = vim.fn.expand("~/vaults/personal/templates")
      require("snacks").picker.files({
        cwd = templates_dir,
        title = "Seleccionar Plantilla",
        confirm = function(picker, item)
          picker:close()
          vim.cmd("ObsidianTemplate " .. item.text)
        end,
      })
    end,
    "Insertar Plantilla"
  },
  s = {
    function() require("snacks").picker.files({ cwd = "~/vaults/personal" }) end,
    "Buscar en Vault"
  },
  l = { "<cmd>ObsidianLink<cr>", "Linkear Selección" },
  d = { "<cmd>ObsidianToday<cr>", "Nota Diaria (Hoy)" },
  b = { "<cmd>ObsidianBacklinks<cr>", "Ver Backlinks" },
  f = { "<cmd>ObsidianFollowLink<cr>", "Seguir Enlace Bajo el Cursor" },
}
