return {
  -- Backend/API overlay with DB and request tooling always on.
  ai_provider = "githubmodels",
  ai_models = {
    githubmodels = "gpt-4o",
  },
  features = {
    database_tools = true,
    http_tools = true,
  },
}
