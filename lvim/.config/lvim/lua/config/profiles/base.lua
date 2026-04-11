return {
  -- Base keeps niche integrations disabled so extra workflows stay opt-in.
  ai_provider = "gemini",
  ai_api_key_env = "GEMINI_API_KEY",
  ai_models = {
    claude = "claude-sonnet-4-20250514",
    deepseek = "deepseek-chat",
    gemini = "gemini-2.5-pro",
    githubmodels = "gpt-4o",
    openai = "gpt-4.1",
    xai = "grok-beta",
  },
  notes_autosave_enabled = true,
  notes_autosave_filetypes = { "gitcommit", "markdown", "mdx", "norg", "org", "rst", "text" },
  repl_shell_candidates = { "zsh", "sh" },
  repl_python_candidates = { "ipython", "python3", "python" },
  features = {
    challenge_tools = false,
    csv_tools = false,
    database_tools = false,
    http_tools = false,
    latex_tools = false,
    notebook_tools = false,
    repl_tools = false,
  },
}
