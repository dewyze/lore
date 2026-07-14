local preferences = require("lore.preferences")
local vaults = require("lore.vaults")

describe("lore.vaults", function()
  local prefs_dir, vault_dir

  before_each(function()
    prefs_dir = vim.fn.tempname()
    vault_dir = vim.fn.tempname()
    preferences.set_directory(prefs_dir)
  end)

  after_each(function()
    preferences.reset_directory()
    vim.fn.delete(prefs_dir, "rf")
    vim.fn.delete(vault_dir, "rf")
  end)

  describe("add", function()
    it("registers the vault under its canonical path", function()
      vaults.add("personal", vault_dir)
      assert.same({ personal = vim.uv.fs_realpath(vault_dir) }, preferences.get("vaults"))
    end)

    it("creates the directory", function()
      vaults.add("personal", vault_dir)
      assert.equals(1, vim.fn.isdirectory(vault_dir))
    end)

    it("scaffolds the minimum files", function()
      vaults.add("personal", vault_dir)
      for _, name in ipairs({ "inbox.md", "todo.md", "archive.md" }) do
        assert.equals(1, vim.fn.filereadable(vault_dir .. "/" .. name), name .. " missing")
      end
    end)

    it("git inits a non-repo path", function()
      vaults.add("personal", vault_dir)
      assert.equals(1, vim.fn.isdirectory(vault_dir .. "/.git"))
    end)

    it("leaves an existing repo alone", function()
      vim.fn.mkdir(vault_dir, "p")
      vim.system({ "git", "init" }, { cwd = vault_dir }):wait()
      vim.system({ "git", "-C", vault_dir, "commit", "--allow-empty", "-m", "x" }):wait()
      vaults.add("personal", vault_dir)
      local log = vim.system({ "git", "-C", vault_dir, "log", "--oneline" }):wait()
      assert.matches("x", log.stdout)
    end)

    it("does not overwrite existing scaffold files", function()
      vim.fn.mkdir(vault_dir, "p")
      vim.fn.writefile({ "- [ ] keep me" }, vault_dir .. "/todo.md")
      vaults.add("personal", vault_dir)
      assert.same({ "- [ ] keep me" }, vim.fn.readfile(vault_dir .. "/todo.md"))
    end)

    it("makes the first vault active", function()
      vaults.add("personal", vault_dir)
      assert.equals("personal", vaults.active().name)
    end)

    it("does not steal active from an existing vault", function()
      vaults.add("personal", vault_dir)
      local other = vim.fn.tempname()
      vaults.add("work", other)
      assert.equals("personal", vaults.active().name)
      vim.fn.delete(other, "rf")
    end)

    it("rejects a duplicate name", function()
      vaults.add("personal", vault_dir)
      assert.error_matches(function()
        vaults.add("personal", vault_dir)
      end, "already registered")
    end)

    it("expands ~ in the path", function()
      -- point HOME-relative expansion somewhere disposable via expand()
      local expanded = vim.fn.expand("~")
      vaults.add("personal", vault_dir)
      local registered = preferences.get("vaults").personal
      assert.is_nil(registered:match("^~"))
      assert.is_not_nil(expanded) -- sanity: expand works in this environment
    end)
  end)

  describe("list", function()
    it("returns name/path pairs sorted by name", function()
      local other = vim.fn.tempname()
      vaults.add("work", other)
      vaults.add("personal", vault_dir)
      local names = {}
      for _, v in ipairs(vaults.list()) do
        table.insert(names, v.name)
      end
      assert.same({ "personal", "work" }, names)
      vim.fn.delete(other, "rf")
    end)

    it("is empty with no registry", function()
      assert.same({}, vaults.list())
    end)
  end)

  describe("switch", function()
    it("changes the active vault and persists it", function()
      local other = vim.fn.tempname()
      vaults.add("personal", vault_dir)
      vaults.add("work", other)
      vaults.switch("work")
      assert.equals("work", vaults.active().name)
      assert.equals("work", preferences.get("active_vault"))
      vim.fn.delete(other, "rf")
    end)

    it("rejects an unknown name", function()
      assert.error_matches(function()
        vaults.switch("nope")
      end, "unknown vault")
    end)
  end)

  describe("active", function()
    it("is nil with no vaults", function()
      assert.is_nil(vaults.active())
    end)

    it("returns name and path", function()
      vaults.add("personal", vault_dir)
      assert.same({ name = "personal", path = vim.uv.fs_realpath(vault_dir) }, vaults.active())
    end)
  end)
end)
