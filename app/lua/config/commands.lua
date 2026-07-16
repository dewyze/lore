-- User commands are the app's real interface; keymaps only dispatch here.
local checkbox = require("lore.checkbox")
local vaults = require("lore.vaults")
local session = require("lore.session")

local function notify_error(err)
  vim.notify((err:gsub("^.-:%d+: ", "")), vim.log.levels.ERROR)
end

-- VaultAdd {path} [name] — like every other tool: you say where, the
-- name defaults to the folder's name. Bare (or \va) prompts for the
-- path with directory Tab-completion.
vim.api.nvim_create_user_command("VaultAdd", function(opts)
  local function add(path, name)
    if not name or name == "" then
      name = vim.fn.fnamemodify((vim.fn.expand(path):gsub("/$", "")), ":t")
    end
    local ok, err = pcall(vaults.add, name, path)
    if not ok then
      return notify_error(err)
    end
    vim.notify(("vault %q added"):format(name), vim.log.levels.INFO)
    local active = vaults.active()
    if active.name == name then
      session.open_vault(active)
    end
  end
  local path, name = unpack(opts.fargs)
  if path then
    return add(path, name)
  end
  vim.ui.input({ prompt = "vault path", completion = "dir" }, function(input)
    if input and input ~= "" then
      add(input)
    end
  end)
end, { nargs = "*", complete = "dir", desc = "Register a vault: VaultAdd {path} [name]" })

vim.api.nvim_create_user_command("Renumber", function()
  require("lore.lists").renumber()
end, { desc = "Renumber ordered lists" })

vim.api.nvim_create_user_command("Due", function()
  require("lore.due").view()
end, { desc = "All @due dates in the vault, soonest first" })

vim.api.nvim_create_user_command("TodoSort", function()
  require("lore.todo").sort()
end, { desc = "Sort todo lists by state, subtree-aware" })

vim.api.nvim_create_user_command("TodoArchive", function()
  require("lore.todo").archive()
end, { desc = "Sweep [x] subtrees into archive.md" })

vim.api.nvim_create_user_command("VaultList", function()
  local lines = {}
  local active = vaults.active()
  for _, vault in ipairs(vaults.list()) do
    local marker = (active and active.name == vault.name) and "*" or " "
    table.insert(lines, ("%s %s  %s"):format(marker, vault.name, vault.path))
  end
  if #lines == 0 then
    lines = { "no vaults registered — :VaultAdd {name} {path}" }
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end, { desc = "List vaults (* = active)" })

vim.api.nvim_create_user_command("CheckboxCycle", function()
  checkbox.cycle()
end, { desc = "Cycle checkbox: [ ] -> [/] -> [x] -> [ ]" })

local CHECKBOX_STATES = { todo = " ", in_progress = "/", done = "x", blocked = "!" }

vim.api.nvim_create_user_command("CheckboxSet", function(opts)
  local state = CHECKBOX_STATES[opts.args]
  if not state then
    return notify_error(("unknown checkbox state %q"):format(opts.args))
  end
  checkbox.set(state)
end, {
  nargs = 1,
  complete = function()
    return vim.tbl_keys(CHECKBOX_STATES)
  end,
  desc = "Set checkbox state explicitly",
})

vim.api.nvim_create_user_command("VaultSwitch", function(opts)
  if opts.args == "" then
    return require("lore.pickers").vaults()
  end
  local ok, err = pcall(vaults.switch, opts.args)
  if not ok then
    return notify_error(err)
  end
  session.open_vault(vaults.active())
end, {
  nargs = "?",
  complete = function()
    return vim.tbl_map(function(vault)
      return vault.name
    end, vaults.list())
  end,
  desc = "Switch the active vault (picker with no argument)",
})

vim.api.nvim_create_user_command("Files", function()
  require("lore.pickers").files()
end, { desc = "Find file in the active vault" })

vim.api.nvim_create_user_command("Grep", function()
  require("lore.pickers").grep()
end, { desc = "Live grep the active vault" })

