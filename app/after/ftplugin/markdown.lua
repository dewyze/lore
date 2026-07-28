-- lore's markdown feel. after/ so it wins over the runtime ftplugin.
vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2

-- stock markdown_inline conceal hides link URLs; cursor line reveals raw
vim.opt_local.conceallevel = 2

-- fuzzy-filter the [[ page completion (native ins-completion). noinsert is
-- load-bearing: without it nvim commits the first match the moment the pum
-- opens, so the next keystroke ends completion and CompleteDone links the
-- wrong page. Held back, the match stays highlighted and typing narrows it.
vim.opt_local.completeopt:append({ "fuzzy", "noinsert" })

vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt_local.foldlevel = 99
vim.opt_local.foldtext = ""

-- root-relative /path.md links resolve at the vault root
vim.opt_local.includeexpr = "v:lua.require'lore.links'.resolve(v:fname)"

local links = require("lore.links")
local navigate = require("lore.navigate")
vim.keymap.set("n", "gf", links.follow, { buffer = true, desc = "follow link (create if missing)" })
vim.keymap.set("n", "K", links.follow, { buffer = true, desc = "follow link (alias of gf)" })
vim.keymap.set("n", "gh", "<Cmd>Frontmatter<CR>", { buffer = true, desc = "frontmatter (and back)" })
vim.keymap.set({ "n", "x" }, "]]", navigate.next_heading, { buffer = true, desc = "next heading" })
vim.keymap.set({ "n", "x" }, "[[", navigate.prev_heading, { buffer = true, desc = "previous heading" })
vim.keymap.set({ "n", "x" }, "]l", navigate.next_link, { buffer = true, desc = "next link" })
vim.keymap.set({ "n", "x" }, "[l", navigate.prev_link, { buffer = true, desc = "previous link" })

vim.keymap.set("n", "<Space>", "<Cmd>CheckboxCycle<CR>", { buffer = true, desc = "cycle checkbox" })

vim.keymap.set("n", "p", function()
  require("lore.urls").paste()
end, { buffer = true, desc = "paste (urls become titled links)" })

-- [[ types itself, then hands off to the page completefunc. completefunc,
-- not omnifunc: omnifunc is the filetype/LSP slot and would get stomped.
vim.bo.completefunc = "v:lua.require'lore.completion'.completefunc"
vim.keymap.set("i", "[[", "[[<C-x><C-u>", { buffer = true, desc = "complete a page link" })

local lists = require("lore.lists")
vim.keymap.set("i", "<CR>", lists.press_enter, { buffer = true, desc = "continue list item" })
vim.keymap.set("n", "o", lists.open_below, { buffer = true, desc = "open list item below" })
vim.keymap.set("n", "O", lists.open_above, { buffer = true, desc = "open list item above" })
vim.keymap.set("i", "<Tab>", lists.tab, { buffer = true, expr = true, desc = "indent list item" })
vim.keymap.set("i", "<S-Tab>", lists.shift_tab, { buffer = true, expr = true, desc = "dedent list item" })
