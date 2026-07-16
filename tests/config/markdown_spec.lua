-- The markdown editing feel: after/ftplugin options, list mappings,
-- checkbox highlighting. Exercised on a real markdown buffer.
require("lore.checkbox").setup()

describe("markdown ftplugin", function()
  local file

  before_each(function()
    file = vim.fn.tempname() .. ".md"
    vim.cmd.edit(file)
  end)

  after_each(function()
    vim.cmd("bwipeout!")
  end)

  it("sets the editing options", function()
    assert.equals(2, vim.bo.shiftwidth)
    assert.is_true(vim.bo.expandtab)
    assert.equals(2, vim.wo.conceallevel)
    assert.equals("expr", vim.wo.foldmethod)
    assert.equals(99, vim.wo.foldlevel)
  end)

  it("maps the list-continuation keys buffer-locally", function()
    for _, map in ipairs({ { "<CR>", "i" }, { "o", "n" }, { "O", "n" }, { "<Tab>", "i" }, { "<S-Tab>", "i" } }) do
      local info = vim.fn.maparg(map[1], map[2], false, true)
      assert.equals(1, info.buffer, map[1] .. " not buffer-mapped")
    end
  end)

  it("applies the checkbox state matches to the window", function()
    local groups = vim.tbl_map(function(match)
      return match.group
    end, vim.fn.getmatches())
    for _, group in ipairs({ "LoreCheckboxInProgress", "LoreCheckboxBlocked" }) do
      assert.is_true(vim.tbl_contains(groups, group), group .. " missing")
    end
  end)

  it("cycles a checkbox through the command", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "- [ ] task" })
    vim.cmd.CheckboxCycle()
    assert.equals("- [/] task", vim.api.nvim_get_current_line())
  end)

  it("sets an asserted state through the command", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "- [/] task" })
    vim.cmd("CheckboxSet blocked")
    assert.equals("- [!] task", vim.api.nvim_get_current_line())
  end)
end)
