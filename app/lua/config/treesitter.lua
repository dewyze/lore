-- Parser install only — core 0.12 owns the treesitter runtime, and the
-- bundled markdown queries already inject yaml into frontmatter and fence
-- languages into code blocks. NVIM_APPNAME isolates lore's data dir, so
-- these install on first launch regardless of the main nvim setup.
local PARSERS = {
  "yaml", -- frontmatter
  -- code-fence injection languages; adjust freely
  "ruby",
  "bash",
  "lua",
  "sql",
  "json",
}

-- async and idempotent; pcall so an offline launch still boots
pcall(function()
  require("nvim-treesitter").install(PARSERS)
end)
