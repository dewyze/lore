local preferences = require("lore.preferences")
local vaults = require("lore.vaults")
local age = require("lore.age")

local DAY = 86400

describe("lore.age", function()
  describe("badge", function()
    it("is nil under two days", function()
      assert.is_nil(age.badge(0))
      assert.is_nil(age.badge(1 * DAY))
    end)

    it("shows days, then weeks, then months, with escalating groups", function()
      local text, group = age.badge(3 * DAY)
      assert.equals("· 3d", text)
      assert.equals("LoreAgeFresh", group)

      text, group = age.badge(15 * DAY)
      assert.equals("· 2w", text)
      assert.equals("LoreAgeAging", group)

      text, group = age.badge(70 * DAY)
      assert.equals("· 2mo", text)
      assert.equals("LoreAgeStale", group)
    end)
  end)

  describe("against a real repo", function()
    local prefs_dir, vault_dir

    local function commit(when)
      local stamp = os.date("%Y-%m-%dT%H:%M:%S", os.time() - when)
      vim.system({ "git", "add", "-A" }, { cwd = vault_dir }):wait()
      vim.system({ "git", "commit", "-m", "x", "--allow-empty" }, {
        cwd = vault_dir,
        env = { GIT_AUTHOR_DATE = stamp, GIT_COMMITTER_DATE = stamp },
      }):wait()
    end

    before_each(function()
      prefs_dir = vim.fn.tempname()
      vault_dir = vim.fn.tempname()
      preferences.set_directory(prefs_dir)
      vaults.add("personal", vault_dir)
      vim.fn.writefile({ "- [ ] old and hanging" }, vault_dir .. "/todo.md")
      commit(20 * DAY)
      vim.fn.writefile(
        { "- [ ] old and hanging", "- [ ] fresh today" },
        vault_dir .. "/todo.md"
      )
      commit(0)
    end)

    after_each(function()
      vim.cmd("silent %bwipeout!")
      preferences.reset_directory()
      vim.fn.delete(prefs_dir, "rf")
      vim.fn.delete(vault_dir, "rf")
    end)

    it("ages lines from blame committer times", function()
      local ages = age.ages(vaults.active().path .. "/todo.md")
      assert.is_true(ages[1] > 19 * DAY, "line 1 should be ~20 days old")
      assert.is_true(ages[2] < 1 * DAY, "line 2 should be fresh")
    end)

    it("renders badges on stale items only", function()
      vim.cmd.edit(vaults.active().path .. "/todo.md")
      age.refresh(0)
      local marks = vim.api.nvim_buf_get_extmarks(0, age.namespace, 0, -1, { details = true })
      assert.equals(1, #marks)
      assert.equals(0, marks[1][2]) -- row 0 = the 20-day line
      assert.matches("2w", marks[1][4].virt_text[1][1])
    end)
  end)
end)
