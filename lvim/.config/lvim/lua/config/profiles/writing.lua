return {
  -- Writing overlay for markdown-heavy note taking and prose work.
  ai_models = {
    gemini = "gemini-2.5-flash",
  },
  notes_autosave_enabled = true,
  notes_autosave_filetypes = { "gitcommit", "markdown", "mdx", "org", "rst", "text" },
  features = {
    latex_tools = true,
  },
}
