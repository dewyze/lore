-- Plugin setup calls. Specs/versions live in config/pack.lua.
require("snacks").setup({
  picker = { enabled = true },
  input = { enabled = true },
})

-- Rendering only. Every override below cedes something back to lore,
-- which owns list behavior and checkbox state.
require("render-markdown").setup({
  -- lore's contract is conceallevel 2 with the cursor line revealing raw
  -- (after/ftplugin/markdown.lua); the plugin would force 3.
  win_options = { conceallevel = { rendered = 2 } },
  -- [/] and [!] have no treesitter node, so lore highlights all four
  -- states by matchadd (lore/checkbox.lua). Letting the plugin render
  -- [ ]/[x] too would style the same brackets twice, and its custom-state
  -- path competes with the shortcut-link unconceal in config/treesitter.
  checkbox = { enabled = false },
  -- signcolumn is "auto", so plugin signs would pop a column into every
  -- markdown buffer and shift the text sideways.
  heading = { sign = false },
  code = { sign = false },
})

require("neo-tree").setup({
  window = {
    mappings = {
      -- stock quick_jump sits on <C-s> (nowait), which would eat the
      -- C-s drawer chord inside the tree; move it to C-j
      ["<C-s>"] = "none",
      ["<C-j>"] = {
        "quick_jump",
        config = {
          on_jump = "open_or_toggle",
          jump_labels = "jfkdlsahgnuvrbytmiceoxwpqz",
        },
      },
    },
  },
})
