-- Vault auto-commit: attention boundaries (FocusLost, debounced) are the
-- commit boundaries, with a VimLeavePre backstop — lore is a persistent
-- instance, quit is rare. Commit-always is what the todo-age git blame
-- needs; nobody reads a private vault's log, so messages are timestamps.
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

function M.setup()
  local group = vim.api.nvim_create_augroup("lore_git", {})
  vim.api.nvim_create_autocmd("FocusLost", {
    group = group,
    callback = function()
      M.commit_all()
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.commit_all({ force = true })
    end,
  })
end

return M
