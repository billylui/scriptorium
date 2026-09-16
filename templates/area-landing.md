---
type: landing
status: active
created: {{date}}
area: "[[{{area_name}}]]"
tags:
  - area
  - landing
---

# {{area_name}}

<one-paragraph context: what this life domain is, current focus, why it's an area (ongoing) vs a project (time-bound).>

## Overview

<2-4 paragraphs: current state, what's evolving, recent shifts. Skip if opening paragraph suffices.>

## Active threads

<Concept-sectioned MOC for the area. Sections are stable concepts (Protocols, References, Stakeholders, Open questions). Sparse for thin areas; rich for active ones.>

### <Thread name>
- [[<note>]] — one-line description

## Protocols & reference

<Stable reference notes that should be findable. Examples: `current-protocol`, `baseline-metrics`, `terminology`. Mark which one(s) are the "read first" anchors.>

- [[<current-protocol>]] — **active reference** (one-line description)
- [[<note>]] — one-line description

## Decisions

<Auto-list from `decisions/` subfolder when material decisions accumulate.> *No decisions logged yet. When ≥1 significant decision is made, file as `decisions/0001-<imperative-title>.md`.*

## All notes

*Catalog grouped by `type:` frontmatter. One `**type: <value>**` group per distinct type present, in this canonical order: protocol, plan, narrative, brief, meeting, research, synthesis, reference, log. Never a `decision` group (those live in `## Decisions`). Header text is the literal frontmatter value. Hand-maintained until you adopt an Obsidian Base.*

**type: protocol**
- [[<note>]] — one-line summary

**type: reference**
- [[<note>]] — one-line summary

<...one group per type actually present. For an append-only stream subfolder, point to its landing, e.g.:> **type: log** — append-only stream ([[entries/entries|stream landing]])
- [[<entry>]] — one-line summary

<If the folder has no eligible notes yet, the body is exactly: *None yet.*>
<Use path-qualified links `[[<Folder>/<note>]]` when a basename collides elsewhere in the vault.>

## Related

- **People:** [[<Person>]]
- **Knowledge:** [[<Knowledge-Note>]]
- **Projects that depend on this area:** [[<Project>]]
- **Sister areas:** [[<Area>]]

---

<Optional sections below (insert ABOVE `## Decisions`):>
<- `## Subareas` — when the area contains a named initiative with its own landing note>
<- `## Conventions` — terminology rules and vocabulary specific to this area>
<- `## Open questions` — at the very end>
