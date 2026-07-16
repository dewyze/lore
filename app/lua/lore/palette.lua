-- Command palette (vimoire's pattern): a curated list — it controls
-- ordering and display names — over snacks.picker. Entries are full
-- command strings, so argument-carrying variants get their own rows.
local M = {}

local COMMANDS = {
  -- Find / Search
  { cmd = "Files", display = "Find > Files" },
  { cmd = "Tags", display = "Find > Tags" },
  { cmd = "Due", display = "Find > Due" },
  { cmd = "Grep", display = "Search > Grep" },
  { cmd = "GrepWord", display = "Search > Word Under Cursor" },

  -- New
  { cmd = "NewPage", display = "New > Note" },
  { cmd = "NewPage ideas/", display = "New > Idea" },
  { cmd = "NewPage contacts/", display = "New > Contact" },
  { cmd = "NewMeeting", display = "New > Meeting" },
  { cmd = "NewPage projects/", display = "New > Project" },
  { cmd = "NewProjectFile", display = "New > File Under Project" },
  { cmd = "NewPagePick", display = "New > Page In Folder…" },
  { cmd = "PageFromSelection", display = "New > Page From Selection" },
  { cmd = "PageFromWord", display = "New > Page From Word" },

  -- Go
  { cmd = "OpenTodo", display = "Go > Todo" },
  { cmd = "OpenInbox", display = "Go > Inbox" },

  -- Todo
  { cmd = "TodoSort", display = "Todo > Sort" },
  { cmd = "TodoArchive", display = "Todo > Archive Done" },
  { cmd = "CheckboxCycle", display = "Todo > Cycle Checkbox" },
  { cmd = "CheckboxSet blocked", display = "Todo > Set Blocked" },

  -- Buffer
  { cmd = "Template", display = "Buffer > Apply Template" },
  { cmd = "Frontmatter", display = "Buffer > Frontmatter" },
  { cmd = "Renumber", display = "Buffer > Renumber Lists" },

  -- Capture (append + stay)
  { cmd = "Inbox", display = "Capture > Thought (inbox)" },
  { cmd = "TodoAdd", display = "Capture > Todo" },

  -- Vault
  { cmd = "VaultSwitch", display = "Vault > Switch" },
  { cmd = "VaultList", display = "Vault > List" },

  -- View
  { cmd = "Tree", display = "View > File Tree" },
  { cmd = "Pane", display = "View > Links Pane" },
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
