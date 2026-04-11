return {
  -- Default daily-driver profile. Enables common DB/API/CSV tooling while
  -- keeping challenge, notebook, and LaTeX extras opt-in.
  obsidian_workspace_name = "notes",
  obsidian_vault_dir = "~/dotfiles/vaults/personal",
  features = {
    csv_tools = true,
    database_tools = true,
    http_tools = true,
  },
}
