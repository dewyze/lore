local preferences = require("lore.preferences")

describe("lore.preferences", function()
  local dir

  before_each(function()
    dir = vim.fn.tempname()
    preferences.set_directory(dir)
  end)

  after_each(function()
    preferences.reset_directory()
    vim.fn.delete(dir, "rf")
  end)

  it("returns nil for an unset key", function()
    assert.is_nil(preferences.get("nope"))
  end)

  it("round-trips a value", function()
    preferences.set("active_vault", "personal")
    assert.equals("personal", preferences.get("active_vault"))
  end)

  it("round-trips a table", function()
    preferences.set("vaults", { personal = "/tmp/p", work = "/tmp/w" })
    assert.same({ personal = "/tmp/p", work = "/tmp/w" }, preferences.get("vaults"))
  end)

  it("persists to disk, not just cache", function()
    preferences.set("active_vault", "work")
    preferences.set_directory(dir) -- drops the cache, forces a re-read
    assert.equals("work", preferences.get("active_vault"))
  end)

  it("deletes a key when set to nil", function()
    preferences.set("gone", "soon")
    preferences.set("gone", nil)
    preferences.set_directory(dir)
    assert.is_nil(preferences.get("gone"))
  end)

  it("treats a corrupt file as empty", function()
    vim.fn.mkdir(dir, "p")
    vim.fn.writefile({ "not json {" }, dir .. "/preferences.json")
    assert.is_nil(preferences.get("anything"))
  end)

  it("creates the directory on first write", function()
    preferences.set("k", "v")
    assert.equals(1, vim.fn.filereadable(dir .. "/preferences.json"))
  end)
end)
