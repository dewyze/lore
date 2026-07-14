-- The links + backlinks pane. One pane, two sections: Links (outgoing,
-- parsed from the context buffer) and Backlinks (inbound, live rg). The
-- pane is a view, not a navigator — it holds no state of its own; Enter
-- edits in the target window so the jumplist accrues there naturally.
--
-- Sprawl alarm (spec): if metadata columns or truncation rendering appear
-- here, stop.
local backlinks = require("lore.backlinks")
local links = require("lore.links")

local M = {}

local FILETYPE = "lore_pane"
local NAME = "lore://pane"
local WIDTH = 40

local state = {
  buf = nil,
  win = nil,
  context = nil, -- bufnr whose links are shown
  entries = {}, -- pane lnum -> { path, lnum }
}

-- Target window: per-tab MRU stack (neo-tree's pattern, verified in okf).
-- WinEnter pushes; the resolver walks newest-first to the first valid
-- normal window. Self-healing — closed windows fall through.
local prior_windows = {}

local function is_float(win)
  return vim.api.nvim_win_get_config(win).relative ~= ""
end

local function remember_window()
  local win = vim.api.nvim_get_current_win()
  if is_float(win) or vim.bo.filetype == FILETYPE then
    return
  end
  local tab = vim.api.nvim_get_current_tabpage()
  local stack = prior_windows[tab] or {}
  for i, known in ipairs(stack) do
    if known == win then
      table.remove(stack, i)
      break
    end
  end
  table.insert(stack, win)
  prior_windows[tab] = stack
end

function M.target_window()
  local stack = prior_windows[vim.api.nvim_get_current_tabpage()] or {}
  for i = #stack, 1, -1 do
    local win = stack[i]
    if
      vim.api.nvim_win_is_valid(win)
      and not is_float(win)
      and win ~= state.win
      and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ""
    then
      return win
    end
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if not is_float(win) and win ~= state.win and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "" then
      return win
    end
  end
  return nil
end

local function ensure_buf()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    return state.buf
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, NAME)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = FILETYPE
  vim.keymap.set("n", "<CR>", M.open_entry, { buffer = buf, desc = "open entry in target window" })
  state.buf = buf
  return buf
end

local function apply_window_options(win)
  vim.wo[win].winfixwidth = true
  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].foldenable = false
  vim.wo[win].cursorline = true
end

local function vault_relative(path)
  local vault = require("lore.vaults").active()
  if vault then
    return (path:gsub("^" .. vim.pesc(vault.path), ""))
  end
  return path
end

local function render()
  if not (state.win and vim.api.nvim_win_is_valid(state.win)) then
    return
  end
  local context = state.context
  if not (context and vim.api.nvim_buf_is_valid(context)) then
    return
  end
  local file = vim.api.nvim_buf_get_name(context)
  if file == "" then
    return
  end

  local lines, entries = {}, {}
  local base_dir = vim.fn.fnamemodify(file, ":h")

  table.insert(lines, "Links")
  local outgoing = links.outgoing(context)
  if #outgoing == 0 then
    table.insert(lines, "  (none)")
  end
  for _, link in ipairs(outgoing) do
    local display = link.title ~= "" and link.title or link.target
    table.insert(lines, "  " .. display)
    entries[#lines] = { path = links.resolve_target(link.target, base_dir), lnum = 1 }
  end

  table.insert(lines, "")
  table.insert(lines, "Backlinks")
  local inbound = backlinks.find(file)
  if #inbound == 0 then
    table.insert(lines, "  (none)")
  end
  for _, ref in ipairs(inbound) do
    table.insert(lines, ("  %s:%d  %s"):format(vault_relative(ref.file), ref.lnum, ref.text))
    entries[#lines] = { path = ref.file, lnum = ref.lnum }
  end

  local buf = ensure_buf()
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  state.entries = entries
end

function M.open()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    return
  end
  local buf = ensure_buf()
  local current = vim.api.nvim_get_current_win()
  vim.cmd("botright vertical " .. WIDTH .. "split")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, buf)
  apply_window_options(state.win)
  vim.fn.matchadd("Title", [[^\S.*]], 10, -1, { window = state.win })
  vim.api.nvim_set_current_win(current)
  state.context = vim.api.nvim_get_current_buf()
  render()
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    M.close()
  else
    M.open()
  end
end

function M.open_entry()
  local entry = state.entries[vim.api.nvim_win_get_cursor(0)[1]]
  if not entry then
    return
  end
  local target = M.target_window()
  if not target then
    return vim.notify("no window to open in", vim.log.levels.WARN)
  end
  vim.api.nvim_set_current_win(target)
  if vim.fn.filereadable(entry.path) == 0 then
    vim.fn.mkdir(vim.fn.fnamemodify(entry.path, ":h"), "p")
    vim.fn.writefile({}, entry.path)
  end
  vim.cmd.edit(vim.fn.fnameescape(entry.path))
  local last = vim.api.nvim_buf_line_count(0)
  vim.api.nvim_win_set_cursor(0, { math.min(entry.lnum, last), 0 })
end

function M.setup()
  local group = vim.api.nvim_create_augroup("lore_pane", {})
  vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = remember_window,
  })
  -- refresh for the buffer under attention; pane window options are
  -- reapplied here too (the neo-tree protection pattern)
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(event)
      if vim.bo[event.buf].filetype == FILETYPE then
        if state.win and vim.api.nvim_win_is_valid(state.win) then
          apply_window_options(state.win)
        end
        return
      end
      if vim.bo[event.buf].buftype ~= "" or vim.api.nvim_buf_get_name(event.buf) == "" then
        return
      end
      if is_float(vim.api.nvim_get_current_win()) then
        return
      end
      state.context = event.buf
      render()
    end,
  })
end

return M