vim.api.nvim_create_user_command("Tags", function()
  require("lore.pickers").tags()
end, { desc = "Search tags in the active vault" })

-- :NewPage [{folder}/] [{title...}] — a first arg ending in "/" names
-- the destination (created if missing); default is notes/. No title
-- prompts for one. Folder-targeted keybindings pass the folder arg.
vim.api.nvim_create_user_command("NewPage", function(opts)
  local args = vim.list_slice(opts.fargs)
  local dir = "notes"
  if args[1] and args[1]:match("/$") then
    dir = table.remove(args, 1):gsub("/$", "")
  end
  local function create_and_open(title)
    local ok, result = pcall(require("lore.pages").create, title, dir)
    if not ok then
      return notify_error(result)
    end
    vim.cmd.edit(vim.fn.fnameescape(result))
  end
  local title = table.concat(args, " ")
  if title ~= "" then
    return create_and_open(title)
  end
  vim.ui.input({ prompt = ("page title (%s/)"):format(dir) }, function(input)
    if input then
      create_and_open(input)
    end
  end)
end, { nargs = "*", desc = "Create a page and open it (NewPage {folder}/ {title})" })

vim.api.nvim_create_user_command("PageFromSelection", function()
  require("lore.pages").from_selection()
end, { range = true, desc = "Create a page from the selection, replace it with a link" })

vim.api.nvim_create_user_command("NewMeeting", function(opts)
  local function create(title)
    local ok, result = pcall(require("lore.pages").create, title, "meetings", { date_prefix = true })
    if not ok then
      return notify_error(result)
    end
    vim.cmd.edit(vim.fn.fnameescape(result))
    local template = vaults.active().path .. "/templates/meeting.md"
    if vim.fn.filereadable(template) == 1 then
      require("lore.templates").apply(template, { title = title })
    end
  end
  if opts.args ~= "" then
    return create(opts.args)
  end
  vim.ui.input({ prompt = "meeting title" }, function(title)
    if title then
      create(title)
    end
  end)
end, { nargs = "*", desc = "Create today's meeting note (date-prefixed, template applied)" })

vim.api.nvim_create_user_command("NewPagePick", function()
  require("lore.pickers").new_page_folder()
end, { desc = "Create a page: pick the folder, then name it" })

vim.api.nvim_create_user_command("NewProjectFile", function()
  require("lore.pickers").new_project_file()
end, { desc = "Create a file under a project, linked to its hub" })

vim.api.nvim_create_user_command("GrepWord", function()
  require("lore.pickers").grep_word()
end, { desc = "Grep the vault for the word under the cursor" })

vim.api.nvim_create_user_command("OpenTodo", function()
  local vault = vaults.active()
  if not vault then
    return notify_error("no active vault")
  end
  vim.cmd.edit(vim.fn.fnameescape(vault.path .. "/todo.md"))
end, { desc = "Go to todo.md" })

vim.api.nvim_create_user_command("OpenInbox", function()
  local vault = vaults.active()
  if not vault then
    return notify_error("no active vault")
  end
  vim.cmd.edit(vim.fn.fnameescape(vault.path .. "/inbox.md"))
end, { desc = "Go to inbox.md" })

vim.api.nvim_create_user_command("TreeReveal", function()
  vim.cmd("Neotree reveal")
end, { desc = "Reveal the current file in the tree" })

local RESERVED_NEW_LETTERS = { f = true, m = true, p = true }

vim.api.nvim_create_user_command("BindNew", function(opts)
  local letter, folder = unpack(opts.fargs)
  if not (letter and folder) or #letter ~= 1 then
    return notify_error("usage: BindNew {letter} {folder}")
  end
  if RESERVED_NEW_LETTERS[letter] then
    return notify_error(("\\n%s is reserved (folder picker / meeting / project)"):format(letter))
  end
  folder = (folder:gsub("/$", ""))
  local preferences = require("lore.preferences")
  local bindings = preferences.get("new_page_bindings") or {}
  bindings[letter] = folder
  preferences.set("new_page_bindings", bindings)
  require("config.keymaps").bind_new(letter, folder)
  vim.notify(("\\n%s -> %s/"):format(letter, folder), vim.log.levels.INFO)
end, { nargs = "+", desc = "Bind \\n{letter} to create pages in {folder}" })

