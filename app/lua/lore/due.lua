-- @due(YYYY-MM-DD) — the one inline field (tada's sole survivor). The
-- tint colors John's own token; the machine adds no text. Escalation is
-- the world's clock, not attention: plain beyond the warn horizon, warm
-- inside it, hot inside the urgent horizon, overdue distinct. Pull only —
-- a deadline that must chase you belongs in Reminders.
local preferences = require("lore.preferences")
local vaults = require("lore.vaults")

local M = {}

M.namespace = vim.api.nvim_create_namespace("lore_due")

local PATTERN = "@due%((%d%d%d%d)%-(%d%d)%-(%d%d)%)"
local RG_PATTERN = [[@due\(\d{4}-\d{2}-\d{2}\)]]

local function horizon(key, default)
  return tonumber(preferences.get(key)) or default
end

-- Whole days from today (negative = past). Noon-to-noon dodges DST.
function M.days_until(year, month, day)
  local target = os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = 12 })
  local now = os.date("*t")
  local today = os.time({ year = now.year, month = now.month, day = now.day, hour = 12 })
  return math.floor((target - today) / 86400)
end

function M.group_for(days_left)
  if days_left < 0 then
    return "LoreDueOverdue"
  end
  if days_left <= horizon("due_urgent_days", 2) then
    return "LoreDueUrgent"
  end
  if days_left <= horizon("due_warn_days", 7) then
    return "LoreDueWarn"
  end
  return nil
end

function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for lnum, line in ipairs(lines) do
    local init = 1
    while true do
      local start_col, end_col, year, month, day = line:find(PATTERN, init)
      if not start_col then
        break
      end
      local group = M.group_for(M.days_until(year, month, day))
      if group then
        vim.api.nvim_buf_set_extmark(bufnr, M.namespace, lnum - 1, start_col - 1, {
          end_col = end_col,
          hl_group = group,
        })
      end
      init = end_col + 1
    end
  end
end

-- Every @due in the vault, soonest first (live rg, no cache).
function M.collect()
  local vault = vaults.active()
  if not vault then
    return {}
  end
  local result = vim.system({
    "rg",
    "--line-number",
    "--no-heading",
    "--no-messages",
    RG_PATTERN,
    vault.path,
  }):wait()
  if result.code ~= 0 then
    return {}
  end
  local found = {}
  for _, line in ipairs(vim.split(result.stdout or "", "\n", { trimempty = true })) do
    local file, lnum, text = line:match("^(.-):(%d+):(.*)$")
    if file then
      local year, month, day = text:match(PATTERN)
      if year then
        table.insert(found, {
          file = file,
          lnum = tonumber(lnum),
          date = ("%s-%s-%s"):format(year, month, day),
          days = M.days_until(year, month, day),
          text = vim.trim(text),
        })
      end
    end
  end
  table.sort(found, function(a, b)
    return a.date < b.date
  end)
  return found
end

function M.view()
  local found = M.collect()
  if #found == 0 then
    return vim.notify("no @due dates in this vault", vim.log.levels.INFO)
  end
  local vault = vaults.active()
  require("snacks").picker({
    title = "Due",
    items = vim.tbl_map(function(entry)
      local when = entry.days < 0 and ("overdue %dd"):format(-entry.days)
        or entry.days == 0 and "today"
        or ("in %dd"):format(entry.days)
      return {
        text = ("%s (%s)  %s:%d  %s"):format(
          entry.date,
          when,
          (entry.file:gsub("^" .. vim.pesc(vault.path) .. "/", "")),
          entry.lnum,
          entry.text
        ),
        entry = entry,
      }
    end, found),
    format = "text",
    layout = { preset = "select" },
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.cmd.edit(vim.fn.fnameescape(item.entry.file))
        vim.api.nvim_win_set_cursor(0, { item.entry.lnum, 0 })
      end
    end,
  })
end

function M.setup()
  vim.api.nvim_set_hl(0, "LoreDueWarn", { link = "DiagnosticWarn", default = true })
  vim.api.nvim_set_hl(0, "LoreDueUrgent", { link = "DiagnosticError", default = true })
  vim.api.nvim_set_hl(0, "LoreDueOverdue", { link = "ErrorMsg", default = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI" }, {
    group = vim.api.nvim_create_augroup("lore_due", {}),
    pattern = "*.md",
    callback = function(event)
      M.refresh(event.buf)
    end,
  })
end

return M
