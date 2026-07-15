-- Page creation. Pages are born in their homes — notes/ by default, or a
-- named folder (folder-targeted keybindings make the choice one
-- keystroke). No triage state; folders self-create. Filenames are the
-- fzf retrieval surface: lowercase snake_case, no spaces.
local vaults = require("lore.vaults")

local M = {}

function M.slugify(title)
  local slug = title:lower()
  slug = slug:gsub("[^%w]+", "_")
  slug = slug:gsub("^_+", ""):gsub("_+$", "")
  return slug
end

-- "rails_upgrade" -> "Rails Upgrade" (the display-title convention;
-- filenames are the store, titles are derived)
function M.title(slug)
  return (slug:gsub("_", " "):gsub("(%a)(%w*)", function(first, rest)
    return first:upper() .. rest
  end))
end

local function active_vault()
  local vault = vaults.active()
  if not vault then
    error("no active vault")
  end
  return vault
end

-- Create (if needed) <dir>/<slug>.md and return its absolute path.
-- opts.date_prefix stamps the slug (meetings: 2026_07_15_team_sync.md).
function M.create(title, dir, opts)
  local slug = M.slugify(title)
  if slug == "" then
    error("empty page title")
  end
  if opts and opts.date_prefix then
    slug = os.date("%Y_%m_%d_") .. slug
  end
  local vault = active_vault()
  local target = vault.path .. "/" .. (dir or "notes")
  vim.fn.mkdir(target, "p")
  local path = target .. "/" .. slug .. ".md"
  if vim.fn.filereadable(path) == 0 then
    vim.fn.writefile({}, path)
  end
  return path
end

-- A file under a project's folder (projects/ is the one place with
-- subfolders), born linking back to its hub so it appears in the hub's
-- backlinks pane immediately.
function M.create_in_project(hub_path, title)
  local slug = vim.fn.fnamemodify(hub_path, ":t:r")
  local path = M.create(title, "projects/" .. slug)
  if vim.fn.getfsize(path) == 0 then
    vim.fn.writefile({ ("[%s](/projects/%s.md)"):format(M.title(slug), slug), "" }, path)
  end
  return path
end

-- Root-relative link target, the vault's standard link form.
function M.link_for(path)
  local vault = active_vault()
  return (path:gsub("^" .. vim.pesc(vault.path), ""))
end

-- Replace the word under the cursor with a link to a new page titled by it.
function M.from_word()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    return vim.notify("no word under cursor", vim.log.levels.WARN)
  end
  local line = vim.api.nvim_get_current_line()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  -- find the <cword> occurrence containing the cursor
  local init, start_col, end_col = 1, nil, nil
  while true do
    local s, e = line:find(word, init, true)
    if not s then
      break
    end
    if col + 1 >= s and col + 1 <= e then
      start_col, end_col = s, e
      break
    end
    init = e + 1
  end
  if not start_col then
    return vim.notify("no word under cursor", vim.log.levels.WARN)
  end
  local path = M.create(word)
  local link = ("[%s](%s)"):format(word, M.link_for(path))
  vim.api.nvim_buf_set_text(0, row - 1, start_col - 1, row - 1, end_col, { link })
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
