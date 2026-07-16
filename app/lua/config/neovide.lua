-- GUI feel (vimoire's block, adapted). Font comes from preferences —
-- machine-owned config, :Font manages it.
local preferences = require("lore.preferences")

local DEFAULT_FONT = "Iosevka Term Slab:h16"

vim.o.guifont = preferences.get("font") or DEFAULT_FONT
vim.o.linespace = 8

if vim.g.neovide then
  vim.g.neovide_padding_top = 20
  vim.g.neovide_padding_left = 20
  vim.g.neovide_padding_right = 20
  vim.g.neovide_padding_bottom = 20
  vim.g.neovide_scroll_animation_length = 0.3
  vim.g.neovide_position_animation_length = 0
  -- the cursor streaking down to the cmdline on :w read as a progress
  -- bar; keep the in-buffer trail, kill the cmdline leg
  vim.g.neovide_cursor_animate_command_line = false

  -- Standard macOS keymaps (neovide doesn't provide these)
  vim.keymap.set({ "n", "i" }, "<D-s>", "<Cmd>w<CR>", { desc = "save" })
  vim.keymap.set("v", "<D-c>", '"+y', { desc = "copy" })
  vim.keymap.set("v", "<D-x>", '"+d', { desc = "cut" })
  vim.keymap.set({ "n", "v" }, "<D-v>", '"+P', { desc = "paste" })
  vim.keymap.set({ "c", "i" }, "<D-v>", "<C-R>+", { desc = "paste" })
end
