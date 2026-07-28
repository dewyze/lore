---
name: enrich-vault
description: Incremental OKF enrichment pass over a lore vault — reads the last-run SHA bookmark, examines only markdown that changed since, then adds frontmatter (type/tags/description/resource), appends Related links, and regenerates index.md/log.md. Proposes structural changes (splits, merges, missing hubs) without performing them. Use when asked to enrich, tag, link, index, or OKF-conform a vault, or to run "the enrichment pass".
---

# Enrich vault

The deferred "LLM enrichment pass" from `SPEC.md:364`, built as a skill so it
ships no app code and stays deletable. It does the taxonomy thinking John
doesn't want to do by hand: reconcile tag vocabulary, surface
related-but-unlinked notes, keep OKF's reserved files current.

Spec references below are to OKF v0.2:
`https://raw.githubusercontent.com/GoogleCloudPlatform/knowledge-catalog/main/okf/SPEC.md`
Fetch it if a rule here is ambiguous — the spec wins, this file is a summary.

## Hard rules

These come from `README.md` Philosophy and `SPEC.md` Anti-goals. Violating
one is a bug, not a tradeoff.

1. **Never reword prose.** You may add frontmatter, append sections, and
   write reserved files. You may not edit a sentence John wrote. No inline
   linking of bare mentions — a link goes in an appended section.
2. **Never invent ontology.** Tags and `type` values come from vocabulary
   already observed in the vault. Suggesting `democracy` when the vault says
   `political` was the Obsidian failure (`SPEC.md:367`). A genuinely new tag
   is allowed only when the file's subject has no existing neighbour, and it
   must be called out in the report.
3. **Nothing derived is load-bearing.** Everything written must be
   regenerable by re-running. No state beyond the bookmark.
4. **Machine edits stay identifiable** — via `generated:` frontmatter and an
   `enrich:` commit prefix.
5. **Structural changes are proposals only.** Never move, merge, split, or
   delete a file. Report and stop.

## Step 1 — Resolve vault and bookmark

Preferences live at `~/.lore/preferences.json` (or `~/.$NVIM_APPNAME`). Read
`active_vault` and `vaults` to get the vault path. Do not depend on cwd.

```bash
python3 - <<'PY'
import json, os
p = os.path.expanduser("~/.lore/preferences.json")
d = json.load(open(p))
name = d.get("active_vault")
print(name, d.get("vaults", {}).get(name, ""), (d.get("enrich_bookmark") or {}).get(name, ""))
PY
```

The bookmark is `enrich_bookmark: {"<vault name>": "<sha>"}`. It is a SHA, not
a timestamp, deliberately: the vault auto-commits, so a dirty-tree check would
never be stable, but `bookmark..HEAD` is (`SPEC.md:373`).

## Step 2 — Scope the work

```bash
git -C "$VAULT" diff --name-only --diff-filter=ACMR "$SHA"..HEAD -- '*.md'
```

- **No bookmark** (first run): scope is every tracked `*.md`. Say so, and
  offer to process in batches rather than boiling the vault in one pass.
- **Bookmark missing from history** (rebase, fresh clone): treat as first run.
- Diff `bookmark..HEAD` only. Uncommitted work is out of scope by design — if
  the tree is dirty, report that and let John commit first, so your own edits
  don't tangle with his.

Reserved files (`index.md`, `log.md`) are never inputs. Everything else is in
scope, including `todo.md`, `inbox.md`, and `archive.md`: frontmatter is inert
with respect to their machinery, because capture appends at EOF
(`todo.lua:109`, `inbox.lua:1`) and sort/archive operate on treesitter
`list_item` spans (`todo.lua:71`, `todo.lua:128`). Nothing there reads line 1.

## Step 3 — Frontmatter

Read the whole file before writing. Preserve unknown keys (§4.1 Extensions).

Required for conformance (§11): a parseable YAML block with non-empty `type`.

- `type` — REQUIRED. Short, descriptive, self-explanatory. Reuse a value
  already present in the vault; `rg '^type:' -N --no-filename "$VAULT" | sort | uniq -c`
  is the vocabulary. For this vault expect shapes like `Meeting`, `Project`,
  `Note`, `Idea`, `Person`, `Reference`. `Meeting` is authoritative, not a
  suggestion: the Raycast capture script writes it at birth
  (`~/dev/dotfiles/raycast/scripts/lore-meeting-note.sh`), so match that
  capitalization exactly rather than inventing `meeting`.
