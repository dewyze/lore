-- Plugin budget (SPEC "Plugins"): every addition needs a named friction.
-- Managed by vim.pack; the lockfile (app/nvim-pack-lock.json) is committed.
local specs = {
  -- parser installer only — core 0.12 owns the treesitter runtime
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
  -- picker (+ input/win if the pane wants them)
  { src = "https://github.com/folke/snacks.nvim" },
  -- existing daily habit; carries the creation-location story
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim" },
  { src = "https://github.com/nvim-lua/plenary.nvim" }, -- neo-tree dependency
  { src = "https://github.com/MunifTanjim/nui.nvim" }, -- neo-tree dependency
  { src = "https://github.com/nvim-tree/nvim-web-devicons" }, -- neo-tree dependency
  -- replaces the inline-style-toggles feature
  { src = "https://github.com/tpope/vim-surround" },
}

-- ~/.lore/config.lua exists ONLY for plugin injection (vimoire precedent).
-- It may return { plugins = { <vim.pack specs> } }. Settings never live
-- there — those go through commands into preferences.json.
local user_config = vim.fn.expand("~/." .. (vim.env.NVIM_APPNAME or "lore") .. "/config.lua")
if vim.fn.filereadable(user_config) == 1 then
  local ok, config = pcall(dofile, user_config)
  if ok and type(config) == "table" and type(config.plugins) == "table" then
    vim.list_extend(specs, config.plugins)
  elseif not ok then
    vim.notify("lore: failed to load " .. user_config .. ": " .. tostring(config), vim.log.levels.WARN)
  end
end

vim.pack.add(specs, { confirm = false })
