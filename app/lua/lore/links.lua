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

function M.follow()
  local target = M.target_at_cursor() or vim.fn.expand("<cfile>")
  if target == "" then
    return
  end
  if target:match("^%a+://") then
    return vim.ui.open(target)
  end
  target = target:gsub("#.*$", "") -- strip anchors
  local path = M.resolve(target)
  if path:sub(1, 1) ~= "/" then
    path = vim.fn.expand("%:p:h") .. "/" .. path
  end
  if vim.fn.filereadable(path) == 0 then
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    vim.fn.writefile({}, path)
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
end

return M
