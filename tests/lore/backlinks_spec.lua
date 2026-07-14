local preferences = require("lore.preferences")
local vaults = require("lore.vaults")
local backlinks = require("lore.backlinks")
local links = require("lore.links")

describe("link data", function()
  local prefs_dir, vault_dir

  before_each(function()
    prefs_dir = vim.fn.tempname()
    vault_dir = vim.fn.tempname()
    preferences.set_directory(prefs_dir)
    vaults.add("personal", vault_dir)
  end)

  after_each(function()
    preferences.reset_directory()
    vim.fn.delete(prefs_dir, "rf")
    vim.fn.delete(vault_dir, "rf")
  end)

  describe("links.outgoing", function()
    it("lists markdown links in the buffer, urls excluded", function()
      vim.cmd.enew()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "see [Rails Upgrade](/projects/rails_upgrade.md) and",
        "[the docs](https://example.com) plus [notes](notes.md)",
      })
      assert.same({
        { title = "Rails Upgrade", target = "/projects/rails_upgrade.md", lnum = 1 },
        { title = "notes", target = "notes.md", lnum = 2 },
      }, links.outgoing(0))
    end)

    it("is empty for a linkless buffer", function()
      vim.cmd.enew()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "plain text" })
      assert.same({}, links.outgoing(0))
    end)
  end)

  describe("backlinks.find", function()
    it("finds lines linking to the given file, root-relative", function()
      vim.fn.mkdir(vault_dir .. "/projects", "p")
      vim.fn.writefile({ "target content" }, vault_dir .. "/projects/x.md")
      vim.fn.writefile(
        { "- [ ] ship [X Project](/projects/x.md)" },
        vault_dir .. "/todo.md"
      )
      vim.fn.writefile(
        { "unrelated", "mentions [x](/projects/x.md) inline" },
        vault_dir .. "/inbox.md"
      )
      local found = backlinks.find(vault_dir .. "/projects/x.md")
      table.sort(found, function(a, b)
        return a.file < b.file
      end)
      assert.equals(2, #found)
      assert.equals(vaults.active().path .. "/inbox.md", found[1].file)
      assert.equals(2, found[1].lnum)
      assert.equals(vaults.active().path .. "/todo.md", found[2].file)
      assert.equals(1, found[2].lnum)
      assert.matches("ship", found[2].text)
    end)

    it("is empty when nothing links here", function()
      vim.fn.writefile({}, vault_dir .. "/lonely.md")
      assert.same({}, backlinks.find(vault_dir .. "/lonely.md"))
    end)
  end)
end)
