-- Plugin setup calls. Specs/versions live in config/pack.lua.
require("snacks").setup({
  picker = { enabled = true },
  input = { enabled = true },
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
