-- Thin dispatch onto snacks.picker, always scoped to the active vault.
-- Logic lives elsewhere (lore.tags, lore.vaults); this module only builds
-- picker options.
local vaults = require("lore.vaults")
local session = require("lore.session")
local tags = require("lore.tags")

local M = {}

local function active_vault()
  local vault = vaults.active()
  if not vault then
    vim.notify("no active vault — :LoreVaultAdd {name} {path}", vim.log.levels.WARN)
  end
  return vault
end

local function picker()
  return require("snacks").picker
end

function M.files()
  local vault = active_vault()
  if vault then
    picker().files({ cwd = vault.path })
  end
end

function M.grep()
  local vault = active_vault()
  if vault then
    picker().grep({ cwd = vault.path })
  end
end

-- Occurrences of one tag: inline #tag or on a frontmatter tags: line.
function M.grep_tag(tag)
  local vault = active_vault()
  if vault then
    picker().grep({
      cwd = vault.path,
      search = ("#%s\\b|^tags:.*\\b%s\\b"):format(tag, tag),
      live = false,
    })
  end
end

function M.tags()
  local vault = active_vault()
  if not vault then
    return
  end
  local found = tags.collect(vault.path)
  if #found == 0 then
    return vim.notify("no tags in this vault", vim.log.levels.INFO)
  end
  picker()({
    title = "Tags",
    items = vim.tbl_map(function(tag)
      return { text = tag }
    end, found),
    format = "text",
    layout = { preset = "select" },
    confirm = function(p, item)
      p:close()
      M.grep_tag(item.text)
    end,
  })
end

function M.templates()
  local found = require("lore.templates").list()
  if #found == 0 then
    return vim.notify("no templates in this vault (templates/*.md)", vim.log.levels.INFO)
  end
  picker()({
    title = "Templates",
    items = vim.tbl_map(function(path)
      return { text = vim.fn.fnamemodify(path, ":t:r"), file = path, path = path }
    end, found),
    format = "text",
    layout = { preset = "select" },
    confirm = function(p, item)
      p:close()
      require("lore.templates").apply(item.path)
    end,
  })
end

function M.vaults()
  local items = {}
  local active = vaults.active()
  for _, vault in ipairs(vaults.list()) do
    local marker = (active and active.name == vault.name) and "* " or "  "
    table.insert(items, { text = marker .. vault.name .. "  " .. vault.path, name = vault.name })
  end
  if #items == 0 then
    return vim.notify("no vaults registered — :LoreVaultAdd {name} {path}", vim.log.levels.INFO)
  end
  picker()({
    title = "Vaults",
    items = items,
    format = "text",
    layout = { preset = "select" },
    confirm = function(p, item)
      p:close()
      vaults.switch(item.name)
      session.open_vault(vaults.active())
    end,
  })
end

return M
