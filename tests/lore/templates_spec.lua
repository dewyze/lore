local preferences = require("lore.preferences")
local vaults = require("lore.vaults")
local templates = require("lore.templates")

describe("lore.templates", function()
  local prefs_dir, vault_dir

  before_each(function()
    prefs_dir = vim.fn.tempname()
    vault_dir = vim.fn.tempname()
    preferences.set_directory(prefs_dir)
    vaults.add("personal", vault_dir)
    vim.fn.mkdir(vault_dir .. "/templates", "p")
  end)

  after_each(function()
    preferences.reset_directory()
    vim.fn.delete(prefs_dir, "rf")
    vim.fn.delete(vault_dir, "rf")
  end)

  describe("list", function()
    it("returns template paths sorted by name", function()
      vim.fn.writefile({}, vault_dir .. "/templates/meeting.md")
      vim.fn.writefile({}, vault_dir .. "/templates/idea.md")
      local names = vim.tbl_map(function(path)
        return vim.fn.fnamemodify(path, ":t")
      end, templates.list())
      assert.same({ "idea.md", "meeting.md" }, names)
    end)

    it("is empty when the vault has no templates dir", function()
      vim.fn.delete(vault_dir .. "/templates", "rf")
      assert.same({}, templates.list())
    end)
  end)

  describe("apply", function()
    it("inserts the template into an empty buffer with substitutions", function()
      vim.fn.writefile(
        { "---", "date: {{date}}", "---", "# {{title}}" },
        vault_dir .. "/templates/note.md"
      )
      vim.cmd.edit(vault_dir .. "/unsorted/rails_upgrade.md")
      templates.apply(vault_dir .. "/templates/note.md")
      assert.same({
        "---",
        "date: " .. os.date("%Y-%m-%d"),
        "---",
        "# Rails Upgrade",
      }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
      vim.cmd("bwipeout!")
    end)

    it("inserts at the cursor in a non-empty buffer", function()
      vim.fn.writefile({ "## Notes", "" }, vault_dir .. "/templates/section.md")
      vim.cmd.edit(vault_dir .. "/unsorted/existing.md")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "first", "last" })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      templates.apply(vault_dir .. "/templates/section.md")
      assert.same(
        { "first", "## Notes", "", "last" },
        vim.api.nvim_buf_get_lines(0, 0, -1, false)
      )
      vim.cmd("bwipeout!")
    end)
  end)
end)
