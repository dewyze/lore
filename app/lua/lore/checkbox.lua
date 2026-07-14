-- Checkbox states. [ ] todo and [x] done are universal GFM; [/] in-progress,
-- [!] blocked, [-] dropped are lore's convention, rendered only here.
-- treesitter can't see the custom states (no node exists for them), so
-- detection is regex and highlighting is matchadd — the sanctioned "regex
-- where treesitter can't" exception.
local M = {}

-- Cycle: [ ] -> [/] -> [x] -> [ ]. Blocked/dropped are asserted states, not
-- cycle steps; cycling from them returns to todo.
local CYCLE = { [" "] = "/", ["/"] = "x" }

local STATES = { [" "] = true, ["/"] = true, ["x"] = true, ["!"] = true, ["-"] = true }

-- "- [x] text" / "  * [/] text" / "3. [ ] text"
local BOX_PATTERNS = {
  "^(%s*[-*+]%s+)%[(.)%](.*)$",
  "^(%s*%d+[.)]%s+)%[(.)%](.*)$",
}
-- "- text" / "3. text" (no checkbox yet)
local LIST_PATTERNS = {
  "^(%s*[-*+]%s+)(.*)$",
  "^(%s*%d+[.)]%s+)(.*)$",
}

local function with_state(line, state)
  for _, pattern in ipairs(BOX_PATTERNS) do
    local prefix, _, rest = line:match(pattern)
    if prefix then
      return prefix .. "[" .. state .. "]" .. rest
    end
  end
  for _, pattern in ipairs(LIST_PATTERNS) do
    local prefix, content = line:match(pattern)
    if prefix then
      return prefix .. "[" .. state .. "] " .. content
    end
  end
  return nil
end

-- The state char of a checkbox line, or nil (also consumed by todo sort).
function M.state(line)
  for _, pattern in ipairs(BOX_PATTERNS) do
    local _, state = line:match(pattern)
    if state then
      return state
    end
  end
  return nil
end

function M.cycle()
  local line = vim.api.nvim_get_current_line()
  local state = M.state(line)
  local next_state = state and (CYCLE[state] or " ") or " "
  local updated = with_state(line, next_state)
  if updated then
    vim.api.nvim_set_current_line(updated)
  end
end

function M.set(state)
  if not STATES[state] then
    error(("unknown checkbox state %q"):format(state))
  end
  local updated = with_state(vim.api.nvim_get_current_line(), state)
  if updated then
    vim.api.nvim_set_current_line(updated)
  end
end

-- Highlighting: window-local matches, reapplied on WinEnter (a buffer moved
-- to a new window would otherwise lose them).
local MATCHES = {
  { "LoreCheckboxInProgress", [=[\v^\s*([-*+]|\d+[.)])\s+\zs\[\/\]]=] },
  { "LoreCheckboxBlocked", [=[\v^\s*([-*+]|\d+[.)])\s+\zs\[!\]]=] },
  { "LoreCheckboxDropped", [=[\v^\s*([-*+]|\d+[.)])\s+\zs\[-\]]=] },
}

local function apply_matches()
  if vim.bo.filetype ~= "markdown" or vim.w.lore_checkbox_matches then
    return
  end
  for _, match in ipairs(MATCHES) do
    vim.fn.matchadd(match[1], match[2])
  end
  vim.w.lore_checkbox_matches = true
end

function M.setup()
  vim.api.nvim_set_hl(0, "LoreCheckboxInProgress", { link = "DiagnosticInfo", default = true })
  vim.api.nvim_set_hl(0, "LoreCheckboxBlocked", { link = "DiagnosticError", default = true })
  vim.api.nvim_set_hl(0, "LoreCheckboxDropped", { link = "Comment", default = true })

  vim.api.nvim_create_autocmd({ "FileType", "WinEnter" }, {
    group = vim.api.nvim_create_augroup("lore_checkbox", {}),
    callback = apply_matches,
  })
end

return M
