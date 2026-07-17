require("config.commands")

local preferences = require("lore.preferences")

local function hex(v)
  return v and ("#%06x"):format(v) or nil
end

describe("themes", function()
  local prefs_dir

  before_each(function()
    prefs_dir = vim.fn.tempname()
    preferences.set_directory(prefs_dir)
  end)

  after_each(function()
    preferences.reset_directory()
    vim.fn.delete(prefs_dir, "rf")
  end)

  it("wisp applies its palette, washes included", function()
    vim.cmd.colorscheme("wisp")
    assert.equals("wisp", vim.g.colors_name)
    assert.equals("dark", vim.o.background)
    local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
    assert.equals("#303030", hex(normal.bg))
    assert.equals("#ebedec", hex(normal.fg))
    local due = vim.api.nvim_get_hl(0, { name = "LoreDueWarn" })
    assert.equals("#f0c674", hex(due.fg))
    assert.equals("#35423e", hex(due.bg), "warn should sit on the due wash")
    local tag = vim.api.nvim_get_hl(0, { name = "LoreTag" })
    assert.equals("#333d48", hex(tag.bg))
  end)

  it("themes paint the :terminal ANSI palette", function()
    vim.cmd.colorscheme("wisp")
    assert.equals("#8abd7a", vim.g.terminal_color_2, "green from the palette, not neon")
    assert.equals("#cc6666", vim.g.terminal_color_1)
    assert.equals(vim.g.terminal_color_4, vim.g.terminal_color_12, "brights mirror normals")
    vim.cmd.colorscheme("daybreak")
    assert.equals("#2e2e2d", vim.g.terminal_color_0, "light theme keeps ANSI black dark")
  end)

  it("picker directory names get real ink, not the selection gray", function()
    vim.cmd.colorscheme("wisp")
    local dir = vim.api.nvim_get_hl(0, { name = "SnacksPickerDir" })
    assert.equals("#969896", hex(dir.fg))
  end)

  it("overdue is a reverse block", function()
    vim.cmd.colorscheme("wisp")
    local over = vim.api.nvim_get_hl(0, { name = "LoreDueOverdue" })
    assert.equals("#cc6666", hex(over.bg))
    assert.equals("#303030", hex(over.fg))
    assert.is_true(over.bold)
  end)

  it("daybreak is light with paper-tuned washes", function()
    vim.cmd.colorscheme("daybreak")
    assert.equals("light", vim.o.background)
    assert.equals("#35648f", hex(vim.api.nvim_get_hl(0, { name = "@markup.heading" }).fg))
    assert.equals("#eddfc2", hex(vim.api.nvim_get_hl(0, { name = "@markup.raw" }).bg))
  end)

  it("every shipped theme loads", function()
    for _, name in ipairs({ "wisp", "daybreak", "fathom", "ember" }) do
      vim.cmd.colorscheme(name)
      assert.equals(name, vim.g.colors_name)
    end
  end)

  it("Theme switches and persists; unknown names refused", function()
    vim.cmd("Theme ember")
    assert.equals("ember", vim.g.colors_name)
    assert.equals("ember", preferences.get("colorscheme"))
    local ok, err = pcall(vim.cmd, "Theme mauve")
    assert.is_false(ok)
    assert.matches("unknown theme", err)
  end)

  it("Font sets guifont and persists", function()
    vim.cmd("Font Courier Prime:h15")
    assert.equals("Courier Prime:h15", vim.o.guifont)
    assert.equals("Courier Prime:h15", preferences.get("font"))
  end)
end)
