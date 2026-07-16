-- List continuation, tada-style: Enter/o/O repeat the list marker.
-- Continuation from any checkbox state inserts a fresh "[ ]" — new items
-- are born todo, state is never cloned.
local M = {}

local function parse(line)
  local indent, bullet, rest = line:match("^(%s*)([-*+])%s+(.*)$")
  local number, sep
  if not indent then
    indent, number, sep, rest = line:match("^(%s*)(%d+)([.)])%s+(.*)$")
  end
  if not indent then
    return nil
  end
  local box, content = rest:match("^%[(.)%]%s?(.*)$")
  return {
    indent = indent,
    bullet = bullet,
    number = tonumber(number),
    sep = sep,
    box = box,
    content = content or rest,
  }
end

-- The marker a new item under `line` should start with, or nil if `line`
-- is not a list item.
function M.next_marker(line)
  local item = parse(line)
  if not item then
    return nil
  end
  local marker
  if item.number then
    marker = item.indent .. (item.number + 1) .. item.sep .. " "
  else
    marker = item.indent .. item.bullet .. " "
  end
  if item.box then
    marker = marker .. "[ ] "
  end
  return marker
end

local function is_empty_item(line)
  local item = parse(line)
  return item ~= nil and item.content == ""
end

local function feed(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "n", false)
end

-- <CR> in insert mode.
function M.press_enter()
  local line = vim.api.nvim_get_current_line()
  local marker = M.next_marker(line)
  if not marker then
    return feed("<CR>")
  end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  if is_empty_item(line) then
    -- Enter on an empty item ends the list: clear the marker.
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, { "" })
    vim.api.nvim_win_set_cursor(0, { row, 0 })
    return
  end
  -- 0-based cursor col == chars before the insertion point in insert mode
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before, after = line:sub(1, col), line:sub(col + 1)
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { before, marker .. after })
  vim.api.nvim_win_set_cursor(0, { row + 1, #marker })
end

local function open_at(row_offset)
  local line = vim.api.nvim_get_current_line()
  local marker = M.next_marker(line)
  if not marker then
    return feed(row_offset == 0 and "O" or "o")
  end
  if row_offset == 0 then
    -- Items opened above keep the neighbour's numbering, not +1.
    local item = parse(line)
    if item.number then
      marker = marker:gsub("%d+", tostring(item.number), 1)
    end
  end
  local row = vim.api.nvim_win_get_cursor(0)[1] + row_offset - 1
  vim.api.nvim_buf_set_lines(0, row, row, false, { marker })
  vim.api.nvim_win_set_cursor(0, { row + 1, #marker })
  vim.cmd("startinsert!")
end

function M.open_below()
  open_at(1)
end

function M.open_above()
  open_at(0)
end

local renumber_query = vim.treesitter.query.parse("markdown", "(list) @list")

-- Renumber every ordered list (nested included — each treesitter list
-- node is its own sequence), anchored on its first item's number.
-- Returns whether anything changed. Runs on BufLeave/QuitPre (attention
-- boundaries, like todo sort) + :Renumber. Number tokens are
-- structure, not speech — this augments, it never rewords.
function M.renumber(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(bufnr, "markdown")
  local root = parser:parse()[1]:root()
  local changed = false
  for _, node in renumber_query:iter_captures(root, bufnr) do
    local counter = nil
    for child in node:iter_children() do
      if child:type() == "list_item" then
        local row = child:range()
        local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
        local indent, number, rest = line:match("^(%s*)(%d+)([.)].*)$")
        if number then
          counter = counter and counter + 1 or tonumber(number)
          if tonumber(number) ~= counter then
            vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, { indent .. counter .. rest })
            changed = true
          end
        end
      end
    end
  end
  return changed
end

-- Insert-mode <Tab>/<S-Tab>: indent/dedent on a list item, literal elsewhere.
function M.tab()
  if parse(vim.api.nvim_get_current_line()) then
    return "<C-t>"
  end
  return "<Tab>"
end

function M.shift_tab()
  if parse(vim.api.nvim_get_current_line()) then
    return "<C-d>"
  end
  return "<S-Tab>"
end

-- Renumber when attention leaves the buffer — tidy on return, never
-- moves text under an active cursor. QuitPre companion because BufLeave
-- doesn't fire on all quit paths.
function M.setup()
  vim.api.nvim_create_autocmd({ "BufLeave", "QuitPre" }, {
    group = vim.api.nvim_create_augroup("lore_lists", {}),
    pattern = "*.md",
    callback = function(event)
      if M.renumber(event.buf) then
        vim.api.nvim_buf_call(event.buf, function()
          vim.cmd("silent! update")
        end)
      end
    end,
  })
end

return M
