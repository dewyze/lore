-- Tag retrieval: live rg, no cache (rg is the retrieval floor).
-- Two sources: inline #tags and frontmatter `tags:` (scalar or inline
-- array). YAML block-style tag lists aren't supported — rg is line-based.
local M = {}

local INLINE = [[#[A-Za-z][A-Za-z0-9_/-]*]]
local FRONTMATTER = [[^tags:\s*.+$]]

local function rg(pattern, path)
  local result = vim.system({
    "rg",
    "--only-matching",
    "--no-filename",
    "--no-line-number",
    "--no-messages",
    pattern,
    path,
  }):wait()
  if result.code ~= 0 then
    return {}
  end
  return vim.split(result.stdout or "", "\n", { trimempty = true })
end

function M.collect(path)
  local seen = {}
  for _, match in ipairs(rg(INLINE, path)) do
    seen[match:sub(2)] = true
  end
  for _, line in ipairs(rg(FRONTMATTER, path)) do
    local value = line:match("^tags:%s*(.-)%s*$")
    value = value:match("^%[(.*)%]$") or value
    for tag in value:gmatch("[^,%s]+") do
      seen[tag] = true
    end
  end
  local tags = vim.tbl_keys(seen)
  table.sort(tags)
  return tags
end

return M
