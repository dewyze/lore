local preferences = require("lore.preferences")
local vaults = require("lore.vaults")
local inbox = require("lore.inbox")

describe("lore.inbox", function()
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

  it("appends a line to the active vault's inbox", function()
    vaults.add("personal", vault_dir)
    inbox.append("call the dentist")
    inbox.append("read that paper")
    assert.same(
      { "call the dentist", "read that paper" },
      vim.fn.readfile(vault_dir .. "/inbox.md")
    )
  end)

  it("errors without an active vault", function()
    assert.error_matches(function()
      inbox.append("orphan thought")
    end, "no active vault")
  end)

  it("ignores blank input", function()
    vaults.add("personal", vault_dir)
    inbox.append("  ")
    assert.same({}, vim.fn.readfile(vault_dir .. "/inbox.md"))
  end)
end)
