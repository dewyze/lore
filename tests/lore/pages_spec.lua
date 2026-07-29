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

  describe("create_contact", function()
    it("seeds a person page with the address as its resource", function()
      local path, seeded = pages.create_contact("Dana Bell", "dana.b@example.com")
      -- not compared to vault_dir directly: macOS resolves /var to /private/var
      assert.matches("/contacts/dana_bell%.md$", path)
      assert.is_true(seeded)
      assert.same({
        "---",
        "type: Person",
        "resource: mailto:dana.b@example.com",
        "---",
        "",
        "# Dana Bell",
        "",
      }, vim.fn.readfile(path))
    end)

    it("never rewrites a page that already has content", function()
      local path = pages.create("Dana Bell", "contacts")
      vim.fn.writefile({ "---", "type: Person", "---", "", "hand-written notes" }, path)
      local _, seeded = pages.create_contact("Dana Bell", "second@example.com")
      assert.is_false(seeded, "an existing contact must not be clobbered")
      assert.equals("hand-written notes", vim.fn.readfile(path)[5])
    end)
  end)

  describe("contact_from_selection", function()
    -- vim.ui.input and vim.notify are stubbed because they *are* the human —
    -- the same boundary as stdin and stdout, not lore standing in for itself.
    -- Capturing notify also keeps a passing run silent.
    local function with_input(answer, fn)
      local original_input, original_notify = vim.ui.input, vim.notify
      local notified = {}
      vim.ui.input = function(_, on_confirm)
        on_confirm(answer)
      end
      vim.notify = function(msg)
        table.insert(notified, msg)
      end
      local ok, err = pcall(fn)
      vim.ui.input, vim.notify = original_input, original_notify
      assert(ok, err)
      return notified
    end

    local function select_email(line, first, last)
      vim.cmd.enew()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { line })
      vim.fn.setpos("'<", { 0, 1, first, 0 })
      vim.fn.setpos("'>", { 0, 1, last, 0 })
    end

    it("substitutes the prompted name and leaves the quoting alone", function()
      -- the shape the raycast script writes; cols 6-23 are inside the quotes
      select_email('  - "dana.b@example.com"', 6, 23)
      with_input("Dana Bell", pages.contact_from_selection)
      assert.equals('  - "Dana Bell"', vim.api.nvim_get_current_line())
      assert.equals(1, vim.fn.filereadable(vault_dir .. "/contacts/dana_bell.md"))
    end)

    it("substitutes a plain name, never a link (attendees are not links)", function()
      select_email("ray@example.com", 1, 15)
      with_input("Ray Ortiz", pages.contact_from_selection)
      assert.equals("Ray Ortiz", vim.api.nvim_get_current_line())
    end)

    it("refuses a selection that is not an address", function()
      select_email("just some prose here", 1, 9)
      local notified = with_input("Nope", pages.contact_from_selection)
      assert.equals("just some prose here", vim.api.nvim_get_current_line())
      assert.equals(0, vim.fn.isdirectory(vault_dir .. "/contacts"))
      assert.same({ "select an email address" }, notified)
    end)

    it("abandons an empty or cancelled name", function()
      select_email("kai@example.com", 1, 15)
      with_input(nil, pages.contact_from_selection)
      assert.equals("kai@example.com", vim.api.nvim_get_current_line())
      assert.equals(0, vim.fn.isdirectory(vault_dir .. "/contacts"))
    end)
  end)
end)
