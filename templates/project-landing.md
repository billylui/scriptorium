---
type: landing
status: active
created: {{date}}
project: "[[{{project_name}}]]"
tags:
  - project
  - landing
---

# {{project_name}}

<one-paragraph context: what this project is, the goal, the time horizon. Replace this.>

## Overview

<2-4 paragraphs: scope, current state, key constraints. Skip this heading if the opening paragraph is enough.>

## Active threads

<Concept-sectioned MOC. Sections are concepts you'll re-enter (Hypotheses, Stakeholders, Workstreams, Open questions about X), NOT file types (Meetings, Decisions, Resources — those belong elsewhere). Sparse for new projects; fills in over time. Each section: one-line framing + wikilinks to the notes that develop the concept.>

### <Thread name>
- [[<note-name>]] — one-line description

## Decisions

<Auto-list from `decisions/` subfolder. While that folder is empty:> *No decisions logged yet. When ≥1 significant decision is made, file as `decisions/0001-<imperative-title>.md` using the `decision` template.*

<When `decisions/` exists, list as:>
- [[0001-<title>]] — one-line summary (status: accepted | superseded)

## All notes

*Catalog of every file in this project folder, grouped by `type:` frontmatter. One `**type: <value>**` group per distinct type present, in this canonical order: protocol, plan, narrative, brief, meeting, research, synthesis, reference, log. Never a `decision` group (those live in `## Decisions`). Header text is the literal frontmatter value. Hand-maintained until you adopt an Obsidian Base; then replaced with an embedded Bases view filtered to this folder.*

**type: plan**
- [[<note>]] — one-line summary

**type: research**
- [[<note>]] — one-line summary

**type: reference**
- [[<note>]] — one-line summary

<...one group per type actually present. For an append-only stream subfolder, point to its landing, e.g.:> **type: log** — append-only stream ([[entries/entries|stream landing]])
- [[<entry>]] — one-line summary

<If the folder has no eligible notes yet, the body is exactly: *None yet.*>
<Use path-qualified links `[[<Folder>/<note>]]` when a basename collides elsewhere in the vault.>

## Related

- **People:** [[<Person>]], [[<Person>]]
- **Knowledge:** [[<Knowledge-Note>]]
- **Other projects:** [[<Other-Project>]]
- **Areas:** [[<Area>]]

---

<Optional sections below (insert ABOVE `## Decisions` if used, not at the end):>
<- `## Codebase` — repo paths, README, conventions (code-bearing projects)>
<- `## Tech Stack` — dependencies, infra (code-bearing projects)>
<- `## Team` — collaborators, advisors>
<- `## Action items` — operational checklists, status tables>
<- `## Funding / Schedule / etc.` — project-specific operational content>
<- `## Open questions` — at the very end, after `## Related`>