- `title` — only when the filename doesn't already say it (§4.1: consumers
  MAY derive title from filename, and lore's filenames are the retrieval
  surface, so usually omit).
- `description` — one sentence. Write this one even when it feels redundant:
  `index.md` generators consume it (§8), and without it every index entry is
  a bare title.
- `tags` — YAML list, from observed vocabulary. Report vocabulary drift you
  notice (near-duplicate tags) as a recommendation; do not silently merge.
- `resource` — a URI for the underlying asset the note *describes*. Most
  notes here are abstract and get none. A note about a dashboard, repo, or
  ticket gets one. Never invent a URL.
- `enriched: { by: claude/<model-id>, at: <ISO 8601> }` — stamp the files
  whose metadata you touched. A producer-defined extension key (§4.1), not a
  spec family.
- `generated: { by: human:john, at: <ISO 8601> }` — attribute the *content*
  (§5.2), which is distinct from the metadata you added. Derive it from git,
  never from vibes:

  ```bash
  # Did a human type this, or did the pass write it?
  git -C "$VAULT" log --diff-filter=A --format='%s' -- "$FILE"   # adding commit
  # The content's last meaningful change = last commit that wasn't this pass
  git -C "$VAULT" log -1 --format='%cI' --invert-grep --grep='^enrich:' -- "$FILE"
  ```

  The git *author* is `John DeWyze` on every commit (auto-commit uses his
  identity), so it discriminates nothing. The commit *subject* does: `auto:`
  is lore's autosave — John typing in the editor — and `enrich:` is you.

  - Body came in via `auto:` commits ⇒ `by: human:john`, `at:` = the
    last-non-`enrich:` timestamp. §7 *requires* the `human:` prefix for
    hand-authored content, and §5.3 keys the trust tier off it.
  - Machine-scaffolded but human-filled (Raycast meeting notes, applied
    templates, a `gf`-born page John then wrote) ⇒ still `human:john`. §5.2
    attributes the *current content*; a template isn't the content.
  - Empty or stub file, nothing written yet ⇒ write no `generated`. There is
    no content to attribute.
  - An existing `generated` ⇒ leave it alone. Never overwrite an attribution.

  **What the stamp actually claims.** `human:john` means "this content
  arrived through John's editor session" — typed or pasted, indistinguishable
  and not worth distinguishing. Do not try to judge whether prose was
  human-written; that is guesswork, and guesswork is what this rule exists to
  prevent.
- `verified` — **never write this.** It means a human confirmed the content;
  `human:john` is his to add, and §5.3 keys trust off the `human:` prefix. A
  machine that can self-verify makes the tier meaningless.
- `status` — omit. Absent means `stable` (§5.4); write it only for something
  clearly `draft` or `deprecated`.
- `stale_after` — omit unless the content is explicitly time-bound.

### Meetings

Meeting notes arrive already scaffolded by the Raycast capture script with
`type: Meeting`, `meeting:`, `date:`, `attendees:`, and an empty `project:`
(`SPEC.md:115`). Leave all of them; add to them.

`meeting:` is the recurring key — the calendar event title, unchanged across
instances, while the filename and body heading vary by date. Two rules:

- **Never rewrite or normalize it.** It is machine-written at birth and is
  the join key for a series. "Rewording" it silently splits one series into
  two. It is quoted (a title may contain `:`); preserve the quoting.
- **Treat a shared `meeting:` as a confirmed relationship.** Notes with the
  same value are the same recurring series — the one linking signal in this
  vault that needs no judgment. `rg -l '^meeting: '"$(...)"` to find
  siblings. Prefer linking a series through a hub over wiring every
  instance to every other: N instances linked pairwise is N² noise in the
  backlinks pane, and the pane is live ripgrep with no ranking.

When a series has enough instances to be worth navigating and no hub exists,
raise it in Step 6 as a proposal — creating the hub is a structural change,
so it is John's to make.

## Step 4 — Links

Backlinks are live ripgrep over explicit links (`README.md` Links), so an
unlinked mention is invisible to the pane. Fix that by appending, never
inline.

At the bottom of the body:

