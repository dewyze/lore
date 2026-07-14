-- Templates are orthogonal to file creation: apply inserts into the
-- current buffer wherever it was born. No folder binding, no path prompts.
local vaults = require("lore.vaults")

local M = {}

function M.list()
  local vault = vaults.active()
  if not vault then
    return {}
  end
  local paths = vim.fn.glob(vault.path .. "/templates/*.md", false, true)
  table.sort(paths)
  return paths
end

local function title_from_buffer()
  return require("lore.pages").title(vim.fn.expand("%:t:r"))
end

function M.apply(path)
  local lines = vim.fn.readfile(path)
  local date = os.date("%Y-%m-%d")
  local title = title_from_buffer()
  lines = vim.tbl_map(function(line)
    line = line:gsub("{{date}}", date)
    line = line:gsub("{{title}}", title)
    return line
  end, lines)

  local buffer_empty = vim.api.nvim_buf_line_count(0) == 1
    and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == ""
  if buffer_empty then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  else
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row, row, false, lines)
  end
end

return M
