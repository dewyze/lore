-- Inbound links: live rg over the active vault, no cache, no index.
local vaults = require("lore.vaults")

local M = {}

-- Lines anywhere in the vault linking to `path`. Links are root-relative
-- (/dir/file.md), so one fixed-string search finds them all.
function M.find(path)
  local vault = vaults.active()
  if not vault then
    return {}
  end
  path = vim.uv.fs_realpath(path) or path
  local relative = path:gsub("^" .. vim.pesc(vault.path), "")
  local result = vim.system({
    "rg",
    "--fixed-strings",
    "--line-number",
    "--no-heading",
    "--no-messages",
    "(" .. relative .. ")",
    vault.path,
  }):wait()
  if result.code ~= 0 then
    return {}
  end
  local found = {}
  for _, line in ipairs(vim.split(result.stdout or "", "\n", { trimempty = true })) do
    local file, lnum, text = line:match("^(.-):(%d+):(.*)$")
    if file and file ~= path then
      table.insert(found, { file = file, lnum = tonumber(lnum), text = vim.trim(text) })
    end
  end
  return found
end

return M
