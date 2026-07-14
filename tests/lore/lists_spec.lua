local lists = require("lore.lists")

local function buf_with(lines, cursor)
  vim.cmd.enew()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, cursor or { 1, 0 })
end

local function lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

describe("lore.lists", function()
  describe("next_marker", function()
    local cases = {
      { "- [x] done", "- [ ] " },
      { "- [/] doing", "- [ ] " },
      { "- [!] stuck", "- [ ] " },
      { "- [ ] fresh", "- [ ] " },
      { "- plain item", "- " },
      { "* star item", "* " },
      { "+ plus item", "+ " },
      { "  - [ ] indented", "  - [ ] " },
      { "2. second", "3. " },
      { "2) paren", "3) " },
      { "10. [x] tenth", "11. [ ] " },
    }
    for _, case in ipairs(cases) do
      it(("%q -> %q"):format(case[1], case[2]), function()
        assert.equals(case[2], lists.next_marker(case[1]))
      end)
    end

    it("is nil for prose", function()
      assert.is_nil(lists.next_marker("no list here"))
    end)

    it("is nil without a space after the bullet", function()
      assert.is_nil(lists.next_marker("-not a list"))
    end)
  end)

  describe("press_enter", function()
    -- press_enter reads the 0-based cursor col as the insertion point.
    -- Simulate an insert-mode end-of-line cursor with virtualedit=onemore
    -- (entering insert via feedkeys hangs headless test children).
    before_each(function()
      vim.opt.virtualedit = "onemore"
    end)

    after_each(function()
      vim.opt.virtualedit = ""
    end)

    local function cursor_at_eol()
      local line = vim.api.nvim_get_current_line()
      vim.api.nvim_win_set_cursor(0, { 1, #line })
    end

    it("continues a checkbox item with a fresh todo", function()
      buf_with({ "- [x] shipped" })
      cursor_at_eol()
      lists.press_enter()
      assert.same({ "- [x] shipped", "- [ ] " }, lines())
      assert.same({ 2, 6 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("continues a plain bullet", function()
      buf_with({ "- thought" })
      cursor_at_eol()
      lists.press_enter()
      assert.same({ "- thought", "- " }, lines())
    end)

    it("increments an ordered item", function()
      buf_with({ "1. first" })
      cursor_at_eol()
      lists.press_enter()
      assert.same({ "1. first", "2. " }, lines())
    end)

    it("carries text after the cursor onto the new item", function()
      buf_with({ "- [ ] hello world" })
      vim.api.nvim_win_set_cursor(0, { 1, #"- [ ] hello" })
      lists.press_enter()
      assert.same({ "- [ ] hello", "- [ ]  world" }, lines())
    end)

    it("clears the marker on an empty item instead of continuing", function()
      buf_with({ "- [ ] " })
      cursor_at_eol()
      lists.press_enter()
      assert.same({ "" }, lines())
    end)
  end)

  describe("open_below", function()
    it("opens a fresh todo under a checkbox item", function()
      buf_with({ "- [/] busy", "unrelated" })
      lists.open_below()
      assert.same({ "- [/] busy", "- [ ] ", "unrelated" }, lines())
      assert.same({ 2, 6 }, vim.api.nvim_win_get_cursor(0))
    end)
  end)

  describe("open_above", function()
    it("opens a fresh todo above a checkbox item", function()
      buf_with({ "- [x] later" })
      lists.open_above()
      assert.same({ "- [ ] ", "- [x] later" }, lines())
      assert.same({ 1, 6 }, vim.api.nvim_win_get_cursor(0))
    end)
  end)
end)
