-- Maps a palette onto highlight groups (the dotfiles palette/apply.lua
-- pattern, aimed at lore's surfaces: markdown, the Lore* groups, floats,
-- embedded code). Palettes supply colors; this file decides where they
-- go. Swapping the palette restyles everything without touching this
-- mapping.
return function(p)
  vim.o.background = p.mode
  vim.cmd.highlight("clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  vim.g.colors_name = p.name

  -- Optional washes: faint tinted panels behind data tokens (wisp's trick).
  local wash = p.wash or {}

  local function hl(group, spec)
    vim.api.nvim_set_hl(0, group, spec)
  end

  -- UI
  hl("Normal", { fg = p.fg, bg = p.bg })
  hl("NormalFloat", { fg = p.fg, bg = p.line })
  hl("FloatBorder", { fg = p.dim, bg = p.line })
  hl("FloatTitle", { fg = p.heading, bg = p.line, bold = true })
  hl("CursorLine", { bg = p.line })
  hl("CursorLineNr", { fg = p.heading })
  hl("LineNr", { fg = p.dim })
  hl("Visual", { bg = p.selection })
  hl("Search", { fg = p.bg, bg = p.warn })
  hl("IncSearch", { fg = p.bg, bg = p.code })
  hl("CurSearch", { link = "IncSearch" })
  hl("MatchParen", { bg = p.selection, bold = true })
  hl("StatusLine", { fg = p.fg, bg = p.line })
  hl("StatusLineNC", { fg = p.dim, bg = p.line })
  hl("WinSeparator", { fg = p.line })
  hl("Pmenu", { fg = p.fg, bg = p.line })
  hl("PmenuSel", { bg = p.selection, bold = true })
  hl("PmenuThumb", { bg = p.dim })
  hl("Folded", { fg = p.dim, bg = p.line })
  hl("NonText", { fg = p.selection })
  hl("Whitespace", { fg = p.selection })
  hl("SpecialKey", { fg = p.selection })
  hl("Directory", { fg = p.link })
  hl("Title", { fg = p.heading, bold = true })
  hl("Comment", { fg = p.dim, italic = true })
  hl("ErrorMsg", { fg = p.bg, bg = p.blocked, bold = true })
  hl("WarningMsg", { fg = p.warn })
  hl("ModeMsg", { fg = p.dim })
  hl("MoreMsg", { fg = p.prog })
  hl("Question", { fg = p.prog })
  hl("Conceal", { fg = p.dim })

  -- Diagnostics (semantic, sparse use)
  hl("DiagnosticError", { fg = p.blocked })
  hl("DiagnosticWarn", { fg = p.warn })
  hl("DiagnosticInfo", { fg = p.prog })
  hl("DiagnosticHint", { fg = p.dim })

  -- Syntax basics (embedded code fences)
  hl("String", { fg = p.str })
  hl("Character", { fg = p.str })
  hl("Keyword", { fg = p.kw })
  hl("Statement", { fg = p.kw })
  hl("Conditional", { fg = p.kw })
  hl("Repeat", { fg = p.kw })
  hl("Operator", { fg = p.fg })
  hl("Delimiter", { fg = p.dim })
  hl("Constant", { fg = p.num })
  hl("Number", { fg = p.num })
  hl("Boolean", { fg = p.num })
  hl("Function", { fg = p.link })
  hl("Identifier", { fg = p.fg })
  hl("Type", { fg = p.heading })
  hl("Special", { fg = p.code })
  hl("PreProc", { fg = p.key })
  hl("Todo", { fg = p.warn, bold = true })
  hl("Error", { fg = p.blocked })

  -- Markdown (treesitter captures)
  for level = 1, 6 do
    hl("@markup.heading." .. level .. ".markdown", { fg = p.heading, bold = true })
  end
  hl("@markup.heading", { fg = p.heading, bold = true })
  hl("@markup.link.label", { fg = p.link, underline = true })
  hl("@markup.link", { fg = p.link })
  hl("@markup.link.url", { fg = p.dim })
  hl("@markup.raw", { fg = p.code, bg = wash.code })
  hl("@markup.raw.block", { fg = p.fg })
  hl("@markup.strong", { bold = true })
  hl("@markup.italic", { italic = true })
  hl("@markup.strikethrough", { strikethrough = true })
  hl("@markup.quote", { fg = p.dim, italic = true })
  hl("@markup.list", { fg = p.dim })
  hl("@markup.list.checked", { fg = p.dim })
  hl("@markup.list.unchecked", { fg = p.fg })
  hl("@punctuation.special.markdown", { fg = p.dim })

  -- YAML frontmatter (injected)
  hl("@property.yaml", { fg = p.key })
  hl("@string.yaml", { fg = p.fg })
  hl("@punctuation.delimiter.yaml", { fg = p.dim })

  -- snacks picker: Dir links to NonText by default, which we map to the
  -- selection color — unreadable on the selected row. Give it real ink.
  hl("SnacksPickerDir", { fg = p.dim })

  -- :terminal ANSI palette. Without these, GUI nvim paints its neon
  -- built-in defaults (a terminal host would supply its own; neovide
  -- can't). Brights mirror normals — this is a muted world.
  local ansi = {
    [0] = p.mode == "dark" and p.line or p.fg, -- black
    [1] = p.blocked, -- red
    [2] = p.str, -- green
    [3] = p.warn, -- yellow
    [4] = p.link, -- blue
    [5] = p.key, -- magenta
    [6] = p.prog, -- cyan
    [7] = p.mode == "dark" and p.fg or p.line, -- white
  }
  for i = 0, 7 do
    vim.g["terminal_color_" .. i] = ansi[i]
    vim.g["terminal_color_" .. (i + 8)] = ansi[i]
  end

  -- lore's own surfaces
  hl("LoreCheckboxInProgress", { fg = p.prog, bold = true })
  hl("LoreCheckboxBlocked", { fg = p.blocked, bold = true })
  hl("LoreTag", { fg = p.tag, bg = wash.tag })
  hl("LoreDueWarn", { fg = p.warn, bg = wash.due })
  hl("LoreDueUrgent", { fg = p.urgent, bg = wash.due })
  hl("LoreDueOverdue", { fg = p.bg, bg = p.over, bold = true })
end
