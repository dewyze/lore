-- Full-stack: real commands, real filesystem, real registry.
require("config.commands")

local preferences = require("lore.preferences")

describe("Lore vault commands", function()
  local prefs_dir, vault_dir

  before_each(function()
    prefs_dir = vim.fn.tempname()
    vault_dir = vim.fn.tempname()
    preferences.set_directory(prefs_dir)
  end)

  after_each(function()
    preferences.reset_directory()
    vim.fn.delete(prefs_dir, "rf")
    vim.fn.delete(vault_dir, "rf")
  end)

  it("LoreVaultAdd registers, scaffolds, and opens the first vault", function()
    vim.cmd(("LoreVaultAdd personal %s"):format(vault_dir))
    assert.equals(vim.uv.fs_realpath(vault_dir), preferences.get("vaults").personal)
    assert.equals(1, vim.fn.filereadable(vault_dir .. "/todo.md"))
    assert.equals("todo.md", vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t"))
  end)

  it("LoreVaultSwitch changes vault and opens its todo.md", function()
    local other = vim.fn.tempname()
    vim.cmd(("LoreVaultAdd personal %s"):format(vault_dir))
    vim.cmd(("LoreVaultAdd work %s"):format(other))
    vim.cmd("LoreVaultSwitch work")
    assert.equals("work", preferences.get("active_vault"))
    assert.equals(preferences.get("vaults").work, vim.fn.getcwd())
    vim.fn.delete(other, "rf")
  end)

  it("LoreVaultSwitch completes registered names", function()
    vim.cmd(("LoreVaultAdd personal %s"):format(vault_dir))
    local completions = vim.fn.getcompletion("LoreVaultSwitch ", "cmdline")
    assert.same({ "personal" }, completions)
  end)

  it("LoreInbox with arguments appends to the active vault's inbox", function()
    vim.cmd(("LoreVaultAdd personal %s"):format(vault_dir))
    vim.cmd("LoreInbox remember the milk")
    assert.same({ "remember the milk" }, vim.fn.readfile(vault_dir .. "/inbox.md"))
  end)

  it("surfaces errors as clean messages, not tracebacks", function()
    -- headless, an error-level notify escalates through vim.cmd; assert the
    -- message is the domain error, stripped of file:line noise
    local ok, err = pcall(vim.cmd, "LoreVaultSwitch nope")
    assert.is_false(ok)
    assert.matches('unknown vault "nope"', err)
    assert.is_nil(err:match("vaults%.lua"))
  end)
end)
