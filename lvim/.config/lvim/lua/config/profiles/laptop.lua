return {
  -- Portable-machine overlay: keep the common personal workflow, but avoid
  -- heavier local-only extras by default.
  ai_models = {
    gemini = "gemini-2.5-flash",
  },
  features = {
    database_tools = false,
    latex_tools = false,
    notebook_tools = false,
    repl_tools = false,
  },
  notes_autosave_filetypes = { "gitcommit", "markdown", "mdx", "text" },
}
