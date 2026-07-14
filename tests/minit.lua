-- Minimal init for the test harness. Run via bin/test, which sets
-- NVIM_APPNAME=lore-test so plugin/data/preferences dirs never touch a
-- real lore install.
local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.normalize(vim.fs.dirname(vim.fs.dirname(source)))

-- parallel children race on shared swap/shada state; neither is under test
vim.o.swapfile = false
vim.o.shadafile = "NONE"

vim.opt.runtimepath:prepend(root .. "/app")
vim.opt.runtimepath:append(root .. "/app/after")

-- commands are part of the surface under test
require("config.commands")

vim.pack.add({ "https://github.com/nvim-lua/plenary.nvim" }, { confirm = false })
