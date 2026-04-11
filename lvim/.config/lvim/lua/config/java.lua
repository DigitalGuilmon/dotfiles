local env = require("config.env")

local warned_missing_spoon = false

vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function(args)
    if not env.spoon_lsp_enabled() then
      return
    end

    local cmd, spoon = env.spoon_lsp_command()
    if not cmd then
      if not warned_missing_spoon and not env.is_headless_sanity() then
        vim.notify(
          "Spoon LSP no está listo: " .. spoon.reason
            .. ". Usa ./scripts/lvim-prepare-spoon.sh o configura SPOON_JDT_LSP_JAR/SPOON_JDT_LSP_DIR.",
          vim.log.levels.WARN
        )
        warned_missing_spoon = true
      end
      return
    end

    local root_dir = env.java_project_root(args.buf)
    if not root_dir then
      return
    end

    vim.lsp.start({
      name = "spoon-lsp",
      cmd = cmd,
      root_dir = root_dir,
      settings = {},
    }, {
      bufnr = args.buf,
      reuse_client = function(client, config)
        return client.name == config.name and client.config.root_dir == config.root_dir
      end,
    })
  end,
})
