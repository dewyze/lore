# lore — Spec

A minimal markdown notes/tracking system for John's principal-engineer role.
Written to be picked up cold by a new LLM session: goals, architecture,
features, mechanics, and what is deliberately NOT being built.

**Standing decisions:**
- Name: **lore** (`NVIM_APPNAME=lore`, socket `/tmp/lore.sock`, launcher
  `bin/lore`, repo `~/dev/lore`).
- Fresh app, **full rewrite**. The existing `okf` app (`~/dev/okf`) is
  *reference only* — reuse its research and behavior designs, not its code.
  Its cache architecture (`.okf/cache.json` + Ruby cache script) is explicitly
  rejected.
- Two repos: the app (`~/dev/lore`) and each vault (its own git repo,
  potentially on different hosts — personal vs enterprise git, NDA/retention
  separation).

## Goals / approach

- **In-flow or it dies.** Everything lives in vim/terminal. (GitHub-issues
  tracking failed purely on being outside vim.)
- **Constraint is the feature.** The tools John loves (Reminders, vimoire) are
  minimal and single-purpose; the ones that failed (Obsidian, Logseq+plugins,
  his own tada/sai) sprawled. Refuse tempting extras.
- **Tool existing habits, not aspirational ones.** Ship the plain version, let
  real friction justify each addition.
- **Determinism from programs, LLM only where grep can't.** Structure is
  additive, never load-bearing. rg is the retrieval floor.
- **No portability layer without a second consumer.** No JSON store. Markdown
  is the store — human-edited, LLM-readable, script-parseable.
- **Capture is frictionless; organization is deferred, not required.**
- **Automation never rewrites what John said.** (Settled 14 Jul 2026,
  replacing a misremembered "nothing acts unasked".) Machines may append,
  manage and augment metadata (frontmatter, tags), and restructure without
  rewording — renumbering rewrites list markers; structure is not speech.
  Anything beyond that, a human asked for. Automation triggers live at
  attention boundaries (idle pauses, BufLeave), never mid-typing.
  (todo sort is user-invoked as of 15 Jul, so it no longer needs an
  automation carve-out at all.)

## Architecture

**App repo** (vimoire/okf shape):

```
~/dev/lore/
  app/              # symlinked → ~/.config/lore/ (NVIM_APPNAME config)
    init.lua
    lua/config/     # options, keymaps, lazy, user commands
    lua/lore/       # the logic (vaults, pane, todo, links, templates)
  bin/lore          # socket-probe launcher
~/.lore/
  config.lua        # optional; bring-your-own-plugins ONLY (vimoire-style);
                    #   never machine-written, never settings
  preferences.json  # machine-owned state: vault registry, active vault,
                    #   options — written only by lore commands
```

**Config is authored via vim commands, never hand-edited.** `preferences.json`
is the single settings store; every knob gets there through a `:Lore*` command.
`config.lua` exists solely for plugin injection (the one job JSON and commands
can't do — vimoire precedent, where John has never once opened the file for
settings). Keymap/option *defaults* are app code — the repo is the app, so
"customizing defaults" means editing the repo and committing.

**Multi-vault:** the vault registry lives in `preferences.json`, managed by
`:LoreVaultAdd` / `:LoreVaultList` / `:LoreVaultSwitch`. Exactly one **active
vault** at a time — every picker, grep, backlink, and pane is scoped to it,
never across; cwd follows the active vault. Switching persists; lore reopens
the last active vault. `:LoreVaultAdd` scaffolds the minimum — `inbox.md`,
`todo.md`, `archive.md` — folders stay born-on-use. No hardcoded paths
anywhere in app code.

**Launcher / lifecycle:** launch on first use (not a login item). Persistent
neovide instance living as a parallel OS window (open alongside coding /
meetings). `bin/lore`: probe `/tmp/lore.sock` with `--remote-expr 1` (a stale
socket after a crash *hangs*; probe before use); alive → `nvim --server ...
--remote <file>` + `:NeovideFocus`; dead → cold-launch neovide with
`--listen`. Config calls `vim.fn.serverstart("/tmp/lore.sock")`. Global
hotkey (Raycast) → launcher. On open, lore shows the active vault's
`todo.md`; with an empty registry (true first launch) it shows a message
directing to `:LoreVaultAdd`. No dashboard in v1 (maybe v2).

## Vault structure & format

