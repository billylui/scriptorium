---
name: vault-log
description: Per-session capture for an agent-written Obsidian vault. Scans the current conversation for decisions, insights, knowledge and action items, files them into the vault with verified links, logs a one-liner to the session date's daily note, captures an optional one-line reflection in the owner's own words, and refreshes the search index. Use before clearing context or switching topics.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
---

# vault-log — Session Capture

You are saving the current conversation's value into the vault before the session ends. This is a **capture** skill, not a maintenance ritual — extract what matters, file it, move on.

**Configuration.** Folder names and the search tool come from `.scriptorium.json` at the vault root: `<daily_folder>`, `<templates_folder>`, `<synthesis_folder>`, `<landing_note_parents>`, `<protected_surfaces>`, `<index_filename>`, `<day_boundary_hour>`, `<search_command>`. Read the real values there rather than assuming the example defaults; where a key is blank, ask instead of guessing a layout.

## Step 1: Session Scan

Review the full conversation and extract anything worth persisting:

- **Decisions made** — what was decided, and why
- **Insights and realizations** — new understanding, reframed thinking, the moments something clicked
- **Knowledge points** — facts, frameworks, patterns, techniques learned
- **Synthesis-grade output** — frameworks, comparison tables, multi-factor analyses or decision models produced during the session that don't naturally belong as an appendix to an existing page. These warrant their own note in `<synthesis_folder>`.
- **Action items** — things the owner committed to doing (not things the agent did)
- **People mentioned** — new context about relationships, interactions, commitments

Skip anything already filed during the conversation — notes created or updated as part of the session's actual work do not need re-filing.

Present a brief summary of what you found:

```
Captured from this session:
- 2 decisions (auth provider, API structure)
- 1 insight (pricing model reframe)
- 1 synthesis → new note in the synthesis folder (API comparison framework)
- 1 action item (follow up with the design contractor re: scope)
```

If the session was purely operational — filing inbox items, no new thinking — say so and skip to Step 3.

## Step 2: File & Link

For each captured item:

1. **Classify** — which folder and note does it belong in? (project, area, person, knowledge)
2. **Dedup check, before creating any new page:**
   - Was this already filed during the conversation? Skip it.
   - **Index check first:** read the per-folder `<index_filename>` for the target folder. Does a page for this concept already exist?
   - **Search if uncertain:** if the index shows no obvious match but the concept might exist under a different name, run `<search_command>` across the vault with the concept as its `{query}`. Any search CLI works here — semantic or plain grep.
   - If a similar page exists, **append or update it** rather than creating a new one. Add the new findings under the existing structure.
   - Only create a new page when the concept is genuinely distinct from everything already in the vault. Near-duplicate pages are the most expensive kind of vault debt: both stay half-right, and every later read has to reconcile them.
3. **Create or append** — add to the appropriate note. If the note doesn't exist, create it with proper YAML frontmatter following the shape conventions (invoke the `vault-conventions` skill for the full spec):
   - **`type:` is REQUIRED on every new note.** Pick from the vocabulary: `landing | decision | research | narrative | reference | meeting | protocol | plan | brief | log | synthesis | person | daily | profile`. When uncertain, use `reference`. The templates encode the right shape for each kind.
   - **New project or area folder:** use `<templates_folder>/project-landing.md` or `<templates_folder>/area-landing.md` for the `<FolderName>/<FolderName>.md` landing note — not the minimal `<templates_folder>/project.md`, which is a plain note template and lacks the skeleton. The four required anchors (`## Active threads`, `## Decisions`, `## All notes`, `## Related`) must be present even when sparse; the skeleton applies regardless of file count.
   - **Sub-folders inside a topic node:** only the THREE blessed names are allowed — `decisions/`, `entries/` (or `sessions/`, `logs/`), `reports/` (or `attachments/`). Forbidden: `meetings/`, `notes/`, `ideas/`, `legal/`, `strategy/`, `research/`, or any other type-bucket. Use `type:` frontmatter for role discrimination, not folders.
   - **Significant decisions go to `decisions/`** — file a material decision as `<TopicNode>/decisions/NNNN-imperative-title.md` using `<templates_folder>/decision.md`. Sequential numbering, never reused. Trivial decisions stay inline in the relevant project or area note.
   - **Never write `.md` files to the vault root** other than those in `root_allowlist`, and never directly at the section level of a folder in `<landing_note_parents>` other than its `<index_filename>`. All content goes inside a `<FolderName>/` topic node.
   - **The people collection and `<synthesis_folder>` are flat** — no sub-folders, no per-note landing pages. Just `<Note-Name>.md` with `type:` (typically `synthesis` there, `person` for people).
