-- Paste URL -> fetched-<title> markdown link. EXPERIMENT per spec:
-- network fetch on paste, falls back to the raw URL offline; remove if
-- hated. The raw URL lands immediately; the title upgrade arrives async.
local M = {}

local ns = vim.api.nvim_create_namespace("lore_urls")

function M.is_url(text)
  return text:match("^https?://%S+$") ~= nil
end

local ENTITIES = {
  ["&amp;"] = "&",
  ["&lt;"] = "<",
  ["&gt;"] = ">",
  ["&quot;"] = '"',
  ["&#39;"] = "'",
}

function M.title_from_html(html)
  local title = html:match("<[Tt][Ii][Tt][Ll][Ee][^>]*>(.-)</[Tt][Ii][Tt][Ll][Ee]>")
  if not title then
    return nil
  end
  for entity, char in pairs(ENTITIES) do
    title = title:gsub(entity, char)
  end
  title = title:gsub("[%[%]]", "")
  title = vim.trim(title:gsub("%s+", " "))
  if title == "" then
    return nil
  end
  return title
end

local function upgrade_to_link(bufnr, mark, url)
  vim.system(
    { "curl", "-sL", "--max-time", "3", url },
    {},
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        return
      end
      local title = M.title_from_html(result.stdout or "")
      if not title or not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, mark, { details = true })
      if #pos == 0 then
        return
      end
      local row, start_col, details = pos[1], pos[2], pos[3]
      local ok, current = pcall(
        vim.api.nvim_buf_get_text, bufnr, row, start_col, details.end_row, details.end_col, {}
      )
      if not ok or table.concat(current) ~= url then
        return -- the text moved or changed under us; leave it alone
      end
      vim.api.nvim_buf_set_text(bufnr, row, start_col, details.end_row, details.end_col, {
        ("[%s](%s)"):format(title, url),
      })
      vim.api.nvim_buf_del_extmark(bufnr, ns, mark)
    end)
  )
end

function M.paste()
  local register = vim.v.register
  local text = vim.trim(vim.fn.getreg(register) or "")
  if not M.is_url(text) then
    return vim.api.nvim_feedkeys(vim.keycode('"' .. register .. "p"), "n", false)
  end
  vim.api.nvim_put({ text }, "c", true, true)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local start_col = col - #text + 1
  local mark = vim.api.nvim_buf_set_extmark(0, ns, row - 1, start_col, {
    end_col = col + 1,
  })
  upgrade_to_link(vim.api.nvim_get_current_buf(), mark, text)
end

return M
