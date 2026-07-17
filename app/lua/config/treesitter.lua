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

local M = {}

-- [!]/[/] checkboxes parse as shortcut links, and the stock
-- markdown_inline query conceals shortcut-link brackets — turning them
-- into bare ! and /. Strip exactly that rule; real [t](u) links keep
-- their concealment. Returns the transformed text (nil if the rule
-- wasn't found, e.g. after an nvim upgrade reshapes the query).
function M.strip_shortcut_conceal(text)
  local replaced, count = text:gsub(
    "; Conceal shortcut links\n%(shortcut_link.-%)%)",
    '(shortcut_link\n  [\n    "["\n    "]"\n  ] @markup.link)'
  )
  if count == 0 then
    return nil
  end
  return replaced
end

pcall(function()
  local chunks = {}
  for _, file in ipairs(vim.treesitter.query.get_files("markdown_inline", "highlights")) do
    chunks[#chunks + 1] = table.concat(vim.fn.readfile(file), "\n")
  end
  local stripped = M.strip_shortcut_conceal(table.concat(chunks, "\n"))
  if stripped then
    vim.treesitter.query.set("markdown_inline", "highlights", stripped)
  end
end)

return M
