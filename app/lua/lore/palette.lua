-- Command palette (vimoire's pattern): a curated list — it controls
-- ordering and display names — over snacks.picker. Entries are full
-- command strings, so argument-carrying variants get their own rows.
local M = {}

local COMMANDS = {
  -- Find
  { cmd = "LoreFiles", display = "Find > Files" },
  { cmd = "LoreGrep", display = "Find > Grep" },
  { cmd = "LoreTags", display = "Find > Tags" },
  { cmd = "LorePane", display = "Find > Links Pane" },

  -- New
  { cmd = "LoreNewPage", display = "New > Page" },
  { cmd = "LorePageFromSelection", display = "New > Page From Selection" },

  -- Todo
  { cmd = "LoreTodoSort", display = "Todo > Sort" },
  { cmd = "LoreTodoArchive", display = "Todo > Archive Done" },
  { cmd = "LoreCheckboxCycle", display = "Todo > Cycle Checkbox" },
  { cmd = "LoreCheckboxSet blocked", display = "Todo > Set Blocked" },
  { cmd = "LoreCheckboxSet dropped", display = "Todo > Set Dropped" },

  -- Buffer
  { cmd = "LoreTemplate", display = "Buffer > Apply Template" },
  { cmd = "LoreFrontmatter", display = "Buffer > Frontmatter" },
  { cmd = "LoreRenumber", display = "Buffer > Renumber Lists" },

  -- Capture
  { cmd = "LoreInbox", display = "Capture > Inbox" },

  -- Vault
  { cmd = "LoreVaultSwitch", display = "Vault > Switch" },
  { cmd = "LoreVaultList", display = "Vault > List" },

  -- View
  { cmd = "LoreTree", display = "View > File Tree" },
}

local function keymap_for(command)
  for _, mode in ipairs({ "n", "x" }) do
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      if map.rhs and map.rhs == ("<Cmd>%s<CR>"):format(command) then
        return map.lhs
      end
    end
  end
  return nil
end

function M.items()
  local existing = vim.api.nvim_get_commands({})
  local items = {}
  for _, entry in ipairs(COMMANDS) do
    local name = entry.cmd:match("^(%S+)")
    if existing[name] then
      table.insert(items, {
        text = entry.display,
        cmd = entry.cmd,
        keymap = keymap_for(entry.cmd),
      })
    end
  end
  return items
end

function M.open()
  require("snacks").picker({
    title = "Commands",
    items = M.items(),
    layout = { preset = "select" },
    format = function(item)
      local parts = { { item.text, "Normal" } }
      if item.keymap then
        table.insert(parts, { "  " .. item.keymap, "Comment" })
      end
      return parts
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.schedule(function()
          vim.cmd(item.cmd)
        end)
      end
    end,
  })
end

return M
