local preferences = require("lore.preferences")
local vaults = require("lore.vaults")
local pages = require("lore.pages")

describe("lore.pages", function()
  local prefs_dir, vault_dir

  before_each(function()
    prefs_dir = vim.fn.tempname()
    vault_dir = vim.fn.tempname()
    preferences.set_directory(prefs_dir)
    vaults.add("personal", vault_dir)
  end)

  after_each(function()
    preferences.reset_directory()
    vim.fn.delete(prefs_dir, "rf")
    vim.fn.delete(vault_dir, "rf")
  end)

  describe("slugify", function()
    local cases = {
      { "Rails Upgrade", "rails_upgrade" },
      { "  spaced  out  ", "spaced_out" },
      { "Already_snake", "already_snake" },
      { "Punct! And? Stuff.", "punct_and_stuff" },
      { "MixedCase-with-dashes", "mixedcase_with_dashes" },
    }
    for _, case in ipairs(cases) do
      it(("%q -> %q"):format(case[1], case[2]), function()
        assert.equals(case[2], pages.slugify(case[1]))
      end)
    end
  end)

  describe("create", function()
    it("creates the page in notes/ by default and returns its path", function()
      local path = pages.create("Rails Upgrade")
      assert.equals(vaults.active().path .. "/notes/rails_upgrade.md", path)
      assert.equals(1, vim.fn.filereadable(path))
    end)

    it("is idempotent for an existing page", function()
      local path = pages.create("Twice")
      vim.fn.writefile({ "content" }, path)
      assert.equals(path, pages.create("Twice"))
      assert.same({ "content" }, vim.fn.readfile(path))
    end)

    it("creates in a named folder, making it if missing", function()
      local path = pages.create("Q3 Roadmap", "projects")
      assert.equals(vaults.active().path .. "/projects/q3_roadmap.md", path)
      assert.equals(1, vim.fn.filereadable(path))
    end)

    it("date-prefixes the slug on request", function()
      local path = pages.create("Team Sync", "meetings", { date_prefix = true })
      assert.equals(
        vaults.active().path .. "/meetings/" .. os.date("%Y_%m_%d") .. "_team_sync.md",
        path
      )
    end)

    it("errors on an empty title", function()
      assert.error_matches(function()
        pages.create("   ")
      end, "empty page title")
    end)
  end)

  describe("create_in_project", function()
    it("files under the project's folder, linked back to the hub", function()
      local hub = pages.create("Rails Upgrade", "projects")
      local path = pages.create_in_project(hub, "Load Testing Notes")
      assert.equals(
        vaults.active().path .. "/projects/rails_upgrade/load_testing_notes.md",
        path
      )
      assert.equals("[Rails Upgrade](/projects/rails_upgrade.md)", vim.fn.readfile(path)[1])
    end)

    it("leaves an existing file's content alone", function()
      local hub = pages.create("Rails Upgrade", "projects")
      local path = pages.create_in_project(hub, "Notes")
      vim.fn.writefile({ "my own words" }, path)
      pages.create_in_project(hub, "Notes")
      assert.same({ "my own words" }, vim.fn.readfile(path))
    end)
  end)

  describe("display_title", function()
    it("prefers frontmatter title", function()
      local path = vault_dir .. "/notes/x.md"
      vim.fn.mkdir(vault_dir .. "/notes", "p")
      vim.fn.writefile({ "---", "title: The Real Name", "---", "body" }, path)
      assert.equals("The Real Name", pages.display_title(path))
    end)

    it("appends the date for meetings", function()
      local path = vault_dir .. "/meetings/m.md"
      vim.fn.mkdir(vault_dir .. "/meetings", "p")
      vim.fn.writefile(
        { "---", "type: meeting", "title: Auth Design Review", "date: 2026-07-08", "---" },
        path
      )
      assert.equals("Auth Design Review · 2026-07-08", pages.display_title(path))
    end)

    it("falls back to the humanized filename", function()
      local path = pages.create("rails upgrade")
      assert.equals("Rails Upgrade", pages.display_title(path))
    end)

    it("flips a filename date prefix into a suffix", function()
      vim.fn.mkdir(vault_dir .. "/meetings", "p")
      local path = vault_dir .. "/meetings/2026_07_16_team_sync.md"
      vim.fn.writefile({}, path)
      assert.equals("Team Sync · 2026-07-16", pages.display_title(path))
    end)
  end)

  describe("link_for", function()
    it("is root-relative to the vault", function()
      local path = pages.create("Some Page")
      assert.equals("/notes/some_page.md", pages.link_for(path))
    end)
  end)

  describe("from_word", function()
    it("replaces the word under the cursor with a link to a new page", function()
      vim.cmd.enew()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "ask infra about it" })
      vim.api.nvim_win_set_cursor(0, { 1, 5 }) -- on "infra"
      pages.from_word()
      assert.equals("ask [infra](/notes/infra.md) about it", vim.api.nvim_get_current_line())
      assert.equals(1, vim.fn.filereadable(vault_dir .. "/notes/infra.md"))
    end)
  end)

  describe("from_selection", function()
    it("replaces the selected text with a link to the new page", function()
      vim.cmd.enew()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "discuss the rails upgrade soon" })
      -- select "rails upgrade" (cols 13-25, 1-based)
      vim.fn.setpos("'<", { 0, 1, 13, 0 })
      vim.fn.setpos("'>", { 0, 1, 25, 0 })
      pages.from_selection()
      assert.equals(
        "discuss the [rails upgrade](/notes/rails_upgrade.md) soon",
        vim.api.nvim_get_current_line()
      )
      assert.equals(1, vim.fn.filereadable(vault_dir .. "/notes/rails_upgrade.md"))
    end)
  end)
end)
