-- User commands are the app's real interface; keymaps only dispatch here.
local checkbox = require("lore.checkbox")
local vaults = require("lore.vaults")
local session = require("lore.session")

local function notify_error(err)
  vim.notify((err:gsub("^.-:%d+: ", "")), vim.log.levels.ERROR)
end

vim.api.nvim_create_user_command("LoreVaultAdd", function(opts)
  local function add(name, path)
    local ok, err = pcall(vaults.add, name, path)
    if not ok then
      return notify_error(err)
    end
    local active = vaults.active()
    if active.name == name then
      session.open_vault(active)
    end
  end
  local name, path = unpack(opts.fargs)
  if name and path then
    return add(name, path)
  end
  -- bare (or \va): prompt for both
  vim.ui.input({ prompt = "vault name" }, function(input_name)
    if not input_name or input_name == "" then
      return
    end
    vim.ui.input({ prompt = "vault path", completion = "dir" }, function(input_path)
      if input_path and input_path ~= "" then
        add(input_name, input_path)
      end
    end)
  end)
end, { nargs = "*", complete = "dir", desc = "Register a vault (scaffold + git init); prompts when bare" })

vim.api.nvim_create_user_command("LoreRenumber", function()
  require("lore.lists").renumber()
end, { desc = "Renumber ordered lists" })

vim.api.nvim_create_user_command("LoreDue", function()
  require("lore.due").view()
end, { desc = "All @due dates in the vault, soonest first" })

vim.api.nvim_create_user_command("LoreTodoSort", function()
  require("lore.todo").sort()
end, { desc = "Sort todo lists by state, subtree-aware" })

vim.api.nvim_create_user_command("LoreTodoArchive", function()
  require("lore.todo").archive()
end, { desc = "Sweep [x] subtrees into archive.md" })

vim.api.nvim_create_user_command("LoreVaultList", function()
  local lines = {}
  local active = vaults.active()
  for _, vault in ipairs(vaults.list()) do
    local marker = (active and active.name == vault.name) and "*" or " "
    table.insert(lines, ("%s %s  %s"):format(marker, vault.name, vault.path))
  end
  if #lines == 0 then
    lines = { "no vaults registered — :LoreVaultAdd {name} {path}" }
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end, { desc = "List vaults (* = active)" })

vim.api.nvim_create_user_command("LoreCheckboxCycle", function()
  checkbox.cycle()
end, { desc = "Cycle checkbox: [ ] -> [/] -> [x] -> [ ]" })

local CHECKBOX_STATES = { todo = " ", in_progress = "/", done = "x", blocked = "!" }

vim.api.nvim_create_user_command("LoreCheckboxSet", function(opts)
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

vim.api.nvim_create_user_command("LoreVaultSwitch", function(opts)
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

vim.api.nvim_create_user_command("LoreFiles", function()
  require("lore.pickers").files()
end, { desc = "Find file in the active vault" })

vim.api.nvim_create_user_command("LoreGrep", function()
  require("lore.pickers").grep()
end, { desc = "Live grep the active vault" })

vim.api.nvim_create_user_command("LoreTags", function()
  require("lore.pickers").tags()
end, { desc = "Search tags in the active vault" })

-- :LoreNewPage [{folder}/] [{title...}] — a first arg ending in "/" names
-- the destination (created if missing); default is notes/. No title
-- prompts for one. Folder-targeted keybindings pass the folder arg.
vim.api.nvim_create_user_command("LoreNewPage", function(opts)
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
end, { nargs = "*", desc = "Create a page and open it (LoreNewPage {folder}/ {title})" })

vim.api.nvim_create_user_command("LorePageFromSelection", function()
  require("lore.pages").from_selection()
end, { range = true, desc = "Create a page from the selection, replace it with a link" })

vim.api.nvim_create_user_command("LoreNewMeeting", function(opts)
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

vim.api.nvim_create_user_command("LoreNewPagePick", function()
  require("lore.pickers").new_page_folder()
end, { desc = "Create a page: pick the folder, then name it" })

vim.api.nvim_create_user_command("LoreNewProjectFile", function()
  require("lore.pickers").new_project_file()
end, { desc = "Create a file under a project, linked to its hub" })

vim.api.nvim_create_user_command("LoreGrepWord", function()
  require("lore.pickers").grep_word()
end, { desc = "Grep the vault for the word under the cursor" })

vim.api.nvim_create_user_command("LoreOpenTodo", function()
  local vault = vaults.active()
  if not vault then
    return notify_error("no active vault")
  end
  vim.cmd.edit(vim.fn.fnameescape(vault.path .. "/todo.md"))
end, { desc = "Go to todo.md" })

vim.api.nvim_create_user_command("LoreOpenInbox", function()
  local vault = vaults.active()
  if not vault then
    return notify_error("no active vault")
  end
  vim.cmd.edit(vim.fn.fnameescape(vault.path .. "/inbox.md"))
end, { desc = "Go to inbox.md" })

vim.api.nvim_create_user_command("LoreTreeReveal", function()
  vim.cmd("Neotree reveal")
end, { desc = "Reveal the current file in the tree" })

local RESERVED_NEW_LETTERS = { f = true, m = true, p = true }

vim.api.nvim_create_user_command("LoreBindNew", function(opts)
  local letter, folder = unpack(opts.fargs)
  if not (letter and folder) or #letter ~= 1 then
    return notify_error("usage: LoreBindNew {letter} {folder}")
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

vim.api.nvim_create_user_command("LorePageFromWord", function()
  require("lore.pages").from_word()
end, { desc = "Create a page from the word under the cursor, replace it with a link" })

vim.api.nvim_create_user_command("LorePalette", function()
  require("lore.palette").open()
end, { desc = "Command palette" })

vim.api.nvim_create_user_command("LorePane", function()
  require("lore.pane").toggle()
end, { desc = "Toggle the links + backlinks pane" })

vim.api.nvim_create_user_command("LoreTree", function()
  vim.cmd("Neotree toggle")
end, { desc = "Toggle the file tree" })

vim.api.nvim_create_user_command("LoreFrontmatter", function()
  require("lore.navigate").frontmatter_toggle()
end, { desc = "Jump to frontmatter (and back)" })

vim.api.nvim_create_user_command("LoreTemplate", function()
  require("lore.pickers").templates()
end, { desc = "Apply a template into the current buffer" })

-- Capture: append + stay. Normal mode prompts; a visual range MOVES the
-- selection out ("this thought doesn't belong here") — undo/git make
-- that safe.
vim.api.nvim_create_user_command("LoreInbox", function(opts)
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

vim.api.nvim_create_user_command("LoreTodoAdd", function(opts)
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
