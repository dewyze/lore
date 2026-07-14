-- Minimal init for the test harness. Run via bin/test, which sets
-- NVIM_APPNAME=lore-test so plugin/data/preferences dirs never touch a
-- real lore install.
local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.normalize(vim.fs.dirname(vim.fs.dirname(source)))

vim.opt.runtimepath:prepend(root .. "/app")

vim.pack.add({ "https://github.com/nvim-lua/plenary.nvim" }, { confirm = false })
