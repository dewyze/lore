-- The default. Nightshade's ground and hues plus washes — inline code,
-- tags, and due dates sit on faint tinted panels instead of relying on
-- ink alone. Ported from dotfiles.
return {
  name = "wisp",
  mode = "dark",

  bg = "#303030",
  line = "#3a3a3a",
  selection = "#585858",
  fg = "#ebedec",
  dim = "#969896",

  heading = "#f0c674",
  link = "#81a2be",
  tag = "#8abeb7",
  code = "#de935f",
  key = "#b294bb",

  str = "#8abd7a",
  kw = "#b294bb",
  num = "#de935f",

  prog = "#8abeb7",
  blocked = "#cc6666",
  warn = "#f0c674",
  urgent = "#cc6666",
  over = "#cc6666",

  wash = {
    code = "#3a4231",
    tag = "#333d48",
    due = "#35423e",
  },
}
