# lore

**Notes, todos, and the connective tissue between them.** A standalone
Neovim app for keeping a work brain in plain markdown.

> **[screenshot placeholder: neovide window, wisp theme, a meeting note with
> frontmatter, a concealed link, tag chips, and a red overdue `@due` token —
> the links pane open on the right]**

## About This Project

lore is a toy. A lovingly over-engineered, extensively tested toy, built
almost entirely with heavy LLM assistance for exactly one user (me). It's
the sibling of [vimoire](https://github.com/dewyze/vimoire), which does
this same trick for writing fiction — lore does it for the day job:
notes, todos, meetings, and the little threads between them.

The trick: start Neovim (or Neovide) with `NVIM_APPNAME=lore` and it
reads `~/.config/lore` instead of your normal config — a whole separate
editor personality, without touching your real vim.

## Why?

Because every notes app eventually asks you to leave vim, and that's
where they die. GitHub issues died there. Obsidian died there (well, it
also died of plugins). The tools that survived — Reminders, vimoire —
survived by being small, single-purpose, and exactly where the hands
already were.

So: markdown files in a git repo, edited in vim, searched with ripgrep.
Everything else is conveniences stacked on top of things that already
work.

## Features

### Vaults

A vault is a folder of markdown and a git repo. `:VaultAdd ~/vaults/work`
scaffolds it (`inbox.md`, `todo.md`, `archive.md`), git-inits it, and
every picker, grep, and backlink scopes to it. Switch vaults, get a
different brain.

### Capture

Thoughts and todos land without navigation: `\cc` prompts and appends to
`inbox.md`, `\ct` to `todo.md` — from whatever buffer you're in. Visual
mode *moves* the selection there instead. Raycast scripts do the same
from outside vim entirely, including one that turns your current
calendar meeting into a dated, templated meeting note.

### todo.md

Checkboxes with two extra states rendered only here: `[/]` in progress,
`[!]` blocked. `<Space>` cycles. Sort is subtree-aware (children travel
with their parents) and only runs when you ask — your hand-ordering *is*
the priority system. Done items sweep into `archive.md` under a date
stamp.

Deadlines are one inline convention: `@due(2026-08-01)`. The token tints
as the date approaches and inverts when it's past. `:Due` lists every
deadline in the vault, soonest first — meeting notes included.

> **[screenshot placeholder: todo.md — all four checkbox states, a warm
> and a red `@due`, one overdue reverse-block]**

### Links

Standard markdown links, root-relative to the vault. `gf` (or `K`)
follows; if the target doesn't exist yet, it's created — linking to a
page is how pages get born. `[[` completes page names fuzzily and expands
to a full link. A side pane shows the current note's outgoing links and
backlinks (live ripgrep, no cache, no index).

### Themes

A small palette engine and four schemes: **wisp** (the default — code,
tags, and due dates sit on faint tinted washes), **daybreak** (light),
**fathom** (deep-sea cool), **ember** (fire warm). `:Theme ember`
switches and persists.

> **[screenshot placeholder: 2×2 grid of the same note in all four
> themes]**

### The Little Things

- A command palette (`⌘⇧P`) with every command, showing its keybinding.
- Paste a URL in a markdown buffer and it upgrades itself into a
  `[Page Title](url)` link once the fetch returns.
- Ordered lists renumber themselves when you leave the buffer.
- Autosave on idle pauses; auto-commit on a debounce. Your vault's git
  history writes itself, and nobody ever reads it, which is the point.

## Quick Start

```bash
# Clone the repo
git clone https://github.com/dewyze/lore ~/dev/lore

# Symlink the app directory
ln -s ~/dev/lore/app ~/.config/lore

# Add bin to your PATH, or symlink the launcher
ln -s ~/dev/lore/bin/lore /usr/local/bin/lore
```

Then run `lore`, and inside: `:VaultAdd ~/path/to/vault` (or `\va`).
From then on, every launch drops you in `todo.md` of your active vault.

The launcher keeps a single instance: if lore is already running, it
focuses the window instead of starting another.

## Requirements

- Neovim 0.12+
- [ripgrep](https://github.com/BurntSushi/ripgrep) — it *is* the search
- git
- A C compiler (Xcode Command Line Tools on macOS) — treesitter parsers
  compile on first launch
- [Neovide](https://neovide.dev) (recommended; `LORE_EDITOR=nvim` for terminal)
- [ical-buddy](https://hasseg.org/icalBuddy/) (optional, for
  meeting-note capture from your calendar)
- A [Nerd Font](https://www.nerdfonts.com) (for tree icons)

First launch needs the network: plugins clone via `vim.pack` and
treesitter parsers download and build. After that, everything is local.

## Philosophy

- **Markdown is the store.** Human-edited, LLM-readable, script-parseable.
  No database, no cache, no index. If lore vanished tomorrow, the vault
  is still just files.
- **ripgrep is the retrieval floor.** Structure is additive, never
  load-bearing.
- **Automation never rewrites what I said.** Machines may append, manage
  metadata, and restructure without rewording. Anything beyond that, a
  human asked for.
- **Capture is frictionless; organization is optional.** Not deferred —
  optional. A note that never gets filed is still findable.
- **An app for one person.** There is no config surface for hypothetical
  users, and that's a feature.

## Acknowledgments

- [vimoire](https://github.com/dewyze/vimoire) — the older sibling that
  proved the `NVIM_APPNAME` recipe
- [Neovim](https://neovim.io) and [Neovide](https://neovide.dev)
- [snacks.nvim](https://github.com/folke/snacks.nvim) and
  [neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim), the only
  plugins that made the budget

## License

MIT

---

*"The palest ink is better than the best memory."* — proverb

*And `rg` is better than the palest ink.*