vim.api.nvim_create_user_command("PageFromWord", function()
  require("lore.pages").from_word()
end, { desc = "Create a page from the word under the cursor, replace it with a link" })

vim.api.nvim_create_user_command("Palette", function()
  require("lore.palette").open()
end, { desc = "Command palette" })

vim.api.nvim_create_user_command("Pane", function()
  require("lore.pane").toggle()
end, { desc = "Toggle the links + backlinks pane" })

vim.api.nvim_create_user_command("Tree", function()
  vim.cmd("Neotree toggle")
end, { desc = "Toggle the file tree" })

local THEMES = { "wisp", "daybreak", "fathom", "ember" }

vim.api.nvim_create_user_command("Theme", function(opts)
  local name = opts.args
  if not vim.tbl_contains(THEMES, name) then
    return notify_error(("unknown theme %q (%s)"):format(name, table.concat(THEMES, ", ")))
  end
  vim.cmd.colorscheme(name)
  require("lore.preferences").set("colorscheme", name)
end, {
  nargs = 1,
  complete = function()
    return THEMES
  end,
  desc = "Switch theme (persists)",
})

vim.api.nvim_create_user_command("Font", function(opts)
  if opts.args == "" then
    return vim.notify(vim.o.guifont, vim.log.levels.INFO)
  end
  vim.o.guifont = opts.args
  require("lore.preferences").set("font", opts.args)
end, { nargs = "*", desc = "Set the GUI font, e.g. :Font Iosevka Term Slab:h16 (persists; bare shows current)" })

vim.api.nvim_create_user_command("Frontmatter", function()
  require("lore.navigate").frontmatter_toggle()
end, { desc = "Jump to frontmatter (and back)" })

vim.api.nvim_create_user_command("Template", function()
  require("lore.pickers").templates()
end, { desc = "Apply a template into the current buffer" })

-- Capture: append + stay. Normal mode prompts; a visual range MOVES the
-- selection out ("this thought doesn't belong here") — undo/git make
-- that safe.
vim.api.nvim_create_user_command("Inbox", function(opts)
  if opts.range > 0 then
    local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
    local ok, err = pcall(function()
      for _, line in ipairs(lines) do
        require("lore.inbox").append(line)
      end
    end)
    if not ok then
      return notify_error(err)
    end
    return vim.api.nvim_buf_set_lines(0, opts.line1 - 1, opts.line2, false, {})
  end
  local function capture(text)
    local ok, err = pcall(require("lore.inbox").append, text)
    if not ok then
      notify_error(err)
    end
  end
  if opts.args ~= "" then
    return capture(opts.args)
  end
  vim.ui.input({ prompt = "inbox" }, function(text)
    if text then
      capture(text)
    end
  end)
end, { nargs = "*", range = true, desc = "Capture a thought to inbox.md (visual: move selection)" })

vim.api.nvim_create_user_command("TodoAdd", function(opts)
  local todo = require("lore.todo")
  if opts.range > 0 then
    local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
    local text = table.concat(vim.tbl_map(vim.trim, lines), " ")
    local ok, err = pcall(todo.add, text)
    if not ok then
      return notify_error(err)
    end
    return vim.api.nvim_buf_set_lines(0, opts.line1 - 1, opts.line2, false, {})
  end
  local function capture(text)
    local ok, err = pcall(todo.add, text)
    if not ok then
      notify_error(err)
    end
  end
  if opts.args ~= "" then
    return capture(opts.args)
  end
  vim.ui.input({ prompt = "todo" }, function(text)
    if text then
      capture(text)
    end
  end)
end, { nargs = "*", range = true, desc = "Capture a todo to todo.md (visual: move selection)" })
