-- Editor options. Markdown-specific options live in ftplugin, not here.

-- External writers (Raycast capture scripts) append to vault files while
-- lore holds them in buffers; pull changes in at attention boundaries
-- instead of prompting.
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("lore_checktime", {}),
  callback = function()
    if vim.o.buftype == "" then
      vim.cmd.checktime()
    end
  end,
})
