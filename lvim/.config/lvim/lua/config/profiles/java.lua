return {
  -- Activate with LVIM_PROFILE=personal,java after preparing spoon-jdt-lsp.
  spoon_lsp_enabled = true,
  spoon_lsp_jar_candidates = {
    "~/dev/spoon-jdt-lsp/target/spoon-jdt-lsp-1.0-SNAPSHOT-jar-with-dependencies.jar",
    "~/dev/lsp_base/spoon-jdt-lsp/target/spoon-jdt-lsp-1.0-SNAPSHOT-jar-with-dependencies.jar",
  },
  spoon_lsp_source_dir_candidates = {
    "~/dev/spoon-jdt-lsp",
    "~/dev/lsp_base/spoon-jdt-lsp",
  },
}
