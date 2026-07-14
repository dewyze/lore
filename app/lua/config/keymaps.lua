-- Default keybindings — okf's settled scheme (its decision 12) until the
-- semantic-keybinding refactor. This table IS the keybinding config: the
-- repo is the app, so change keys here and commit. A command maps to one
-- key or a list of keys; nil disables. Keys dispatch to user commands,
-- never inline closures.
local keymaps = {
  LoreFiles = "<leader>ff",
  LoreGrep = "<leader>fg",
  LoreTags = "<leader>ft",
  LorePane = "<leader>fb",
  LoreNewPage = "<leader>nf",
  LoreTree = "<leader>nt",
  LoreInbox = "<leader>i",
  LoreFrontmatter = "<leader>h",
  LoreVaultSwitch = "<leader>v",
}

for command, keys in pairs(keymaps) do
  if type(keys) == "string" then
    keys = { keys }
  end
  for _, key in ipairs(keys or {}) do
    vim.keymap.set("n", key, ("<Cmd>%s<CR>"):format(command), { desc = "lore: " .. command })
  end
end

-- Command palette: Cmd+Shift+P (the macOS palette chord; neovide passes
-- it through) + Ctrl+Shift+P (terminal-ambiguous with C-p, but harmless)
-- + a leader fallback.
for _, key in ipairs({ "<D-S-p>", "<C-S-p>", "<leader>p" }) do
  vim.keymap.set({ "n", "x" }, key, "<Cmd>LorePalette<CR>", { desc = "lore: LorePalette" })
end
