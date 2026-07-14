-- Page creation. New pages are born in unsorted/ — a standing signal that
-- they need homes; organization is deferred, not required. Filenames are
-- the fzf retrieval surface: lowercase snake_case, no spaces.
local vaults = require("lore.vaults")

local M = {}

function M.slugify(title)
  local slug = title:lower()
  slug = slug:gsub("[^%w]+", "_")
  slug = slug:gsub("^_+", ""):gsub("_+$", "")
  return slug
end

local function active_vault()
  local vault = vaults.active()
  if not vault then
    error("no active vault")
  end
  return vault
end

-- Create (if needed) unsorted/<slug>.md and return its absolute path.
function M.create(title)
  local slug = M.slugify(title)
  if slug == "" then
    error("empty page title")
  end
  local vault = active_vault()
  local dir = vault.path .. "/unsorted"
  vim.fn.mkdir(dir, "p")
  local path = dir .. "/" .. slug .. ".md"
  if vim.fn.filereadable(path) == 0 then
    vim.fn.writefile({}, path)
  end
  return path
end

-- Root-relative link target, the vault's standard link form.
function M.link_for(path)
  local vault = active_vault()
  return (path:gsub("^" .. vim.pesc(vault.path), ""))
end

-- Replace the visual selection (single line) with a markdown link to a
-- newly created page titled by the selected text.
function M.from_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  if start_pos[2] ~= end_pos[2] then
    return vim.notify("page-from-selection works on a single line", vim.log.levels.WARN)
  end
  local row, start_col, end_col = start_pos[2], start_pos[3], end_pos[3]
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
  end_col = math.min(end_col, #line)
  local title = line:sub(start_col, end_col)
  if vim.trim(title) == "" then
    return vim.notify("nothing selected", vim.log.levels.WARN)
  end
  local path = M.create(title)
  local link = ("[%s](%s)"):format(title, M.link_for(path))
  vim.api.nvim_buf_set_text(0, row - 1, start_col - 1, row - 1, end_col, { link })
end

return M
