-- User commands are the app's real interface; keymaps only dispatch here.
local checkbox = require("lore.checkbox")
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

vim.api.nvim_create_user_command("LoreCheckboxCycle", function()
  checkbox.cycle()
end, { desc = "Cycle checkbox: [ ] -> [/] -> [x] -> [ ]" })

local CHECKBOX_STATES = { todo = " ", in_progress = "/", done = "x", blocked = "!", dropped = "-" }

vim.api.nvim_create_user_command("LoreCheckboxSet", function(opts)
  local state = CHECKBOX_STATES[opts.args]
  if not state then
    return notify_error(("unknown checkbox state %q"):format(opts.args))
  end
  checkbox.set(state)
end, {
  nargs = 1,
  complete = function()
    return vim.tbl_keys(CHECKBOX_STATES)
  end,
  desc = "Set checkbox state explicitly",
})

vim.api.nvim_create_user_command("LoreVaultSwitch", function(opts)
  if opts.args == "" then
    return require("lore.pickers").vaults()
  end
  local ok, err = pcall(vaults.switch, opts.args)
  if not ok then
    return notify_error(err)
  end
  session.open_vault(vaults.active())
end, {
  nargs = "?",
  complete = function()
    return vim.tbl_map(function(vault)
      return vault.name
    end, vaults.list())
  end,
  desc = "Switch the active vault (picker with no argument)",
})

vim.api.nvim_create_user_command("LoreFiles", function()
  require("lore.pickers").files()
end, { desc = "Find file in the active vault" })

vim.api.nvim_create_user_command("LoreGrep", function()
  require("lore.pickers").grep()
end, { desc = "Live grep the active vault" })

vim.api.nvim_create_user_command("LoreTags", function()
  require("lore.pickers").tags()
end, { desc = "Search tags in the active vault" })

vim.api.nvim_create_user_command("LoreInbox", function(opts)
  local function capture(text)
    local ok, err = pcall(require("lore.inbox").append, text)
    if not ok then
      notify_error(err)
    end
  end
  if opts.args ~= "" then
    return capture(opts.args)
  end
  vim.ui.input({ prompt = "inbox" }, function(text)
    if text then
      capture(text)
    end
  end)
end, { nargs = "*", desc = "Append a line to the active vault's inbox" })
