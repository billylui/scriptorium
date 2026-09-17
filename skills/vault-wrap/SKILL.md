---
name: vault-wrap
description: End-of-day pass over a markdown vault — synthesise the day's log into a summary, sweep the inbox, find orphaned notes, flag stale projects, lint the conventions, refresh the search index, and set tomorrow's first thing. Run once at the end of a working day, after one or more capture sessions.
---

# Vault wrap

The closing pass. `vault-up` opens the day and `vault-log` captures during it; this closes it and does the maintenance nothing else does.

Run once per day. Everything here is safe to re-run — if a wrap already happened, do the lint and index steps and skip the synthesis.

**Configuration.** Folder names, the day boundary and the search command come from `.scriptorium.json` at the vault root: `<daily_folder>`, `<inbox_folder>`, `<landing_note_parents>`, `<synthesis_folder>`, `<templates_folder>`, `<index_filename>`, `<day_boundary_hour>`, `<search_command>`, `<protected_surfaces>`. Read the real values; where a key is blank, skip that step rather than guessing a layout.

**Day boundary.** Before `<day_boundary_hour>`, today's note is *yesterday's* date. Resolve this first — every step below writes to that file.

---

## 1. Summarise the day

Read today's note in `<daily_folder>`. Synthesise its activity log into a short summary: what actually moved, what was decided, what is now open.

**Write the summary, not a list.** The log already lists. The summary's job is what the log cannot say — what it added up to.

⚑ **Never write into a protected surface.** Anything in `<protected_surfaces>` — a reflections heading, a journal section — is the owner's own words. If they gave you text for it, format and append it. Never invent it, never rewrite it, never fill an empty one to look complete.

## 2. Inbox to zero

List `<inbox_folder>`. For each item: classify, file, link, log, remove — the intake loop.

If something cannot be filed because you do not know where it belongs, **ask rather than guessing.** A note filed into the wrong folder is worse than one left in the inbox, because the inbox is a place people look.

Report what remains and why.

## 3. Orphans

Find notes nothing links to. Glob the vault's `.md` files, then check which basenames never appear inside `[[...]]` anywhere else.

Exclude by nature: daily notes, templates, index files, landing notes, and the root `CLAUDE.md`.

**Orphans are a signal, not an error.** A genuinely standalone note is fine. A note that *should* be connected and is not means the link step was skipped when it was filed. Report them and offer to link the ones that clearly belong somewhere.

## 4. Stale topic nodes

For each folder under `<landing_note_parents>`, read its landing note's frontmatter and modification time.

Flag anything `status: active` untouched for more than two weeks. **Ask whether it is finished, parked, or genuinely still active** — and if finished, offer to update the status and move it to the archive.

This step exists because nothing about a stale project looks stale from inside its own note. One project left `active` after it ended appears in every enumeration and every "what is open" answer, indefinitely.

## 5. Lint the conventions

Check what the write-time guard cannot: files that reached disk another way — shell commands, sync, mobile, another editor.

- **Hard-wrapped prose.** Paragraphs split across lines by a column boundary rather than intent. Offer to reflow.
- **Stray root markdown** — anything at the vault root outside the allowlist.
- **Multi-wikilink YAML** — two or more `[[...]]` on one frontmatter line.
- **Missing landing notes** — a folder under `<landing_note_parents>` with no `<Folder>/<Folder>.md`.
- **Missing `type:`** on notes in content folders.
- **Broken wikilinks** — link targets with no matching file. Distinguish a typo from an intentional forward reference.
- **Index drift** — notes absent from their folder's `<index_filename>`.

**Report before fixing.** Reflowing and index updates are safe to apply directly; anything touching prose or structure gets confirmed first.

## 6. Refresh the search index

Run whatever `<search_command>` depends on. For an index-backed tool this is its update and embed step; for a grep-style tool there is nothing to do.

**Run it yourself.** Do not tell the owner to run it later — an index that lags the vault silently degrades every answer the research law depends on, and the degradation is invisible.

## 7. Tomorrow's first thing

Close with **one** thing to pick up tomorrow, drawn from what is actually open: an unfinished thread, a decision waiting, a stale project needing a call.

One, not a list. A list is a backlog and gets ignored; one thing gets done.

Offer to write it into tomorrow's note.

---

## Report

Keep it short — this runs at the end of a working day:

- What the day added up to, in a sentence or two
- Inbox: processed / remaining
- Orphans, stale nodes, lint findings — **counts, with detail only where action is needed**
- Whether the index refreshed
- Tomorrow's one thing

**Say what you changed and what you only reported.** The owner should never have to diff their own vault to find out what the wrap did.
