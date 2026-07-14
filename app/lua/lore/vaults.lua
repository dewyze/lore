-- The vault registry. Lives in preferences.json ({ name = path }), managed
-- entirely by commands. Exactly one active vault at a time; everything in
-- lore scopes to it.
local preferences = require("lore.preferences")

local M = {}

local SCAFFOLD = { "inbox.md", "todo.md", "archive.md" }

local function registry()
  return preferences.get("vaults") or {}
end

local function scaffold(path)
  vim.fn.mkdir(path, "p")
  for _, name in ipairs(SCAFFOLD) do
    local file = path .. "/" .. name
    if vim.fn.filereadable(file) == 0 then
      vim.fn.writefile({}, file)
    end
  end
  if vim.fn.isdirectory(path .. "/.git") == 0 then
    vim.system({ "git", "init" }, { cwd = path }):wait()
  end
end

function M.add(name, path)
  local vaults = registry()
  if vaults[name] then
    error(("vault %q is already registered"):format(name))
  end
  path = vim.fs.normalize((vim.fn.fnamemodify(vim.fn.expand(path), ":p"):gsub("/$", "")))
  scaffold(path)
  vaults[name] = path
  preferences.set("vaults", vaults)
  if not preferences.get("active_vault") then
    preferences.set("active_vault", name)
  end
end

function M.list()
  local items = {}
  for name, path in pairs(registry()) do
    table.insert(items, { name = name, path = path })
  end
  table.sort(items, function(a, b)
    return a.name < b.name
  end)
  return items
end

function M.switch(name)
  if not registry()[name] then
    error(("unknown vault %q"):format(name))
  end
  preferences.set("active_vault", name)
end

function M.active()
  local name = preferences.get("active_vault")
  local path = name and registry()[name]
  if not path then
    return nil
  end
  return { name = name, path = path }
end

return M
