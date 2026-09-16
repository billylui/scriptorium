# `type:` Frontmatter Vocabulary

Universal across the vault. Every `.md` file in a content folder MUST have a `type:` field. Extend the table for your own domains if you need to — but extend it *here*, in one place, rather than inventing a value at write time and hoping the next note agrees.

| Value | Used for |
|---|---|
| `landing` | Folder landing notes (`<Folder>/<Folder>.md`) |
| `decision` | ADR-lite under `<TopicNode>/decisions/` |
| `research` | Externally-sourced findings, synthesized briefings |
| `narrative` | Pitch, positioning, or strategic narrative artifacts |
| `reference` | Stable facts, panels, glossaries, terminology |
| `meeting` | Meeting briefs or recaps |
| `protocol` | A current-state operating procedure you follow and revise |
| `plan` | Forward planning artifact (event plan, project plan) |
| `brief` | Short context-setter for a person, event, or sub-topic |
| `log` | Append-only running log (build log, session log) |
| `synthesis` | Compiled understanding (knowledge-page style) |
| `person` | Contact dossier in the people collection |
| `daily` | Daily note in `<daily_folder>` |
| `profile` | Owner ground-truth hub — the single canonical profile of the vault owner. Exactly one in the vault. |

When inferring `type:` for an existing note, prefer the most specific match. When genuinely ambiguous, use `reference`.

**Canonical order for `## All notes` grouping:** protocol → plan → narrative → brief → meeting → research → synthesis → reference → log. `decision` is never a group there (those live in `## Decisions`). `landing`, `person`, `daily` and `profile` don't appear in a topic-node `## All notes` catalog at all.

The order is not alphabetical and not arbitrary: it runs from what you act on, through what you are building toward, to what you merely keep. A reader scanning the catalog top-down hits the operative notes first.
