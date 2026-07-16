-- The grammar's lore vocabulary, as actually bound (minit loads
-- config.keymaps, so these are the real global maps).
describe("keymaps", function()
  local cases = {
    { "<leader>ff", "LoreFiles" },
    { "<leader>ss", "LoreGrep" },
    { "<leader>sw", "LoreGrepWord" },
    { "<leader>fd", "LoreDue" },
    { "<leader>nn", "LoreNewPage notes/" },
    { "<leader>ni", "LoreNewPage ideas/" },
    { "<leader>nc", "LoreNewPage contacts/" },
    { "<leader>nm", "LoreNewMeeting" },
    { "<leader>npp", "LoreNewPage projects/" },
    { "<leader>npf", "LoreNewProjectFile" },
    { "<leader>va", "LoreVaultAdd" },
    { "<leader>cc", "LoreInbox" },
    { "<leader>ct", "LoreTodoAdd" },
    { "gt", "LoreOpenTodo" },
    { "gi", "LoreOpenInbox" },
    { "<C-S><C-S>", "LoreTree" },
    { "<C-S><C-L>", "LorePane" },
  }

  for _, case in ipairs(cases) do
    it(("%s -> %s"):format(case[1], case[2]), function()
      assert.matches(case[2], vim.fn.maparg(case[1], "n"), 1, true)
    end)
  end

  it("captures work from visual mode with a range", function()
    assert.matches(":LoreInbox", vim.fn.maparg("<leader>cc", "x"), 1, true)
  end)

  it("tabs step via brackets", function()
    assert.matches("tabnext", vim.fn.maparg("]t", "n"))
  end)

  it("the todo domain binds only inside todo.md", function()
    assert.equals("", vim.fn.maparg("<leader>tt", "n"))
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    vim.cmd.edit(dir .. "/todo.md")
    assert.matches("LoreTodoSort", vim.fn.maparg("<leader>tt", "n"))
    assert.matches("LoreTodoArchive", vim.fn.maparg("<leader>ta", "n"))
    vim.cmd("bwipeout!")
    vim.fn.delete(dir, "rf")
  end)
end)
