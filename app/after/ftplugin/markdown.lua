-- lore's markdown feel. after/ so it wins over the runtime ftplugin.
vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2

-- stock markdown_inline conceal hides link URLs; cursor line reveals raw
vim.opt_local.conceallevel = 2

vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt_local.foldlevel = 99
vim.opt_local.foldtext = ""

-- root-relative /path.md links resolve at the vault root
vim.opt_local.includeexpr = "v:lua.require'lore.links'.resolve(v:fname)"

local links = require("lore.links")
local navigate = require("lore.navigate")
vim.keymap.set("n", "gf", links.follow, { buffer = true, desc = "follow link (create if missing)" })
vim.keymap.set({ "n", "x" }, "]]", navigate.next_heading, { buffer = true, desc = "next heading" })
vim.keymap.set({ "n", "x" }, "[[", navigate.prev_heading, { buffer = true, desc = "previous heading" })

vim.keymap.set("i", "[[", function()
  require("lore.completion").trigger()
end, { buffer = true, desc = "complete a page link" })

local lists = require("lore.lists")
vim.keymap.set("i", "<CR>", lists.press_enter, { buffer = true, desc = "continue list item" })
vim.keymap.set("n", "o", lists.open_below, { buffer = true, desc = "open list item below" })
vim.keymap.set("n", "O", lists.open_above, { buffer = true, desc = "open list item above" })
vim.keymap.set("i", "<Tab>", lists.tab, { buffer = true, expr = true, desc = "indent list item" })
vim.keymap.set("i", "<S-Tab>", lists.shift_tab, { buffer = true, expr = true, desc = "dedent list item" })
