local base = require("config.profiles.laptop")

return vim.tbl_deep_extend("force", base, {
  -- MacBook Air M4: keep the portable workflow lean and default to faster
  -- hosted models that feel snappy on the road.
  ai_provider = "gemini",
  ai_models = {
    claude = "claude-3-5-haiku-latest",
    deepseek = "deepseek-chat",
    gemini = "gemini-2.5-flash",
    githubmodels = "gpt-4o-mini",
    openai = "gpt-4.1-mini",
    xai = "grok-beta",
  },
  repl_python_candidates = { "ipython", "python3", "/opt/homebrew/bin/python3", "python" },
})
