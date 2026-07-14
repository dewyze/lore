local preferences = require("lore.preferences")
local vaults = require("lore.vaults")
local pane = require("lore.pane")

pane.setup()

describe("lore.pane", function()
  local prefs_dir, vault_dir

  before_each(function()
    prefs_dir = vim.fn.tempname()
    vault_dir = vim.fn.tempname()
    preferences.set_directory(prefs_dir)
    vaults.add("personal", vault_dir)
    vim.fn.mkdir(vault_dir .. "/projects", "p")
    vim.fn.writefile({ "# X Project" }, vault_dir .. "/projects/x.md")
    vim.fn.writefile(
      { "- [ ] ship [X Project](/projects/x.md)" },
      vault_dir .. "/todo.md"
    )
    vim.fn.writefile(
      { "mentions [todo](/todo.md) here" },
      vault_dir .. "/inbox.md"
    )
    vim.cmd("silent only")
    vim.cmd.edit(vaults.active().path .. "/todo.md")
  end)

  after_each(function()
    pane.close()
    vim.cmd("silent only")
    vim.cmd("silent %bwipeout!")
    preferences.reset_directory()
    vim.fn.delete(prefs_dir, "rf")
    vim.fn.delete(vault_dir, "rf")
  end)

  local function pane_lines()
    return vim.api.nvim_buf_get_lines(vim.fn.bufnr("lore://pane"), 0, -1, false)
  end

  it("toggle opens a pane without stealing focus, toggles closed", function()
    local before = vim.api.nvim_get_current_win()
    pane.toggle()
    assert.equals(before, vim.api.nvim_get_current_win())
    assert.equals(2, #vim.api.nvim_tabpage_list_wins(0))
    pane.toggle()
    assert.equals(1, #vim.api.nvim_tabpage_list_wins(0))
  end)

  it("shows outgoing links and backlinks for the current buffer", function()
    pane.toggle()
    local lines = table.concat(pane_lines(), "\n")
    assert.matches("Links", lines)
    assert.matches("X Project", lines)
    assert.matches("Backlinks", lines)
    assert.matches("/inbox%.md:1", lines)
  end)

  it("refreshes when entering another buffer", function()
    pane.toggle()
    vim.cmd.edit(vaults.active().path .. "/projects/x.md")
    local lines = table.concat(pane_lines(), "\n")
    assert.matches("/todo%.md:1", lines, "backlink from todo.md should appear")
  end)

  it("opens a backlink at its line in the target window, not the pane", function()
    pane.toggle()
    local target_win = vim.api.nvim_get_current_win()
    local pane_win = vim.fn.win_findbuf(vim.fn.bufnr("lore://pane"))[1]
    vim.api.nvim_set_current_win(pane_win)
    -- find the backlink entry line
    local row
    for i, line in ipairs(pane_lines()) do
      if line:match("/inbox%.md:1") then
        row = i
      end
    end
    vim.api.nvim_win_set_cursor(pane_win, { row, 0 })
    pane.open_entry()
    assert.equals(target_win, vim.api.nvim_get_current_win())
    assert.equals(vaults.active().path .. "/inbox.md", vim.api.nvim_buf_get_name(0))
    assert.equals(1, vim.api.nvim_win_get_cursor(0)[1])
  end)

  it("pane buffer is protected", function()
    pane.toggle()
    local buf = vim.fn.bufnr("lore://pane")
    assert.equals("nofile", vim.bo[buf].buftype)
    assert.is_false(vim.bo[buf].modifiable)
    assert.equals("lore_pane", vim.bo[buf].filetype)
  end)
end)
