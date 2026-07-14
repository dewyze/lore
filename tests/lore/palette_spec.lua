local palette = require("lore.palette")

describe("lore.palette", function()
  it("lists only commands that exist, with display names", function()
    local items = palette.items()
    assert.is_true(#items > 10)
    for _, item in ipairs(items) do
      assert.is_string(item.text)
      assert.matches(" > ", item.text)
      -- every entry must be runnable
      local name = item.cmd:match("^(%S+)")
      assert.equals(2, vim.fn.exists(":" .. name), item.cmd .. " is not a command")
    end
  end)

  it("shows the bound key as a hint where one exists", function()
    local by_cmd = {}
    for _, item in ipairs(palette.items()) do
      by_cmd[item.cmd] = item
    end
    assert.is_not_nil(by_cmd.LoreFiles.keymap, "LoreFiles should carry its keymap hint")
  end)

  it("includes argument-carrying entries for asserted checkbox states", function()
    local texts = vim.tbl_map(function(item)
      return item.cmd
    end, palette.items())
    assert.is_true(vim.tbl_contains(texts, "LoreCheckboxSet blocked"))
    assert.is_true(vim.tbl_contains(texts, "LoreCheckboxSet dropped"))
  end)
end)