4. **Add `[[wikilinks]]`** — link to related people, projects and areas, and **verify each new target exists** before writing it (glob `<TargetName>.md`, or check the relevant index). A bare wikilink resolves only to a file of that exact name, never to a folder, so `[[Project]]` needs `Project/Project.md` to exist. If the basename is ambiguous — the same note name exists in two folders — use a path-qualified link: `[[<Folder>/<note-name>]]`.
5. **Multi-page propagation** — after filing the primary destination, check:
   - **People mentioned** → does their dossier need an interaction-log entry? If so, append it with date and context.
   - **Areas affected** → does a decision in this session change a protocol, strategy or stack? If so, update that specific section in the relevant area note.
   - **Project status** → does this session change a project's status, timeline or scope? If so, update its landing note.
   - Log every page touched (primary and propagated) in the output.

Follow the auto-sort rules in `LAWS.md`. Don't create a note for a passing mention — use judgment about what is substantial enough to persist.

## Step 2b: Update Indexes & Landing Catalogs

For each note **created** in Step 2 (not merely modified):

1. Add a one-line entry to the per-folder `<index_filename>`: `- [[Note-Name]] — summary`.
2. Update the global `<index_filename>` at the vault root — add the entry and adjust that section's count.
3. If a NEW topic-node folder was created, verify it contains its `<FolderName>.md` landing note. Add it if missing. (The vault-guard hook blocks writes into a topic-node folder that has no landing, so this is normally already handled — but a folder created by other means can still slip through.)
4. **If the note was created inside a topic node** — including a named sub-area, but NOT a stream or artifact sub-folder like `decisions/`, `entries/` or `reports/` — add it to that landing's **`## All notes`** catalog, under the `**type: <value>**` group matching the note's own frontmatter `type:`, as `- [[Note-Name]] — one-line summary`. Create the group in canonical order (protocol → plan → narrative → brief → meeting → research → synthesis → reference → log) if it is absent. Path-qualify the link if the basename collides elsewhere in the vault. Notes filed under `decisions/` are catalogued in the landing's `## Decisions` section instead.

A note modified but not created needs no index or catalog update — its entry already exists.

## Step 3: Daily Note Log

Determine the **session date**: if the current time is before `<day_boundary_hour>` (05:00 by default), use **yesterday's** date — late-night work belongs to the day it started. Otherwise use today's date.

Read `<daily_folder>/YYYY-MM-DD.md` for the session date and append **one timestamped line** to its `## Activity log` section:

```
- HH:MM — [one-line summary of what the session covered and its key outcomes]
```

Use the current time for the timestamp. If the daily note doesn't exist, create it from `<templates_folder>/daily.md`.

## Step 4: Open Loops & Reflection

Ask both questions together in one short message. Both are skippable, at zero friction:

1. **"Anything from this session that's still on your mind?"** If something comes back, process it — classify, file, link. If not, move on.

2. **"One-line reflection in your own words?"** Vary the phrasing naturally; when the session had an obviously decisive or charged moment, anchor to it ("how did the X decision actually sit with you?").
   - If answered, append the words **verbatim** to the session date's daily note under `## Reflections`: `- HH:MM — <their exact words>`
   - **Protected surface.** `## Reflections` is a human-authored surface listed in `protected_surfaces`. Format and append ONLY — never paraphrase, expand, tidy, or invent. If the question is skipped, write nothing there; a placeholder is worse than an empty section because it reads later as though something was captured.
   - Multiple sessions in one day accumulate bullets.

**Why this step carries more weight than it looks.** In a mature agent-written vault almost all the prose is the agent's, which means the reflection line is one of the very few *renewable* first-party sources in the whole system — and in practice it is the one most often left empty, because nothing ever asks. Every claim the agent can legitimately make about how its owner thinks has to be sourced from material like this (see `AUTHORSHIP.md`, Law 2). Ask the question properly. A skipped reflection is a permanently missing data point, not a neutral non-event.

This capture skill hosts the question because it is the ritual actually run while the human is present. An unattended scheduled pass must never write to this section — it has nobody to ask, so anything it puts there is fabrication by construction.

## Step 5: Refresh the Search Index

If `<search_command>` points at a tool that maintains its own index (a semantic-search CLI, for instance), refresh it now and report briefly:

```
search index: updated X files
```

Plain `grep`-style tools need no index step — skip it silently rather than reporting a no-op.

## Output Format

Keep it tight — the whole output should fit on one screen:

1. What was captured (the Step 1 summary)
2. Where it was filed (bullet list of notes created and updated)
3. Daily note updated, confirmed
4. Open loops and reflection prompts (one message, both skippable)
5. Search index status

No tables, no stats blocks, no stale-project scans. Those belong to an end-of-day pass (`vault-wrap`), not a session capture.
