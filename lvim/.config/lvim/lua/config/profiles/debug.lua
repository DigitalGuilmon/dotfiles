return {
  -- Debug-focused overlay for service troubleshooting sessions.
  ai_provider = "githubmodels",
  ai_models = {
    githubmodels = "gpt-4o",
  },
  notes_autosave_enabled = false,
  features = {
    database_tools = true,
    http_tools = true,
  },
}
