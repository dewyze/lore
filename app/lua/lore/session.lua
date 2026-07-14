-- What "being in a vault" means editor-side: cwd follows the active vault
-- (scopes rg/pickers for free) and todo.md is the landing buffer.
local vaults = require("lore.vaults")

local M = {}

function M.open_vault(vault)
  vim.cmd.cd(vim.fn.fnameescape(vault.path))
  vim.cmd.edit(vim.fn.fnameescape(vault.path .. "/todo.md"))
end

function M.startup()
  if vim.fn.argc() > 0 then
    return
  end
  local vault = vaults.active()
  if vault then
    M.open_vault(vault)
  else
    vim.notify("no vaults registered — :LoreVaultAdd {name} {path}", vim.log.levels.INFO)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = M.startup })
end

return M
