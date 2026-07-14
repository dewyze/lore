-- Vault autosave + auto-commit. Idle pauses (CursorHold/I) are the
-- boundaries: they subsume FocusLost (switching apps stops input, so
-- CursorHold fires seconds later) and, unlike a bare timer, never land
-- mid-word. Every pause writes buffers (obsidian-style autosave); commits
-- ride the same pauses through a debounce, with a VimLeavePre backstop —
-- lore is a persistent instance, quit is rare. Commit-always is what the
-- todo-age git blame needs; nobody reads a private vault's log, so
-- messages are timestamps.
local preferences = require("lore.preferences")
local vaults = require("lore.vaults")

local M = {}

local DEFAULT_DEBOUNCE_MINUTES = 15

local last_commit = {}

local function run(args, cwd)
  return vim.system(args, { cwd = cwd }):wait()
end

local function dirty(path)
  local result = run({ "git", "status", "--porcelain" }, path)
  return result.code == 0 and result.stdout ~= ""
end

-- Commit everything pending in one vault. Commits disk state only —
-- unsaved buffer edits ride a later commit.
function M.commit(path)
  if vim.fn.isdirectory(path .. "/.git") == 0 then
    return false
  end
  if not dirty(path) then
    return false
  end
  run({ "git", "add", "-A" }, path)
  local result = run({ "git", "commit", "-m", "auto: " .. os.date("%Y-%m-%d %H:%M:%S") }, path)
  return result.code == 0
end

local function debounce_seconds()
  local minutes = tonumber(preferences.get("autocommit_minutes")) or DEFAULT_DEBOUNCE_MINUTES
  return minutes * 60
end

-- All registered vaults (not just the active one — a vault switch must not
-- strand uncommitted work), debounced per vault on actual commits.
function M.commit_all(opts)
  opts = opts or {}
  local now = os.time()
  for _, vault in ipairs(vaults.list()) do
    if opts.force or now - (last_commit[vault.path] or 0) >= debounce_seconds() then
      if M.commit(vault.path) then
        last_commit[vault.path] = now
      end
    end
  end
end

-- Test hook: clear debounce state.
function M.reset()
  last_commit = {}
end

-- One pause boundary: write everything, then maybe commit. noautocmd so
-- autosave is pure persistence — no write-hook side effects. (Renumbering
-- rides BufLeave, not writes.)
function M.checkpoint(opts)
  vim.cmd("silent! noautocmd wall")
  M.commit_all(opts)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("lore_git", {})
  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    group = group,
    callback = function()
      M.checkpoint()
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.checkpoint({ force = true })
    end,
  })
end

return M
