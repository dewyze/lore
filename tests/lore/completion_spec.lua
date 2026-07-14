local preferences = require("lore.preferences")
local vaults = require("lore.vaults")
local completion = require("lore.completion")

describe("lore.completion", function()
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

  describe("pages", function()
    it("lists vault pages as completion items", function()
      vim.fn.mkdir(vault_dir .. "/projects", "p")
      vim.fn.writefile({}, vault_dir .. "/projects/rails_upgrade.md")
      local items = completion.pages()
      local by_word = {}
      for _, item in ipairs(items) do
        by_word[item.word] = item
      end
      local item = by_word["rails_upgrade"]
      assert.is_not_nil(item)
      assert.equals("/projects/rails_upgrade.md", item.user_data.lore.path)
      assert.equals("Rails Upgrade", item.user_data.lore.title)
      -- scaffold files are pages too
      assert.is_not_nil(by_word["todo"])
    end)

    it("is empty without an active vault", function()
      preferences.set("active_vault", nil)
      assert.same({}, completion.pages())
    end)
  end)

  describe("finish", function()
    it("rewrites [[word into a full markdown link", function()
      vim.cmd.enew()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "see [[rails_upgrade and more" })
      -- cursor just past the completed word ("see [[rails_upgrade" = 19 bytes)
      vim.api.nvim_win_set_cursor(0, { 1, 19 })
      completion.finish(4, { path = "/projects/rails_upgrade.md", title = "Rails Upgrade" })
      assert.equals(
        "see [Rails Upgrade](/projects/rails_upgrade.md) and more",
        vim.api.nvim_get_current_line()
      )
    end)
  end)
end)
