-- Todo age: "how long has this been hanging." One git blame call gives
-- every line's last-touched timestamp; an item's age is its most recent
-- touch anywhere in the subtree (a child you edited yesterday means the
-- todo isn't hanging). Display is age-tinted virtual text — position
-- never changes, age never reorders (that's an on-demand sort's job).
local todo = require("lore.todo")

local M = {}

M.namespace = vim.api.nvim_create_namespace("lore_age")

local DAY = 86400

-- Badge tiers; edit and commit. Under MIN_DAYS shows nothing — fresh
-- items need no reminder they exist.
local MIN_DAYS = 2
local TIERS = {
  { days = 21, group = "LoreAgeStale" },
  { days = 7, group = "LoreAgeAging" },
  { days = 0, group = "LoreAgeFresh" },
}

local enabled = true

function M.badge(seconds)
  local days = math.floor(seconds / DAY)
  if days < MIN_DAYS then
    return nil
  end
  local text
  if days >= 60 then
    text = math.floor(days / 30) .. "mo"
  elseif days >= 14 then
    text = math.floor(days / 7) .. "w"
  else
    text = days .. "d"
  end
  for _, tier in ipairs(TIERS) do
    if days >= tier.days then
      return "· " .. text, tier.group
    end
  end
end

-- line (1-based) -> seconds since last touch, from one blame call.
-- Uncommitted lines carry the current time, so they read as fresh.
function M.ages(path)
  local result = vim.system({
    "git",
    "blame",
    "--line-porcelain",
    path,
  }, { cwd = vim.fn.fnamemodify(path, ":h") }):wait()
  if result.code ~= 0 then
    return {}
  end
  local now = os.time()
  local ages, current_line = {}, nil
  for line in (result.stdout or ""):gmatch("[^\n]+") do
    local final = line:match("^%x+ %d+ (%d+)")
    if final then
      current_line = tonumber(final)
    else
      local time = line:match("^committer%-time (%d+)")
      if time and current_line then
        ages[current_line] = math.max(0, now - tonumber(time))
      end
    end
  end
  return ages
end

function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
  if not enabled then
    return
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  -- blame line numbers only align with an unmodified buffer
  if path == "" or vim.bo[bufnr].modified or vim.fn.filereadable(path) == 0 then
    return
  end
  local ages = M.ages(path)
  if vim.tbl_isempty(ages) then
    return
  end
  for _, list in ipairs(todo.lists(bufnr)) do
    for _, item in ipairs(list.items) do
      local newest = math.huge
      for row = item.start_row + 1, item.end_row do
        newest = math.min(newest, ages[row] or math.huge)
      end
      local text, group = M.badge(newest)
      if text then
        vim.api.nvim_buf_set_extmark(bufnr, M.namespace, item.start_row, 0, {
          virt_text = { { text, group } },
          virt_text_pos = "eol",
        })
      end
    end
  end
end

function M.toggle()
  enabled = not enabled
  M.refresh()
end

function M.setup()
  vim.api.nvim_set_hl(0, "LoreAgeFresh", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "LoreAgeAging", { link = "DiagnosticWarn", default = true })
  vim.api.nvim_set_hl(0, "LoreAgeStale", { link = "DiagnosticError", default = true })

  -- CursorHold rather than BufWritePost: autosave writes with noautocmd,
  -- so the idle pause is the reliable "disk is fresh" signal
  vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold" }, {
    group = vim.api.nvim_create_augroup("lore_age", {}),
    pattern = "*/todo.md",
    callback = function(event)
      M.refresh(event.buf)
    end,
  })
end

return M
