-- Buffer navigation: frontmatter jump (and back), heading motions.
local M = {}

local function frontmatter_end()
  if vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] ~= "---" then
    return nil
  end
  local last = math.min(vim.api.nvim_buf_line_count(0), 100)
  local lines = vim.api.nvim_buf_get_lines(0, 1, last, false)
  for i, line in ipairs(lines) do
    if line == "---" then
      return i + 1
    end
  end
  return nil
end

function M.frontmatter_toggle()
  local last = frontmatter_end()
  if not last then
    return vim.notify("no frontmatter", vim.log.levels.INFO)
  end
  if vim.api.nvim_win_get_cursor(0)[1] <= last then
    vim.cmd("normal! ``") -- back to where we jumped from
  else
    vim.cmd("normal! m'")
    vim.api.nvim_win_set_cursor(0, { math.min(2, last), 0 })
  end
end

local HEADING = [[^#\+\s]]

function M.next_heading()
  vim.fn.search(HEADING, "W")
end

function M.prev_heading()
  vim.fn.search(HEADING, "bW")
end

return M