```
vault/
  inbox.md          # quick-capture target, append-only (unsorted *lines*)
  todo.md           # work todos (see todo.md spec below)
  archive.md        # done todos, swept from todo.md by explicit command
  notes/            # default birth place for new pages; everything that
                    #   isn't an idea/project/meeting — a home, not a queue
  ideas/            # musings, blog seeds, brainstorming; destination
                    #   (build vs write) is metadata
  projects/         # the spine; one file per project
  meetings/
  templates/        # per-vault templates, plain visible folder
```

- Folders earn existence by *type-at-creation*, not topic. Retrieval is flat
  (rg/fzf). Folders born on use — no contacts/ until a person page is born
  (first 1:1 note), at which point whatever dir is typed gets created.
- **No triage state** (settled 14 Jul 2026, replacing `unsorted/`): pages
  are born in their homes. Retrieval is flat, so shelving has near-zero
  cost of error — a queue of "files needing homes" is a guilt pile with
  no payoff. Folder-targeted creation makes the birth choice one
  keystroke; when unsure, `notes/` *is* the answer, permanently if need be.
- Plain markdown, OKF-flavored: YAML frontmatter + standard markdown links
  (`[Title](/path.md)`), freeform body. No custom filetype.
- **Frontmatter minimum:** nothing required. Meetings get `date:`,
  `attendees:` (plain names, NOT links — machine-filled, zero cost),
  `project:`. `tags:` optional anywhere.
- **Filenames are the fzf retrieval surface.** lowercase snake_case, no
  spaces. Meetings date-prefixed: `2026_07_13_team_sync.md`. Others
  descriptive-stable: `rails_upgrade.md`.
- Checkbox states: `[ ]` todo, `[x]` done (universal GFM); custom convention
  rendered only by lore: `[/]` in progress, `[!]` blocked. (`[-]` dropped
  existed briefly; retired 15 Jul 2026 — unneeded.)

## Creation & templates

Creation and templating are **orthogonal primitives**:

- **Make a file** — via neo-tree (location = tree position), via
  make-page-from-word/selection or new-page command (location = `notes/`
  by default; `:LoreNewPage {folder}/ {title}` targets a folder, created
  if missing, with keybindings per folder — `\nn`/`\ni`/`\np` style), via
  Raycast meeting script (location = `meetings/`, machine-decided).
- **Apply a template** — picker over `templates/`, *inserts into the current
  buffer* with `{{date}}`/`{{title}}` substituted. Works on any empty file
  regardless of where it was born. No folder binding, no path prompts.
  (Optional later: a `default_dir:` frontmatter hint in a template. Not
  structural.)

The Raycast meeting script is the only thing that writes a complete templated
file directly (no human present).

## Features — v1 verb inventory

**Global (outside vim)**
- Open/focus lore (launcher + hotkey)
- Quick-capture → append `inbox.md` (Raycast script, no editor)
- Create meeting note from current calendar event (Raycast script, reads
  calendar via icalBuddy or Raycast API; fills title/date/attendees from
  the meeting template). *Promoted from deferred: it's capture
  infrastructure, same family as inbox quick-add.*

Raycast scripts live in John's separate raycast repo, not here. They write
files; they never commit (see git auto-commit section).

