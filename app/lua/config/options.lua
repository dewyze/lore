-- Editor options. Markdown-specific options live in ftplugin, not here.
-- Base set harvested from dotfiles + vimoire (their convergent choices),
-- adapted where lore's nature differs (GUI-first, prose-leaning).

vim.o.number = true
vim.o.confirm = true
vim.o.cursorline = true -- dotfiles habit; also where conceal reveals raw links
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.scrolloff = 5
vim.o.undofile = true
vim.o.swapfile = false -- vimoire's call; lore autosaves on every pause anyway
vim.o.mouse = "a" -- vimoire, not dotfiles: a GUI notes app wants the mouse
vim.o.termguicolors = true
vim.o.linebreak = true -- wrap at word boundaries, prose-friendly
vim.o.breakindent = true -- wrapped list items keep their indent

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