```markdown
## Related

- [Subscriptions](/projects/subscriptions.md) - why this note relates
```

- Absolute bundle-relative paths (`/projects/foo.md`) — §6.1 recommends them
  because they survive moves, and it's what `links.lua` already emits.
- If a `## Related` section exists, merge into it; don't add a second.
- Broken links are legal (§6.1) and are how pages get born in lore — linking
  to a page that should exist is a valid suggestion. Flag it in the report so
  John knows a `gf` will create it.
- Don't link a note to something it merely shares a tag with. The bar is "a
  reader of A would want B", not lexical overlap.

## Step 5 — Reserved files

**`index.md`** (§8) — a directory listing for progressive disclosure. Not a
hub page, not a concept.

- **No frontmatter.** Sole exception: the bundle-root `index.md` MAY carry
  `okf_version: "0.2"` (§12). Any other frontmatter is nonconformant.
- Sections of bullets; entries reuse the linked concept's `description`:

```markdown
# Projects

* [Subscriptions](projects/subscriptions.md) - Renewal tracking and vendor notes.
* [Meetings](meetings/) - Dated meeting notes.
```

- Subdirectory entries end in `/`. Index links are relative (§8's form).
- Regenerate any directory's index whose contents changed. Missing indexes are
  explicitly fine (§11) — add one when a directory has enough files that
  listing helps, not reflexively.

**`log.md`** (§9) — per-scope history, ISO-8601 date headings, newest first:

```markdown
# Directory Update Log

## 2026-07-28
* **Creation**: Established the [Subscriptions](/projects/subscriptions.md) hub.
```

Default criteria for what earns a log line (see Tunables):

- **Log**: a concept created; a concept deprecated; a structural change John
  approved; a new hub.
- **Don't log**: tags added, `description` written, index regenerated,
  `Related` links appended. Routine enrichment is visible in git; logging it
  turns `log.md` into a changelog of yourself.

## Step 6 — Recommendations

Report, don't act. Cover John's item 4 and anything else load-bearing:

- Files that want splitting (two unrelated subjects) or merging (same subject).
- A folder with no hub file — `projects/<slug>/` with no `projects/<slug>.md`
  is invisible to backlinks and pickers (`pages.lua:52-59`).
- A recurring `meeting:` series with several instances and no hub to hang
  them on.
- Tag vocabulary drift: near-duplicates that should collapse.
- Notes that look misfiled.
- Conformance gaps you chose not to fix, and why.

## Step 7 — Commit and advance

1. Show what changed (`git -C "$VAULT" diff --stat`) plus the report.
2. Commit with an `enrich:` subject prefix so machine edits are greppable.
3. Advance the bookmark to the **new** HEAD — after your commit, so the next
   run doesn't re-examine your own writes.

```bash
python3 - <<'PY'
import json, os, subprocess
p = os.path.expanduser("~/.lore/preferences.json")
d = json.load(open(p))
name = d["active_vault"]
vault = d["vaults"][name]
sha = subprocess.check_output(["git","-C",vault,"rev-parse","HEAD"], text=True).strip()
d.setdefault("enrich_bookmark", {})[name] = sha
json.dump(d, open(p,"w"))
print("bookmark", name, sha)
PY
```

Writing `preferences.json` directly is a deliberate exception to "humans never
edit this file" (`preferences.lua:1-3`) — the rule keeps *humans* out; this is
a machine, and the pass runs outside nvim so the Lua module isn't loaded.
Load-then-merge, never overwrite the file wholesale: `active_vault` and
`vaults` must survive.

If John rejects the changes, `git checkout` the vault and leave the bookmark
alone. A failed pass must be re-runnable.

## Tunables

Adjust here, not by adding flags — a script growing modes is on John's
watch-list (`SPEC.md:404`).

- **Excluded files**: none by default. `todo.md`/`inbox.md`/`archive.md` get
  frontmatter like anything else — §11 wants `type:` on every non-reserved
  `.md`, and their append/sort machinery never touches line 1. Their bodies
  are churn, so keep their metadata thin: `type` and `description`, no `tags`.
- **log.md criteria**: Step 5's lists.
- **Index threshold**: when a directory earns an `index.md`.
- **New-tag tolerance**: how readily a genuinely new tag is allowed vs.
  forced onto an existing one.
