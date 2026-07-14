local lists = require("lore.lists")

local function buf_with(lines)
  vim.cmd.enew()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

local function lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

describe("lore.lists.renumber", function()
  it("renumbers after a mid-list insert", function()
    buf_with({ "1. one", "1. new", "2. two" })
    lists.renumber()
    assert.same({ "1. one", "2. new", "3. two" }, lines())
  end)

  it("renumbers after a delete", function()
    buf_with({ "1. one", "3. three", "4. four" })
    lists.renumber()
    assert.same({ "1. one", "2. three", "3. four" }, lines())
  end)

  it("anchors on the first item's number", function()
    buf_with({ "5. five", "9. six" })
    lists.renumber()
    assert.same({ "5. five", "6. six" }, lines())
  end)

  it("preserves the separator style", function()
    buf_with({ "1) a", "5) b" })
    lists.renumber()
    assert.same({ "1) a", "2) b" }, lines())
  end)

  it("renumbers nested ordered lists independently", function()
    buf_with({
      "1. outer one",
      "   1. inner one",
      "   3. inner two",
      "3. outer two",
    })
    lists.renumber()
    assert.same({
      "1. outer one",
      "   1. inner one",
      "   2. inner two",
      "2. outer two",
    }, lines())
  end)

  it("leaves bullet lists and prose alone", function()
    buf_with({ "- a", "- b", "", "prose 1. not a list" })
    lists.renumber()
    assert.same({ "- a", "- b", "", "prose 1. not a list" }, lines())
  end)

  it("keeps checkboxes intact", function()
    buf_with({ "1. [x] done", "1. [ ] open" })
    lists.renumber()
    assert.same({ "1. [x] done", "2. [ ] open" }, lines())
  end)

  it("reports whether anything changed", function()
    buf_with({ "1. a", "2. b" })
    assert.is_false(lists.renumber())
    buf_with({ "1. a", "7. b" })
    assert.is_true(lists.renumber())
  end)
end)
