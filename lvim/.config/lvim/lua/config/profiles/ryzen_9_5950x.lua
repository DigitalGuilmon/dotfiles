local base = require("config.profiles.workstation")

return vim.tbl_deep_extend("force", base, {
  -- Ryzen 9 5950X workstation: favor the higher quality coding models and keep
  -- the heavier local workflows enabled.
  ai_provider = "claude",
  ai_models = {
    claude = "claude-sonnet-4-20250514",
    deepseek = "deepseek-reasoner",
    gemini = "gemini-2.5-pro",
    githubmodels = "gpt-4o",
    openai = "gpt-4.1",
    xai = "grok-beta",
  },
})