**Vault-level (inside lore)**
- Find file (picker), live grep, tag search (rg over frontmatter/#tags)
- Switch vault (picker; everything rescopes; persists)
- New page → `notes/` by default; folder-targeted variants
- Append to inbox from inside (stray thought without leaving buffer)
- Toggle neo-tree

**Buffer, normal/visual**
- Follow link (`gf`/`gx`); root-relative `/path.md` links need a small
  `includeexpr`; `gf` on a missing file → create it
- Make page from word/selection → create in `notes/`, replace text with link
- Links + backlinks pane (see below)
- Jump to frontmatter (and back)
- Apply template into buffer
- Cycle checkbox state; set `[!]`/`[-]` explicitly
- Heading navigation (`]]`/`[[` next/prev heading)
- Paste URL → fetched-`<title>` markdown link (**experiment** — network
  fetch on paste, falls back to raw URL offline; remove if hated)
- Folding: stock vim folds via treesitter

**Insert mode**
- Link completion: trigger (`[[` per okf's research) → fuzzy page completion →
  inserts standard md link. Fresh implementation; okf's blink.cmp source is
  the reference.
- List continuation (Enter/`o`/`O`) — owned tada-style mappings. (Friction
  named 13 Jul: the options-only route can't continue from `[x]` or custom
  states.) Continuation from any checkbox state inserts a fresh `- [ ]` —
  new items are born todo, state is never cloned. Plain bullets repeat,
  ordered items increment, Enter on an empty item clears its marker.
- Context-aware Tab/S-Tab: on a list item → indent/dedent (`<C-t>`/`<C-d>`);
  anywhere else → literal Tab. Normal-mode variant maybe C-Tab —
  **neovide-only** (terminals can't distinguish C-Tab from Tab).
- Ordered-list renumbering on insert/delete

**Neo-tree:** stock verbs; creation location implicit from tree position.
Nothing custom v1.

**Keybindings: verbs first, keys are config data.** Every feature is a user
command; keymaps only dispatch to commands, never inline closures. Each
command accepts one key or a list of keys (vimoire-style normalizer, `nil`
disables). Defaults adopt okf's settled scheme (its resolved decision 12:
`f` find family, `n` new family, singles for inbox/frontmatter) until John's
semantic-keybinding refactor, which will reassign keys as its own effort.

## Links + backlinks pane

*Promoted from deferred by explicit want (a described interaction, not an
admired screenshot). The largest UI piece — watch it hardest.*

- One pane, two sections: **Links** (outgoing, parsed from current buffer)
  and **Backlinks** (inbound, live `rg` — no cache, no index).
- Read-only buffer: `buftype=nofile`, `nomodifiable`, own filetype,
  `winfixwidth`. Reapply window opts on `BufWinEnter`/`WinEnter` (neo-tree
  protection pattern).
- **Target window** = neo-tree's per-tab MRU stack (okf verified this in
  neo-tree source): `WinEnter` autocmd pushes winids, skipping floats and the
  pane itself; resolver walks newest-first to the first valid normal window.
  Self-healing — closed windows fall through.
- Refresh both sections on `BufEnter` in normal windows.
- Enter on an entry: `:edit` *in the target window* — jumplist accrues there
  naturally, so `C-o`/`C-i` are the navigation history. The pane is a view,
  not a navigator; it holds no state.
- Backlink entries jump to the referencing *line*; outgoing entries open the
  target file. Toggle command.
- This **absorbs** the rg→quickfix backlinks idea — one backlinks UI, not two.
- Sprawl alarm: metadata columns, z-index/truncation rendering (okf's notes
  warn about neo-tree's `container.lua`). If those appear, stop.

## Treesitter / markdown mechanics

- Core 0.12 owns the treesitter runtime (highlighting, folds,
  `vim.treesitter.*`); markdown + markdown_inline parsers ship with nvim.
  nvim-treesitter (main branch) is retained **only as the parser installer**
  — NVIM_APPNAME isolates lore's data dir, so parsers from John's main nvim
  are invisible; lore installs its own.
- Parsers to install: `yaml` (frontmatter injection — highlights for free)
  plus code-fence injection languages (`ruby`, `bash`, `lua`, `sql`, `json`
  as the starting set; adjust freely).
- nvim-treesitter-textobjects for code-block textobjects (fences are
  `fenced_code_block` nodes). treesitter-context rejected — no verb needs it.
- Reference implementation for main-branch API: dotfiles
  `lua/plugins/treesitter.lua`.
- Folding: `vim.treesitter.foldexpr()`, `foldlevel=99`, `foldtext=""`.
- `conceallevel=2` — stock markdown_inline conceal metadata hides link URLs
  (shows link text; cursor line reveals raw). Free; easy to disable.
- **Custom states are regex, by design:** tree-sitter-markdown only knows
  `[ ]`/`[x]`. `[/]`/`[!]` get regex highlight rules (matchadd) with
  distinct colors. This is the sanctioned "regex where treesitter can't"
  exception.
- Cycle: `[ ]` → `[/]` → `[x]` → `[ ]`. Blocked is an asserted state —
  explicit set action, not a cycle step.
- Parent-checkbox auto-update: **cut** (unasked automation + ambiguous
  semantics with custom states).
- Inline style toggles: **skip** — vim-surround covers it.
- TOC, tables: **no**. Preview: separate dedicated plugin, later.
- 2-space indent (`shiftwidth=2 expandtab`), matching main dotfiles.

## todo.md

- **Work todos only.** Personal todos stay in Reminders — it's a *push*
  system (always on you, notifications) and vim structurally cannot be one.
  todo.md is pull, on the laptop, next to work context. Do not migrate
  personal todos into vim; that's the totality impulse, not a need.
- Nested items; a todo's **children are its metadata** — links, notes,
  context. No field syntax. (tada's `| @:x !:High` fields "did nothing" —
  that's the cautionary tale.) If a queryable field need ever materializes,
  inline `@due(...)`-style conventions are greppable and can be added then.
- Because children are links, todos automatically appear in their project's
  backlinks pane — todos surface in project context with zero machinery.
- **Sort by state, subtree-aware** (children travel with parents — treesitter
  `list_item` nodes, not line sorting). Order: `[/]` → `[ ]` → `[!]` → `[x]`
  sinks. Stable within a state: **hand position is priority** — the top of
  the `[ ]` block is the pick-up-next queue.
- Sort triggers: **explicit commands only** (settled 15 Jul 2026; BufLeave
  auto-sort was built, then cut — sorting-on-my-behalf fights hand
  ordering). Multiple on-demand sorts are the model: state today; age
  (blame) and `@due` views later, as commands, never as defaults.
- **Deadlines** — the one tada field worth keeping: inline `@due(YYYY-MM-DD)`
  convention (spec pre-approved greppable inline fields). When built: tint
  at attention boundaries (red past, yellow near), a due-sorted view
  (rg over the vault, so meeting notes carry deadlines too). Pull only —
  a deadline that must chase you belongs in Reminders.
- **Archive:** explicit sweep command moves `[x]` subtrees to `archive.md`,
  stamped with the archive date. Never automatic — items must not vanish
  unwatched.
- **Age ("how long has this been hanging"):** `git blame --porcelain todo.md`
  — one async call returns every line's last-touched timestamp; parse once.
  Last-touched (not created) is the *correct* staleness semantic: a line you
  touched yesterday isn't hanging. Day-level resolution is all the feature
  needs. `-L` exists for single lines, `--since=` as a depth escape hatch —
  neither needed at vault scale. Display mechanism (virtual text? sort
  input?) undecided — decide when building.

## Git auto-commit (blame's dependency)

- **Idle pauses are the boundaries** (CursorHold/CursorHoldI, ~4s of no
  input). FocusLost was considered and dropped as redundant: switching
  apps stops input, so CursorHold fires seconds later anyway — and unlike
  a bare Logseq-style timer, pauses never land mid-word. Prior art:
  obsidian-git's "N minutes after last change" mode is this shape.
- Every pause runs **autosave** (`silent! noautocmd wall` — obsidian-style;
  no-op when clean). noautocmd deliberately: autosave is pure persistence,
  no write-hook side effects. Renumbering rides BufLeave/QuitPre instead
  (like todo sort — tidy on return, never moves under the cursor), plus
  explicit `:LoreRenumber`.
- Commits ride the same pauses, **debounced** (at most once per ~15 min;
  `autocommit_minutes` preference) + `VimLeavePre` force backstop. On-quit
  alone is wrong — lore is a persistent instance, quit is rare.
- The age feature only needs ~daily granularity; the debounce is headroom,
  not obligation. Start coarse.
- Raycast scripts do **not** commit (earlier spec draft misrecorded this).
  External writes ride the next lore auto-commit; day-level blame
  granularity doesn't care. lore sets `autoread` + `checktime` on
  FocusGained so external appends flow into open buffers instead of
  triggering file-changed prompts.
- Commit messages: auto-timestamp. Nobody reads a private vault's log; blame
  only needs dates.
- **Push is deferred.** Local-first; commit-always is what blame needs.
  Sync strategy (enterprise vs public remotes, background push) is a
  separate later decision.
- Cost reality: ~15 text commits/day ≈ a few MB/year packed. Git's pain
  points (100k+ commits, binaries) are unreachable here. **One real risk:
  images** — binaries don't delta-compress; if the vault accrues
  screenshots, that's what bloats history. Flag, revisit if it happens.
- Precedent: obsidian-git, Logseq built-in git, GitJournal (auto-commit
  vaults); gitsigns.nvim, GitLens (live per-line blame in-editor).

## Plugins (hard budget)

Plugin manager: **vim.pack** (built into 0.12) — a persistent instance has
nothing to lazy-load, so lazy.nvim would be a dependency doing no job.

nvim-treesitter (main, parser install only) · nvim-treesitter-textobjects ·
**snacks** (picker — resolved over fzf-lua; also input/win if the pane wants
them) · **neo-tree** (accepted: existing daily habit, and it carries the
creation-location story) · vim-surround (tiny, replaces inline-style
feature). Nothing else at v1. Every addition needs a named friction.

## Deferred — do NOT build until friction proves the need

1. **LLM enrichment pass** — "engineering discoverability" (shaped
   14 Jul 2026). Hand-tagging is a gesture, never an obligation; the pass
   does the thinking John doesn't want to: reconcile tag vocabulary drift
   (suggest from the *observed* vocabulary — democracy/democrat/political
   was the Obsidian failure — never invent ontology), suggest
   related-but-unlinked notes (backlinks only see explicit links), maybe
   retro-tag old notes as new vocabulary emerges. Gate: only if real use
   shows John reaching for tag/link surfaces and finding them thin —
   proven valuable for idea/leadership work in Obsidian, not project work;
   this vault is both. If built: incremental (git-diff-gated via a
   last-run SHA bookmark in preferences.json — auto-commits don't break
   this, the pass diffs bookmark..HEAD, not "uncommitted"), machine edits
   identifiable and regenerable, single script, never load-bearing,
   never per-query. Propose-then-review vs commit-and-trust: decide at
   build time (reviewing tag diffs is itself the taxonomist work being
   avoided).
2. **Aggregate views** — orphans, broken links, graph (may be
   Obsidian-admiration; requires whole-vault pass).
3. **sai-style deterministic verbs** (`next`, `set-status`) — only if an
   LLM workflow genuinely needs machine state transitions.
4. **Contacts import/sync** (vCard) — cut harder than deferred; person pages
   are born manually when there's something to write.
5. **Push/sync strategy**, todo age *display* polish, template
   `default_dir:` hints, image handling.

## Anti-goals

- No custom format or filetype (tada's mistake).
- No JSON/YAML store; frontmatter is metadata, not a database.
- No cache/index as source of truth — anything derived must be regenerable
  and optional (rg is the floor).
- No plugin ecosystem or config surface for hypothetical users. An app for
  one person.
- No automation that rewrites prose. Restructuring is bounded: sort is
  position-only, archive relocation is explicit, renumbering touches list
  markers only.

## Watch-list (John's over-tooling tells — check work against these)

- Features ahead of use; taxonomy designed while unsure.
- Any script growing modes/config/flow-engine (the sai failure).
- Admired features vs used features.
- Rebuilding what treesitter (structure) or an on-demand LLM (semantics)
  already provides.
- The pane growing rendering machinery.

## Open decisions

1. ~~Vault path(s)~~ — resolved: registry in `preferences.json` via
   `:LoreVaultAdd`; nothing baked in.
2. ~~Picker~~ — resolved: snacks.picker ("fine for now, we can try it").
3. ~~Normal-mode indent key~~ — resolved: nothing needed. Insert mode has
   Tab/S-Tab (aliasing vim's native i_CTRL-T/i_CTRL-D); normal mode's
   native `>>`/`<<` suffice.
4. Todo age display — leaning **virtual text with age-tinted highlights**
   (extmark chunks carry their own colors; fresh=dim → stale=warm).
   Finalize at build time.
5. ~~Auto-commit debounce default~~ — resolved: 15 min (config number).
6. Keybindings — okf's scheme as defaults; the semantic-keybinding
   refactor happens at the end, as its own effort.
7. ~~Does `:LoreVaultAdd` `git init` a non-repo path?~~ — resolved: yes
   (auto-commit and todo age depend on every vault being a repo).
8. Picker appearance/theming (snacks highlight groups, layout presets) —
   revisit near the end; both snacks and fzf-lua are fully themeable.
9. ~~`wall`-before-commit (autosave)?~~ — resolved: yes; autosave +
   debounced commit both ride idle pauses (see git auto-commit section).
10. Vault ownership/mixing (personal vs work, cross-vault search) —
    parked. May resolve to one full vault depending on the new company's
    rules; revisit before real content accumulates in the wrong git.
11. Raycast meeting-note script (`~/dev/raycast/scripts/lore-meeting-note.sh`)
    is untested against live icalBuddy output — parser written from
    documented format. Test on a day with real meetings; if parsing is
    off, capture `icalBuddy -nc -b "" -li 1 -ea -iep "title,attendees"
    eventsNow` output and fix in one pass.

## Prior art (all local)

- `~/dev/vimoire` — the recipe: NVIM_APPNAME app, radically constrained,
  grown from real daily use. The success story.
- `~/dev/okf` — built vault app, cache-based (rejected architecture).
  Reference for: launcher/socket/NeovideFocus research (NOTES.md), the
  MRU-target-window pattern, blink.cmp `[[` completion source design,
  snacks patterns, app/ repo shape. Reference only — no code ports.
- `~/dev/vim-tada` — the interactions worth keeping (toggle, smart-Tab,
  fold) and the cautionary tale (custom format, metadata engine that did
  nothing).
- `~/dev/sai` — cautionary tale for flow engines; source of the deferred
  deterministic-verbs idea.
- `~/dev/dotfiles` — treesitter main-branch reference
  (`lua/plugins/treesitter.lua`), Tomorrow-Night treesitter captures.
- mkdnflow.nvim — *behavior* reference for checkbox cycling with custom
  symbols, create-on-follow, selection→link. Read designs, write our own
  (same rule as okf).
