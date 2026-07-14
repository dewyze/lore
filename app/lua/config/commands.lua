-- User commands are the app's real interface; keymaps only dispatch here.
local vaults = require("lore.vaults")
local session = require("lore.session")

local function notify_error(err)
  vim.notify((err:gsub("^.-:%d+: ", "")), vim.log.levels.ERROR)
end

vim.api.nvim_create_user_command("LoreVaultAdd", function(opts)
  local name, path = unpack(opts.fargs)
  if not (name and path) then
    return notify_error("usage: LoreVaultAdd {name} {path}")
  end
  local ok, err = pcall(vaults.add, name, path)
  if not ok then
    return notify_error(err)
  end
  local active = vaults.active()
  if active.name == name then
    session.open_vault(active)
  end
end, { nargs = "+", complete = "dir", desc = "Register a vault (scaffold + git init)" })

vim.api.nvim_create_user_command("LoreVaultList", function()
  local lines = {}
  local active = vaults.active()
  for _, vault in ipairs(vaults.list()) do
    local marker = (active and active.name == vault.name) and "*" or " "
    table.insert(lines, ("%s %s  %s"):format(marker, vault.name, vault.path))
  end
  if #lines == 0 then
    lines = { "no vaults registered — :LoreVaultAdd {name} {path}" }
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end, { desc = "List vaults (* = active)" })

vim.api.nvim_create_user_command("LoreVaultSwitch", function(opts)
  local ok, err = pcall(vaults.switch, opts.args)
  if not ok then
    return notify_error(err)
  end
  session.open_vault(vaults.active())
end, {
  nargs = 1,
  complete = function()
    return vim.tbl_map(function(vault)
      return vault.name
    end, vaults.list())
  end,
  desc = "Switch the active vault",
})
