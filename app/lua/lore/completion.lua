-- [[ page completion, native ins-completion (the plugin budget carries no
-- completion engine). Typing [[ in a markdown buffer pops vault pages;
-- accepting rewrites the [[word into a standard [Title](/path.md) link —
-- the trigger is Obsidian muscle memory, the output stays OKF-standard.
--
-- The list is served through 'completefunc' rather than a one-shot
-- complete() call: nvim re-invokes the function every time the leader
-- changes, so backspacing a typo re-opens the popup. A complete() list
-- ends for good the moment the leader matches nothing.
local pages = require("lore.pages")
local vaults = require("lore.vaults")

local M = {}

-- byte col of the first "[" while a completion is in flight
local pending = nil
-- pages for the completion in flight; one rg per [[, not per keystroke
local cache = nil

function M.pages()
  local vault = vaults.active()
  if not vault then
    return {}
  end
  -- Meetings are held back at the rg level: date-prefixed and unbounded,
  -- they crowd out the pages worth linking to. Reaching one is a gf or
  -- picker job, not a mid-sentence one. The leading **/ catches a
  -- project's own meetings/ as well as the vault-root folder.
  local result = vim.system({
    "rg",
    "--files",
    "--glob",
    "*.md",
    "--glob",
    "!**/meetings/**",
  }, { cwd = vault.path }):wait()
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

-- 0-based byte col of the "[[" opening an unfinished link before col, or
-- nil. Link brackets never nest, so the nearest unclosed pair is the one
-- being typed into.
function M.link_start(line, col)
  local open = line:sub(1, col):find("%[%[[^%[%]]*$")
  return open and open - 1 or nil
end

-- 'completefunc'. Always answers with the whole page list and lets nvim
-- filter ('completeopt' carries fuzzy) — that way a leader matching
-- nothing is one keystroke from matching again.
function M.completefunc(findstart, _base)
  if findstart == 1 then
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local start_col = M.link_start(line, col)
    if not start_col then
      return -3 -- cancel silently, leave completion mode
    end
    pending = start_col
    return start_col + 2 -- the leader begins just past the "[["
  end
  cache = cache or M.pages()
  return cache
end

function M.on_complete_done()
  local start_col = pending
  pending, cache = nil, nil
  if not start_col then
    return
  end
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
