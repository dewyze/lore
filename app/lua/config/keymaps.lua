-- lore's keybinding vocabulary, an instance of the shared grammar
-- (~/dev/dotfiles/KEYBINDINGS.md): five layers, domains are acts,
-- double-letter = default act, find = nameable / search = by content.
-- Keys dispatch to user commands, never inline closures. This table is
-- the config: edit, commit. (The \n folder aliases come from
-- preferences instead — :LoreBindNew manages them.)
local preferences = require("lore.preferences")

local M = {}

local KEYMAPS = {
  -- find (nameable)
  ["<leader>ff"] = "LoreFiles",
  ["<leader>ft"] = "LoreTags",
  ["<leader>fd"] = "LoreDue",
  -- search (by content)
  ["<leader>ss"] = "LoreGrep",
  ["<leader>sw"] = "LoreGrepWord",
  -- new (create + go); folder aliases bound from preferences below
  ["<leader>nm"] = "LoreNewMeeting",
  ["<leader>nf"] = "LoreNewPagePick",
  ["<leader>npp"] = "LoreNewPage projects/",
  ["<leader>npf"] = "LoreNewProjectFile",
  -- vault (va earned first; vv/vl stay command-only until used)
  ["<leader>va"] = "LoreVaultAdd",
  -- palette (alias of the chords)
  ["<leader>p"] = "LorePalette",
  -- go's
  ["gt"] = "LoreOpenTodo", -- shadows tab-next; ]t/[t cover tabs
  ["gi"] = "LoreOpenInbox", -- shadows insert-at-last-insert
  -- drawers: the C-s show namespace
  ["<C-s><C-s>"] = "LoreTree",
  ["<C-s><C-l>"] = "LorePane",
  ["<C-s><C-f>"] = "LoreTreeReveal",
}

for key, command in pairs(KEYMAPS) do
  vim.keymap.set("n", key, ("<Cmd>%s<CR>"):format(command), { desc = "lore: " .. command })
end

-- capture (append + stay): normal prompts, visual MOVES the selection
-- (":" form so the range reaches the command)
for key, command in pairs({ ["<leader>cc"] = "LoreInbox", ["<leader>ct"] = "LoreTodoAdd" }) do
  vim.keymap.set("n", key, ("<Cmd>%s<CR>"):format(command), { desc = "lore: " .. command })
  vim.keymap.set("x", key, (":%s<CR>"):format(command), { silent = true, desc = "lore: " .. command })
end

-- brackets: step through ordered things (tabs live here, not on gt)
vim.keymap.set("n", "]t", "<Cmd>tabnext<CR>", { desc = "next tab" })
vim.keymap.set("n", "[t", "<Cmd>tabprevious<CR>", { desc = "previous tab" })

-- palette chords (Cmd+Shift+P is the macOS chord; Ctrl+Shift+P needs a
-- chord-capable terminal — neovide does both)
for _, key in ipairs({ "<D-S-p>", "<C-S-p>" }) do
  vim.keymap.set({ "n", "x" }, key, "<Cmd>LorePalette<CR>", { desc = "lore: LorePalette" })
end

-- \n{letter} folder aliases, from preferences (machine-owned; the
-- letters f/m/p are verbs above and stay reserved)
function M.bind_new(letter, folder)
  vim.keymap.set(
    "n",
    "<leader>n" .. letter,
    ("<Cmd>LoreNewPage %s/<CR>"):format(folder),
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
    vim.keymap.set("n", "<leader>tt", "<Cmd>LoreTodoSort<CR>", { buffer = event.buf, desc = "lore: sort todos" })
    vim.keymap.set("n", "<leader>ta", "<Cmd>LoreTodoArchive<CR>", { buffer = event.buf, desc = "lore: archive done" })
  end,
})

return M
