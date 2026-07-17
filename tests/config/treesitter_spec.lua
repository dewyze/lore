local treesitter = require("config.treesitter")

describe("shortcut-link conceal strip", function()
  it("removes exactly the shortcut conceal rule from the live runtime query", function()
    local chunks = {}
    for _, file in ipairs(vim.treesitter.query.get_files("markdown_inline", "highlights")) do
      chunks[#chunks + 1] = table.concat(vim.fn.readfile(file), "\n")
    end
    local text = table.concat(chunks, "\n")
    local stripped = treesitter.strip_shortcut_conceal(text)
    assert.is_not_nil(stripped, "rule not found — nvim upgrade reshaped the query?")
    assert.is_nil(stripped:match("Conceal shortcut links"))
    -- other conceals survive
    assert.matches("Conceal full reference links", stripped)
    -- and the result still parses as a query
    assert.has_no_error(function()
      vim.treesitter.query.parse("markdown_inline", stripped)
    end)
  end)

  it("returns nil on unrecognized text", function()
    assert.is_nil(treesitter.strip_shortcut_conceal("(something) @else"))
  end)
end)
