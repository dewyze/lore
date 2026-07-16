-- Standard markdown links, OKF-flavored: [Title](/path.md) root-relative
-- to the active vault. follow() replaces gf so a missing target is created
-- rather than erroring (spec: "gf on a missing file -> create it").
local vaults = require("lore.vaults")

local M = {}

-- includeexpr hook: vault-root the /-relative targets.
function M.resolve(fname)
  if fname:sub(1, 1) == "/" then
    local vault = vaults.active()
    if vault then
      return vault.path .. fname
    end
  end
  return fname
end

-- The [text](target) link containing the cursor, or nil.
function M.target_at_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local init = 1
  while true do
    local start_col, end_col, target = line:find("%[[^%]]*%]%(([^%)]+)%)", init)
    if not start_col then
      return nil
    end
    if col >= start_col and col <= end_col then
      return target
    end
    init = end_col + 1
  end
end

-- All markdown links in a buffer (file targets only, urls excluded) —
-- the pane's "Links" section.
function M.outgoing(bufnr)
  local found = {}
  local lines = vim.api.nvim_buf_get_lines(bufnr or 0, 0, -1, false)
  for lnum, line in ipairs(lines) do
    for title, target in line:gmatch("%[([^%]]*)%]%(([^%)]+)%)") do
      if not target:match("^%a+://") then
        table.insert(found, { title = title, target = target, lnum = lnum })
      end
    end
  end
  return found
end

-- Absolute path for a link target: vault-rooted when /-relative,
-- base_dir-relative otherwise. Anchors stripped.
function M.resolve_target(target, base_dir)
  target = target:gsub("#.*$", "")
  local path = M.resolve(target)
  if path:sub(1, 1) ~= "/" then
    path = base_dir .. "/" .. path
  end
  return path
end

-- Creation only happens through a real markdown link ("linking births
-- pages"); the bare <cfile> fallback may open things that exist (pasted
-- URLs, literal paths) but never creates — K on a prose word is a no-op,
-- not a junk file. PageFromWord is the deliberate verb for that.
function M.follow()
  local target = M.target_at_cursor()
  local from_link = target ~= nil
  target = target or vim.fn.expand("<cfile>")
  if target == "" then
    return vim.notify("no link under cursor", vim.log.levels.INFO)
  end
  if target:match("^%a+://") then
    return vim.ui.open(target)
  end
  local path = M.resolve_target(target, vim.fn.expand("%:p:h"))
  if vim.fn.filereadable(path) == 0 then
    if not from_link then
      return vim.notify("no link under cursor", vim.log.levels.INFO)
    end
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    vim.fn.writefile({}, path)
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
end

return M
