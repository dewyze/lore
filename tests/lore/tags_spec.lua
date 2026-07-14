local tags = require("lore.tags")

describe("lore.tags", function()
  local dir

  local function write(name, lines)
    vim.fn.writefile(lines, dir .. "/" .. name)
  end

  before_each(function()
    dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
  end)

  after_each(function()
    vim.fn.delete(dir, "rf")
  end)

  it("collects inline #tags", function()
    write("a.md", { "working on #rails upgrade with #infra" })
    assert.same({ "infra", "rails" }, tags.collect(dir))
  end)

  it("collects frontmatter inline-array tags", function()
    write("a.md", { "---", "tags: [ideas, writing]", "---", "body" })
    assert.same({ "ideas", "writing" }, tags.collect(dir))
  end)

  it("collects frontmatter scalar tags", function()
    write("a.md", { "---", "tags: solo", "---" })
    assert.same({ "solo" }, tags.collect(dir))
  end)

  it("dedupes across files and sources", function()
    write("a.md", { "#rails here" })
    write("b.md", { "---", "tags: [rails]", "---" })
    assert.same({ "rails" }, tags.collect(dir))
  end)

  it("ignores markdown headings", function()
    write("a.md", { "# Heading", "## Another", "#real-tag" })
    assert.same({ "real-tag" }, tags.collect(dir))
  end)

  it("supports nested tag paths", function()
    write("a.md", { "#team/infra stuff" })
    assert.same({ "team/infra" }, tags.collect(dir))
  end)

  it("returns empty for a tagless vault", function()
    write("a.md", { "nothing here" })
    assert.same({}, tags.collect(dir))
  end)
end)
