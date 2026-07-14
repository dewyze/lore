local preferences = require("lore.preferences")
local vaults = require("lore.vaults")
local pages = require("lore.pages")

describe("lore.pages", function()
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

  describe("slugify", function()
    local cases = {
      { "Rails Upgrade", "rails_upgrade" },
      { "  spaced  out  ", "spaced_out" },
      { "Already_snake", "already_snake" },
      { "Punct! And? Stuff.", "punct_and_stuff" },
      { "MixedCase-with-dashes", "mixedcase_with_dashes" },
    }
    for _, case in ipairs(cases) do
      it(("%q -> %q"):format(case[1], case[2]), function()
        assert.equals(case[2], pages.slugify(case[1]))
      end)
    end
  end)

  describe("create", function()
    it("creates the page in unsorted/ and returns its path", function()
      local path = pages.create("Rails Upgrade")
      assert.equals(vaults.active().path .. "/unsorted/rails_upgrade.md", path)
      assert.equals(1, vim.fn.filereadable(path))
    end)

    it("is idempotent for an existing page", function()
      local path = pages.create("Twice")
      vim.fn.writefile({ "content" }, path)
      assert.equals(path, pages.create("Twice"))
      assert.same({ "content" }, vim.fn.readfile(path))
    end)

    it("errors on an empty title", function()
      assert.error_matches(function()
        pages.create("   ")
      end, "empty page title")
    end)
  end)

  describe("link_for", function()
    it("is root-relative to the vault", function()
      local path = pages.create("Some Page")
      assert.equals("/unsorted/some_page.md", pages.link_for(path))
    end)
  end)

  describe("from_selection", function()
    it("replaces the selected text with a link to the new page", function()
      vim.cmd.enew()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "discuss the rails upgrade soon" })
      -- select "rails upgrade" (cols 13-25, 1-based)
      vim.fn.setpos("'<", { 0, 1, 13, 0 })
      vim.fn.setpos("'>", { 0, 1, 25, 0 })
      pages.from_selection()
      assert.equals(
        "discuss the [rails upgrade](/unsorted/rails_upgrade.md) soon",
        vim.api.nvim_get_current_line()
      )
      assert.equals(1, vim.fn.filereadable(vault_dir .. "/unsorted/rails_upgrade.md"))
    end)
  end)
end)
