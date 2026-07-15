local preferences = require("lore.preferences")
local vaults = require("lore.vaults")
local due = require("lore.due")

local DAY = 86400

local function date_in(days)
  return os.date("%Y-%m-%d", os.time() + days * DAY)
end

describe("lore.due", function()
  local prefs_dir

  before_each(function()
    prefs_dir = vim.fn.tempname()
    preferences.set_directory(prefs_dir)
  end)

  after_each(function()
    preferences.reset_directory()
    vim.fn.delete(prefs_dir, "rf")
  end)

  describe("group_for", function()
    it("uses the default horizons: plain / warn 7 / urgent 2 / overdue", function()
      assert.is_nil(due.group_for(30))
      assert.is_nil(due.group_for(8))
      assert.equals("LoreDueWarn", due.group_for(7))
      assert.equals("LoreDueWarn", due.group_for(3))
      assert.equals("LoreDueUrgent", due.group_for(2))
      assert.equals("LoreDueUrgent", due.group_for(0))
      assert.equals("LoreDueOverdue", due.group_for(-1))
    end)

    it("reads integer horizons from preferences", function()
      preferences.set("due_warn_days", 14)
      preferences.set("due_urgent_days", 5)
      assert.equals("LoreDueWarn", due.group_for(10))
      assert.equals("LoreDueUrgent", due.group_for(5))
    end)
  end)

  describe("days_until", function()
    it("counts whole days from today", function()
      local today = os.date("*t")
      assert.equals(0, due.days_until(today.year, today.month, today.day))
      local tomorrow = os.date("*t", os.time() + DAY)
      assert.equals(1, due.days_until(tomorrow.year, tomorrow.month, tomorrow.day))
      local yesterday = os.date("*t", os.time() - DAY)
      assert.equals(-1, due.days_until(yesterday.year, yesterday.month, yesterday.day))
    end)
  end)

  describe("refresh", function()
    it("tints tokens by proximity, leaves far dates plain", function()
      vim.cmd.enew()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        ("- [ ] slipped @due(%s)"):format(date_in(-1)),
        ("- [ ] this week @due(%s)"):format(date_in(5)),
        ("- [ ] someday @due(%s)"):format(date_in(30)),
        "- [ ] no date at all",
      })
      due.refresh(0)
      local marks = vim.api.nvim_buf_get_extmarks(0, due.namespace, 0, -1, { details = true })
      assert.equals(2, #marks)
      assert.equals(0, marks[1][2])
      assert.equals("LoreDueOverdue", marks[1][4].hl_group)
      assert.equals(1, marks[2][2])
      assert.equals("LoreDueWarn", marks[2][4].hl_group)
    end)
  end)

  describe("collect", function()
    it("finds every @due in the vault, soonest first", function()
      local vault_dir = vim.fn.tempname()
      vaults.add("personal", vault_dir)
      vim.fn.writefile(
        { ("- [ ] later @due(%s)"):format(date_in(9)) },
        vault_dir .. "/todo.md"
      )
      vim.fn.mkdir(vault_dir .. "/meetings", "p")
      vim.fn.writefile(
        { ("promised the doc by @due(%s)"):format(date_in(1)) },
        vault_dir .. "/meetings/one_on_one.md"
      )
      local found = due.collect()
      assert.equals(2, #found)
      assert.equals(date_in(1), found[1].date)
      assert.matches("one_on_one", found[1].file)
      assert.equals(date_in(9), found[2].date)
      assert.equals(1, found[2].lnum)
      vim.fn.delete(vault_dir, "rf")
    end)
  end)
end)
