-- lore — bootstrap. The repo's app/ dir is symlinked to ~/.config/lore and
-- loaded via NVIM_APPNAME=lore (see bin/lore).
vim.g.mapleader = "\\"

require("config.options")
require("config.pack")
require("config.plugins")
require("config.treesitter")
require("config.commands")
require("config.keymaps")

require("lore.checkbox").setup()
require("lore.session").setup()
require("lore.todo").setup()
require("lore.git").setup()
require("lore.pane").setup()
require("lore.completion").setup()

-- bin/lore normally passes --listen; this covers direct `NVIM_APPNAME=lore
-- nvim` launches. Fails harmlessly if the socket is already ours.
pcall(vim.fn.serverstart, "/tmp/lore.sock")
