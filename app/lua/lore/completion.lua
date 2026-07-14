-- [[ page completion, native ins-completion (the plugin budget carries no
-- completion engine). Typing [[ in a markdown buffer pops vault pages;
-- accepting rewrites the [[word into a standard [Title](/path.md) link —
-- the trigger is Obsidian muscle memory, the output stays OKF-standard.
local pages = require("lore.pages")
local vaults = require("lore.vaults")

local M = {}

-- byte col of the first "[" while a completion is in flight
local pending = nil

function M.pages()
  local vault = vaults.active()
  if not vault then
    return {}
  end
  local result = vim.system({ "rg", "--files", "--glob", "*.md" }, { cwd = vault.path }):wait()
  if result.code ~= 0 then
    return {}
  end
  local items = {}
  for _, relative in ipairs(vim.split(result.stdout or "", "\n", { trimempty = true })) do
    local stem = vim.fn.fnamemodify(relative, ":t:r")
    table.insert(items, {
      word = stem,
      menu = "/" .. relative,
      user_data = { lore = { path = "/" .. relative, title = pages.title(stem) } },
    })
  end
  table.sort(items, function(a, b)
    return a.word < b.word
  end)
  return items
end

-- Rewrite "[[<word>" (from start_col to the cursor) into the final link.
function M.finish(start_col, data)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local link = ("[%s](%s)"):format(data.title, data.path)
  vim.api.nvim_buf_set_text(0, row - 1, start_col, row - 1, col, { link })
  vim.api.nvim_win_set_cursor(0, { row, start_col + #link })
end

-- insert-mode [[ handler: insert the brackets, then pop the page list
function M.trigger()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { "[[" })
  vim.api.nvim_win_set_cursor(0, { row, col + 2 })
  local items = M.pages()
  if #items == 0 then
    return
  end
  pending = col
  vim.fn.complete(col + 3, items) -- 1-based, just past the "[["
end

function M.on_complete_done()
  if not pending then
    return
  end
  local start_col = pending
  pending = nil
  local completed = vim.v.completed_item
  local data = type(completed) == "table"
    and type(completed.user_data) == "table"
    and completed.user_data.lore
  if data then
    M.finish(start_col, data)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("CompleteDone", {
    group = vim.api.nvim_create_augroup("lore_completion", {}),
    callback = M.on_complete_done,
  })
end

return M
