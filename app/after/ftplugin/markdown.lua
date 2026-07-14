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

local lists = require("lore.lists")
vim.keymap.set("i", "<CR>", lists.press_enter, { buffer = true, desc = "continue list item" })
vim.keymap.set("n", "o", lists.open_below, { buffer = true, desc = "open list item below" })
vim.keymap.set("n", "O", lists.open_above, { buffer = true, desc = "open list item above" })
vim.keymap.set("i", "<Tab>", lists.tab, { buffer = true, expr = true, desc = "indent list item" })
vim.keymap.set("i", "<S-Tab>", lists.shift_tab, { buffer = true, expr = true, desc = "dedent list item" })
