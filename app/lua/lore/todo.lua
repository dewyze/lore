-- todo.md machinery: subtree-aware state sort and the archive sweep.
-- Structure comes from treesitter (list_item nodes, so children travel
-- with parents); state comes from the checkbox regex.
local checkbox = require("lore.checkbox")
local vaults = require("lore.vaults")

local M = {}

-- Sort order per spec: [/] -> [ ] -> [!] -> [x] sinks. Dropped sinks past
-- done; plain bullets rank with open todos.
local RANK = { ["/"] = 1, [" "] = 2, ["!"] = 3, ["x"] = 4, ["-"] = 5 }
local DEFAULT_RANK = RANK[" "]

local list_query = vim.treesitter.query.parse("markdown", "(list) @list")

local function nested_in_item(node)
  local parent = node:parent()
  while parent do
    if parent:type() == "list_item" then
      return true
    end
    parent = parent:parent()
  end
  return false
end

-- Top-level lists, each with item segments tiling the list's row span
-- (segment = item start to next item's start, so loose-list blank lines
-- travel with the item above them).
local function top_level_lists(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, "markdown")
  local root = parser:parse()[1]:root()
  local all_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local lists = {}
  for _, node in list_query:iter_captures(root, bufnr) do
    if not nested_in_item(node) then
      local _, _, end_row, end_col = node:range()
      local list_end = end_col > 0 and end_row + 1 or end_row
      -- trailing blanks are the list's separator from what follows, not
      -- cargo of the final item — pin them in place
      while list_end > 0 and (all_lines[list_end] or ""):match("^%s*$") do
        list_end = list_end - 1
      end
      local starts = {}
      for child in node:iter_children() do
        if child:type() == "list_item" then
          table.insert(starts, (child:range()))
        end
      end
      local items = {}
      for i, start_row in ipairs(starts) do
        items[i] = { start_row = start_row, end_row = starts[i + 1] or list_end }
      end
      if #items > 0 then
        table.insert(lists, { start_row = starts[1], end_row = list_end, items = items })
      end
    end
  end
  return lists
end

local function segment(all_lines, item)
  local lines = {}
  for row = item.start_row, item.end_row - 1 do
    table.insert(lines, all_lines[row + 1])
  end
  return lines
end

-- Sort every top-level list by state. Returns whether anything moved.
function M.sort(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local all_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local edits = {}
  for _, list in ipairs(top_level_lists(bufnr)) do
    local decorated = {}
    for index, item in ipairs(list.items) do
      local state = checkbox.state(all_lines[item.start_row + 1])
      decorated[index] = {
        rank = state and RANK[state] or DEFAULT_RANK,
        index = index, -- table.sort is unstable; keep entry order within a state
        item = item,
      }
    end
    table.sort(decorated, function(a, b)
      if a.rank ~= b.rank then
        return a.rank < b.rank
      end
      return a.index < b.index
    end)
    local reordered = {}
    for _, entry in ipairs(decorated) do
      vim.list_extend(reordered, segment(all_lines, entry.item))
    end
    local original = segment(all_lines, list)
    if not vim.deep_equal(original, reordered) then
      table.insert(edits, { list.start_row, list.end_row, reordered })
    end
  end
  table.sort(edits, function(a, b)
    return a[1] > b[1] -- bottom-up so earlier row ranges stay valid
  end)
  for _, edit in ipairs(edits) do
    vim.api.nvim_buf_set_lines(bufnr, edit[1], edit[2], false, edit[3])
  end
  return #edits > 0
end

-- Sweep top-level [x] subtrees into the vault's archive.md under a date
-- heading. Explicit only — items must not vanish unwatched. Done children
-- of unfinished parents stay put.
function M.archive()
  local vault = vaults.active()
  if not vault then
    return vim.notify("no active vault", vim.log.levels.WARN)
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local all_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local removals, archived = {}, {}
  for _, list in ipairs(top_level_lists(bufnr)) do
    for _, item in ipairs(list.items) do
      if checkbox.state(all_lines[item.start_row + 1]) == "x" then
        table.insert(removals, item)
        vim.list_extend(archived, segment(all_lines, item))
      end
    end
  end
  if #removals == 0 then
    return vim.notify("nothing to archive", vim.log.levels.INFO)
  end

  local path = vault.path .. "/archive.md"
  local existing = vim.fn.filereadable(path) == 1 and vim.fn.readfile(path) or {}
  local heading = "## " .. os.date("%Y-%m-%d")
  local last_heading
  for _, line in ipairs(existing) do
    if line:match("^## ") then
      last_heading = line
    end
  end
  if last_heading ~= heading then
    if #existing > 0 then
      table.insert(existing, "")
    end
    table.insert(existing, heading)
    table.insert(existing, "")
  end
  vim.list_extend(existing, archived)
  vim.fn.writefile(existing, path)

  table.sort(removals, function(a, b)
    return a.start_row > b.start_row
  end)
  for _, item in ipairs(removals) do
    vim.api.nvim_buf_set_lines(bufnr, item.start_row, item.end_row, false, {})
  end
  vim.notify(("archived %d item(s)"):format(#removals), vim.log.levels.INFO)
end

-- Sort triggers: explicit command plus BufLeave (tidy on return, never
-- moves under the cursor) with a QuitPre companion (BufLeave doesn't fire
-- on all quit paths). Writes only when the sort itself changed the buffer.
function M.setup()
  vim.api.nvim_create_autocmd({ "BufLeave", "QuitPre" }, {
    group = vim.api.nvim_create_augroup("lore_todo", {}),
    pattern = "*/todo.md",
    callback = function(event)
      if M.sort(event.buf) then
        vim.api.nvim_buf_call(event.buf, function()
          vim.cmd("silent! update")
        end)
      end
    end,
  })
end

return M
