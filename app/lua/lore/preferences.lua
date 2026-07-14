-- Machine-owned settings store: ~/.lore/preferences.json.
-- Every setting arrives through a :Lore* command; humans never edit this
-- file. (~/.lore/config.lua exists separately, for plugin injection only.)
local M = {}

local DEFAULT_DIR = vim.fn.expand("~/." .. (vim.env.NVIM_APPNAME or "lore"))

local dir = DEFAULT_DIR
local cache = nil

-- Tests point this at a tempdir; set_directory also drops the cache, so
-- calling it with the current dir forces a re-read from disk.
function M.set_directory(d)
  dir = d
  cache = nil
end

function M.reset_directory()
  M.set_directory(DEFAULT_DIR)
end

local function file_path()
  return dir .. "/preferences.json"
end

local function load()
  if cache then
    return cache
  end
  cache = {}
  local file = io.open(file_path(), "r")
  if file then
    local ok, data = pcall(vim.json.decode, file:read("*a"))
    file:close()
    if ok and type(data) == "table" then
      cache = data
    end
  end
  return cache
end

local function save(data)
  vim.fn.mkdir(dir, "p")
  local file = assert(io.open(file_path(), "w"))
  file:write(vim.json.encode(data))
  file:close()
  cache = data
end

function M.get(key)
  local value = load()[key]
  if value == vim.NIL then
    return nil
  end
  return value
end

function M.set(key, value)
  local data = load()
  data[key] = value
  save(data)
end

return M
