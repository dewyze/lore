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
    -- deferred past the startup redraw, which eats immediate notifies
    vim.defer_fn(function()
      vim.notify("no vaults registered — :VaultAdd {path} (or \\va)", vim.log.levels.WARN)
    end, 250)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = M.startup })
end

return M
