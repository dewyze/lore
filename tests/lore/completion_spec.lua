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

    -- Meetings are date-prefixed and unbounded: dozens of
    -- 2026_07_28_team_sync stems would bury the pages worth linking to.
    -- They stay reachable by gf and the pickers, just not mid-sentence.
    it("leaves meetings out", function()
      vim.fn.mkdir(vault_dir .. "/meetings", "p")
      vim.fn.mkdir(vault_dir .. "/notes", "p")
      vim.fn.writefile({}, vault_dir .. "/meetings/2026_07_28_team_sync.md")
      vim.fn.writefile({}, vault_dir .. "/notes/kept.md")
      local words = vim.tbl_map(function(item)
        return item.word
      end, completion.pages())
      assert.is_false(vim.tbl_contains(words, "2026_07_28_team_sync"), "meeting offered")
      assert.is_true(vim.tbl_contains(words, "kept"), "note missing")
    end)

    it("leaves a meetings folder nested under a project out too", function()
      vim.fn.mkdir(vault_dir .. "/projects/rails_upgrade/meetings", "p")
      vim.fn.writefile({}, vault_dir .. "/projects/rails_upgrade/meetings/2026_07_28_kickoff.md")
      local words = vim.tbl_map(function(item)
        return item.word
      end, completion.pages())
      assert.is_false(vim.tbl_contains(words, "2026_07_28_kickoff"), "nested meeting offered")
    end)
  end)

  describe("link_start", function()
    it("finds the [[ that opens an unfinished link", function()
      assert.equals(4, completion.link_start("see [[rail", 10))
    end)

    it("finds it with no leader typed yet", function()
      assert.equals(4, completion.link_start("see [[", 6))
    end)

    it("is nil with no [[ before the cursor", function()
      assert.is_nil(completion.link_start("see rail", 8))
    end)

    it("is nil once the link is closed", function()
      assert.is_nil(completion.link_start("see [[rails]]", 13))
    end)

    it("takes the nearest [[ when the line holds an earlier link", function()
      assert.equals(10, completion.link_start("a [[x]] b [[ra", 14))
    end)

    it("ignores a [[ after the cursor", function()
      assert.is_nil(completion.link_start("see  [[rail", 4))
    end)
  end)

  describe("completefunc", function()
    local function buffer_with(line, col)
      vim.cmd.enew()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { line })
      vim.api.nvim_win_set_cursor(0, { 1, col })
    end

    it("starts the leader just past the [[", function()
      buffer_with("see [[rail", 10)
      assert.equals(6, completion.completefunc(1, ""))
    end)

    it("leaves completion mode when the cursor is not in a link", function()
      buffer_with("see rail", 8)
      assert.equals(-3, completion.completefunc(1, ""))
    end)

    it("answers the second invocation with the vault's pages", function()
      vim.fn.mkdir(vault_dir .. "/projects", "p")
      vim.fn.writefile({}, vault_dir .. "/projects/rails_upgrade.md")
      buffer_with("see [[rail", 10)
      completion.completefunc(1, "")
      local words = vim.tbl_map(function(item)
        return item.word
      end, completion.completefunc(0, "rail"))
      assert.is_true(vim.tbl_contains(words, "rails_upgrade"))
    end)

    -- nvim re-invokes completefunc as the leader shrinks, so a typo'd
    -- leader that matches nothing must still answer with the full list —
    -- that is what lets backspace bring the popup back.
    it("answers every re-invocation, matching leader or not", function()
      buffer_with("see [[raisl", 11)
      completion.completefunc(1, "")
      assert.is_true(#completion.completefunc(0, "raisl") > 0)
      buffer_with("see [[rais", 10)
      assert.equals(6, completion.completefunc(1, ""))
      assert.is_true(#completion.completefunc(0, "rais") > 0)
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
