-- Quick capture: append to the active vault's inbox.md. Append-only,
-- unsorted lines; organization is deferred, not required.
local vaults = require("lore.vaults")

local M = {}

function M.append(text)
  text = vim.trim(text or "")
  if text == "" then
    return
  end
  local vault = vaults.active()
  if not vault then
    error("no active vault")
  end
  local file = assert(io.open(vault.path .. "/inbox.md", "a"))
  file:write(text .. "\n")
  file:close()
end

return M
