---
name: vault-up
description: Session-start ritual for an agent-written Obsidian vault. Creates today's daily note, processes the inbox to zero, shows a vault health dashboard, surfaces active projects, resurfaces old notes for serendipity, and sets the session intention. Use at the beginning of any working session in the vault.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
---

# vault-up — Session Start Ritual

You are opening a work session on the vault. Run through each step below in order. Be concise in your output — use tables and bullets, not paragraphs.

**Configuration.** Folder names and the search tool come from `.scriptorium.json` at the vault root: `<daily_folder>`, `<inbox_folder>`, `<templates_folder>`, `<synthesis_folder>`, `<landing_note_parents>`, `<private_domains>`, `<index_filename>`, `<day_boundary_hour>`, `<search_command>`. Read the real values there rather than assuming the example defaults; where a key is blank, ask instead of guessing a layout.

## Step 1: Today's Daily Note

Determine the **session date**: if the current time is before `<day_boundary_hour>` (05:00 by default), use **yesterday's** date — late-night work belongs to the day it started. Otherwise use today's date.

- Check whether `<daily_folder>/YYYY-MM-DD.md` exists for the session date.
- If not, create it from `<templates_folder>/daily.md`. Replace `{{date}}` with `YYYY-MM-DD`, `{{day_name}}` with the weekday name, `{{date_long}}` with the full date (e.g. "Saturday, 21 March 2026").
- If it exists, read it so you have context on the day's activity so far.

## Step 1b: Missed Close-Out Check

Check whether yesterday's daily note has a `## Daily summary` section with content in it. An empty or missing section means the previous day was never closed out:

- Flag it prominently: **"Yesterday was not closed out — no daily summary. Write one now?"**
- If confirmed, synthesize yesterday's activity log into a summary before continuing.
- If declined, move on. This is a prompt, not a gate.

## Step 2: Process the Inbox to Zero

- List `<inbox_folder>`. If empty, report "Inbox clear" and move on.
- If items exist, process each one using the auto-sort rules in `LAWS.md`:
  1. Classify by project, area, or person.
  2. Create or append to the appropriate note in the correct folder (shape per the `vault-conventions` skill).
  3. Add `[[wikilinks]]` to related notes, verifying each target exists.
  4. Log the activity in the session date's daily note.
  5. Remove the processed item from `<inbox_folder>`.

A dump that spans several topics splits into separate notes per destination rather than one note filed under whichever topic came first.

## Step 3: Vault Health Dashboard

Read the global `<index_filename>` at the vault root, and the owner profile hub (the single note with `type: profile`) if one exists, to orient on the vault's shape and current context. Then display a compact dashboard:

```
Inbox:       X items (should be 0 after Step 2)
Daily notes: last entry YYYY-MM-DD (X days ago)
People:      X contacts
Projects:    list active project names
Areas:       list area names
Knowledge:   X notes
Drafts:      X notes with status: draft
Orphans:     X notes with zero backlinks (list them if <5)
```

Use the global index for counts and structure — don't re-scan every folder, which is slow and produces a number that disagrees with the index instead of fixing it. To find orphans: glob all `.md` files, then grep for `[[filename]]` patterns; a note is orphaned when nothing else links to it (excluding templates, `<index_filename>` files, and the vault's instruction files).

## Step 4: Active Projects

For each topic node under `<landing_note_parents>`, read its landing note (`<Folder>/<Folder>.md`) and show:

- Project name
- Status (from frontmatter)
- Last modified date
- One-line summary, or the next action if one is recorded

Flag any project not modified in 14+ days as **stale**. Staleness is a prompt to archive or revive, not a criticism — a project that has been stale for a month is usually a decision nobody has made yet.

## Step 5: On This Day

Look for daily notes from one week ago, one month ago, and three months ago. If any exist, show a 1-2 line summary of what happened that day. If none exist, skip silently rather than reporting absence.

## Step 6: Serendipity

Pick 3 random notes from the vault and show each title plus its first meaningful line. The goal is to trigger connections you would not have searched for.

Exclude templates, daily notes, `<index_filename>` files, the vault's instruction files, and anything under `<private_domains>` — a resurfacing feature that surprises you mid-screenshare is a bug, not serendipity.

Randomize with something like `ls | shuf | head -3` (or `gshuf` on macOS).

## Step 7: Review Cadence Check

- Check when the last weekly review happened: search daily notes for a "weekly review" mention, or look for a `<synthesis_folder>` note dated within the last 7 days.
- Check when the last monthly synthesis happened: search for a "monthly synthesis" mention, or a `<synthesis_folder>` note dated within the last 30 days.
- If either is overdue, flag it: "Weekly review overdue (last: X days ago)" or "Monthly synthesis overdue."

Use `<search_command>` for these searches, substituting the query for its `{query}` token. Any search CLI works — semantic or plain grep — so long as it takes a query and returns note paths; nothing here depends on a particular product.

## Step 8: Session Intention

Ask: **"What's the ONE thing for this session?"**

Wait for the answer before starting any other work. This step is the reason the ritual exists — everything above is orientation, and orientation without a chosen target just becomes a nicer way to start the day unfocused.

## Output Format

Present everything as a single scannable briefing. Use a header per section, keep each section to 3-5 lines, and end with the intention prompt.
