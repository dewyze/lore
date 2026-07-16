-- lore's keybinding vocabulary, an instance of the shared grammar
-- (~/dev/dotfiles/KEYBINDINGS.md): five layers, domains are acts,
-- double-letter = default act, find = nameable / search = by content.
-- Keys dispatch to user commands, never inline closures. This table is
-- the config: edit, commit. (The \n folder aliases come from
-- preferences instead — :BindNew manages them.)
local preferences = require("lore.preferences")

local M = {}

local KEYMAPS = {
  -- find (nameable)
  ["<leader>ff"] = "Files",
  ["<leader>ft"] = "Tags",
  ["<leader>fd"] = "Due",
  -- search (by content)
  ["<leader>ss"] = "Grep",
  ["<leader>sw"] = "GrepWord",
  -- new (create + go); folder aliases bound from preferences below
  ["<leader>nm"] = "NewMeeting",
  ["<leader>nf"] = "NewPagePick",
  ["<leader>npp"] = "NewPage projects/",
  ["<leader>npf"] = "NewProjectFile",
  -- vault (va earned first; vv/vl stay command-only until used)
  ["<leader>va"] = "VaultAdd",
  -- palette (alias of the chords)
  ["<leader>p"] = "Palette",
  -- go's
  ["gt"] = "OpenTodo", -- shadows tab-next; ]t/[t cover tabs
  ["gi"] = "OpenInbox", -- shadows insert-at-last-insert
  -- drawers: the C-s show namespace
  ["<C-s><C-s>"] = "Tree",
  ["<C-s><C-l>"] = "Pane",
  ["<C-s><C-f>"] = "TreeReveal",
}

for key, command in pairs(KEYMAPS) do
  vim.keymap.set("n", key, ("<Cmd>%s<CR>"):format(command), { desc = "lore: " .. command })
end

-- capture (append + stay): normal prompts, visual MOVES the selection
-- (":" form so the range reaches the command)
for key, command in pairs({ ["<leader>cc"] = "Inbox", ["<leader>ct"] = "TodoAdd" }) do
  vim.keymap.set("n", key, ("<Cmd>%s<CR>"):format(command), { desc = "lore: " .. command })
  vim.keymap.set("x", key, (":%s<CR>"):format(command), { silent = true, desc = "lore: " .. command })
end

-- brackets: step through ordered things (tabs live here, not on gt)
vim.keymap.set("n", "]t", "<Cmd>tabnext<CR>", { desc = "next tab" })
vim.keymap.set("n", "[t", "<Cmd>tabprevious<CR>", { desc = "previous tab" })

-- bare keeps + C layer, parity with the code world (KEYBINDINGS.md)
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true, desc = "move lines down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true, desc = "move lines up" })
vim.keymap.set("n", "<CR><CR>", "i<CR><Esc>w", { desc = "split line" })
vim.keymap.set("n", "<C-w>m", "<C-w>|<C-w>_", { desc = "maximize window" })
vim.keymap.set("n", "<C-s><C-q>", function()
  local open = vim.fn.getqflist({ winid = 0 }).winid ~= 0
  vim.cmd(open and "cclose" or "copen")
end, { desc = "show: quickfix" })
vim.keymap.set("n", "<C-s><C-t>", "<Cmd>belowright split | terminal<CR>", { desc = "show: terminal" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "exit terminal mode" })
for _, key in ipairs({ "<C-/>", "<C-_>" }) do
  vim.keymap.set("n", key, "gcc", { remap = true, silent = true, desc = "comment line" })
  vim.keymap.set("x", key, "gc", { remap = true, silent = true, desc = "comment selection" })
end

-- palette chords (Cmd+Shift+P is the macOS chord; Ctrl+Shift+P needs a
-- chord-capable terminal — neovide does both)
for _, key in ipairs({ "<D-S-p>", "<C-S-p>" }) do
  vim.keymap.set({ "n", "x" }, key, "<Cmd>Palette<CR>", { desc = "lore: Palette" })
end

-- \n{letter} folder aliases, from preferences (machine-owned; the
-- letters f/m/p are verbs above and stay reserved)
function M.bind_new(letter, folder)
  vim.keymap.set(
    "n",
    "<leader>n" .. letter,
    ("<Cmd>NewPage %s/<CR>"):format(folder),
    { desc = ("lore: new page in %s/"):format(folder) }
  )
end

local DEFAULT_NEW_BINDINGS = { n = "notes", i = "ideas", c = "contacts" }

for letter, folder in pairs(vim.tbl_extend("force", DEFAULT_NEW_BINDINGS, preferences.get("new_page_bindings") or {})) do
  M.bind_new(letter, folder)
end

-- the todo domain only exists inside todo.md
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("lore_todo_keys", {}),
  pattern = "*/todo.md",
  callback = function(event)
    if vim.b[event.buf].lore_todo_keys then
      return
    end
    vim.b[event.buf].lore_todo_keys = true
    vim.keymap.set("n", "<leader>tt", "<Cmd>TodoSort<CR>", { buffer = event.buf, desc = "lore: sort todos" })
    vim.keymap.set("n", "<leader>ta", "<Cmd>TodoArchive<CR>", { buffer = event.buf, desc = "lore: archive done" })
  end,
})

return M
