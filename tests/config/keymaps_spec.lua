-- The grammar's lore vocabulary, as actually bound (minit loads
-- config.keymaps, so these are the real global maps).
describe("keymaps", function()
  local cases = {
    { "<leader>ff", "Files" },
    { "<leader>ss", "Grep" },
    { "<leader>sw", "GrepWord" },
    { "<leader>fd", "Due" },
    { "<leader>nn", "NewPage notes/" },
    { "<leader>ni", "NewPage ideas/" },
    { "<leader>nc", "NewPage contacts/" },
    { "<leader>nm", "NewMeeting" },
    { "<leader>npp", "NewPage projects/" },
    { "<leader>npf", "NewProjectFile" },
    { "<leader>va", "VaultAdd" },
    { "<leader>cc", "Inbox" },
    { "<leader>ct", "TodoAdd" },
    { "gt", "OpenTodo" },
    { "gi", "OpenInbox" },
    { "<C-S><C-S>", "Tree" },
    { "<C-S><C-L>", "Pane" },
  }

  for _, case in ipairs(cases) do
    it(("%s -> %s"):format(case[1], case[2]), function()
      assert.matches(case[2], vim.fn.maparg(case[1], "n"), 1, true)
    end)
  end

  it("captures work from visual mode with a range", function()
    assert.matches(":Inbox", vim.fn.maparg("<leader>cc", "x"), 1, true)
  end)

  it("tabs step via brackets", function()
    assert.matches("tabnext", vim.fn.maparg("]t", "n"))
  end)

  it("the todo domain binds only inside todo.md", function()
    assert.equals("", vim.fn.maparg("<leader>tt", "n"))
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    vim.cmd.edit(dir .. "/todo.md")
    assert.matches("TodoSort", vim.fn.maparg("<leader>tt", "n"))
    assert.matches("TodoArchive", vim.fn.maparg("<leader>ta", "n"))
    vim.cmd("bwipeout!")
    vim.fn.delete(dir, "rf")
  end)
end)
