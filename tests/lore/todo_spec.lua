local preferences = require("lore.preferences")
local vaults = require("lore.vaults")
local todo = require("lore.todo")

local function buf_with(lines)
  vim.cmd.enew()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

local function lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

describe("lore.todo", function()
  describe("sort", function()
    it("orders by state: [/] [ ] [!] [x]", function()
      buf_with({
        "- [x] shipped",
        "- [ ] pending",
        "- [!] stuck",
        "- [/] active",
      })
      todo.sort()
      assert.same({
        "- [/] active",
        "- [ ] pending",
        "- [!] stuck",
        "- [x] shipped",
      }, lines())
    end)

    it("children travel with their parents", function()
      buf_with({
        "- [x] done parent",
        "  - [ ] child note",
        "  - context line",
        "- [/] active parent",
        "  - [x] done child stays put",
      })
      todo.sort()
      assert.same({
        "- [/] active parent",
        "  - [x] done child stays put",
        "- [x] done parent",
        "  - [ ] child note",
        "  - context line",
      }, lines())
    end)

    it("is stable within a state", function()
      buf_with({
        "- [ ] first",
        "- [x] done",
        "- [ ] second",
        "- [ ] third",
      })
      todo.sort()
      assert.same({
        "- [ ] first",
        "- [ ] second",
        "- [ ] third",
        "- [x] done",
      }, lines())
    end)

    it("sorts each list independently, leaving structure alone", function()
      buf_with({
        "# Work",
        "",
        "- [x] w done",
        "- [ ] w open",
        "",
        "# Later",
        "",
        "- [x] l done",
        "- [/] l active",
      })
      todo.sort()
      assert.same({
        "# Work",
        "",
        "- [ ] w open",
        "- [x] w done",
        "",
        "# Later",
        "",
        "- [/] l active",
        "- [x] l done",
      }, lines())
    end)

    it("treats plain bullets like open todos", function()
      buf_with({
        "- [x] done",
        "- just a note",
        "- [ ] open",
      })
      todo.sort()
      assert.same({
        "- just a note",
        "- [ ] open",
        "- [x] done",
      }, lines())
    end)

    it("does not touch an already-sorted buffer", function()
      buf_with({ "- [/] a", "- [ ] b" })
      vim.bo.modified = false
      assert.is_false(todo.sort())
      assert.is_false(vim.bo.modified)
    end)
  end)

  describe("archive", function()
    local prefs_dir, vault_dir

    before_each(function()
      prefs_dir = vim.fn.tempname()
      vault_dir = vim.fn.tempname()
      preferences.set_directory(prefs_dir)
      vaults.add("personal", vault_dir)
      vim.cmd.edit(vault_dir .. "/todo.md")
    end)

    after_each(function()
      vim.cmd("bwipeout!")
      preferences.reset_directory()
      vim.fn.delete(prefs_dir, "rf")
      vim.fn.delete(vault_dir, "rf")
    end)

    it("moves done subtrees to archive.md stamped with the date", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "- [x] shipped",
        "  - detail",
        "- [ ] keep",
      })
      todo.archive()
      assert.same({ "- [ ] keep" }, lines())
      local archived = vim.fn.readfile(vaults.active().path .. "/archive.md")
      assert.same({
        "## " .. os.date("%Y-%m-%d"),
        "",
        "- [x] shipped",
        "  - detail",
      }, archived)
    end)

    it("keeps done children of unfinished parents", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "- [ ] parent",
        "  - [x] finished step",
      })
      todo.archive()
      assert.same({ "- [ ] parent", "  - [x] finished step" }, lines())
    end)

    it("appends under the same date heading on repeat sweeps", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "- [x] one", "- [x] two" })
      todo.archive()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "- [x] three" })
      todo.archive()
      local archived = vim.fn.readfile(vaults.active().path .. "/archive.md")
      assert.same({
        "## " .. os.date("%Y-%m-%d"),
        "",
        "- [x] one",
        "- [x] two",
        "- [x] three",
      }, archived)
    end)
  end)
end)
