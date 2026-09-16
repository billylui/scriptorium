# ADR-Lite Decisions (MADR conventions)

Significant strategic, operational and structural decisions are logged as MADR-style ADR-lite notes so future-you (and future agents) can reconstruct *why* something was chosen, and compare what was predicted against what happened.

Reference: [adr.github.io/madr](https://adr.github.io/madr/).

## Location & naming

- **Path:** `<TopicNode>/decisions/NNNN-imperative-title.md` — always this path, regardless of how many decisions exist. The `decisions/` folder materializes when the first decision is filed.
- **Number:** 4-digit sequential (`0001`, `0002`, …), **never reused** even after rejection or supersession. A reused number silently rewrites history: an old link that pointed at a rejected option now resolves to an unrelated accepted one.
- **Title:** imperative mood (`use-postgres`, `reject-single-channel-positioning`).
- `type: decision` in frontmatter.
- No landing note required for `decisions/` — the parent topic node's `## Decisions` section catalogs them.

## Frontmatter

- `status: proposed | accepted | rejected | superseded`
- Supersession: `supersedes: "[[NNNN-old]]"` and `superseded-by: "[[NNNN-new]]"`, written on **both** files. Old notes are kept, never deleted — the rejected reasoning is the part that stops you re-litigating the same question in six months. (Single wikilink per line — never comma-joined, which spawns a ghost node.)

## Required sections

1. **Context** — what triggered this, what's at stake.
2. **Options considered** — each with an explicit *why-not*.
3. **Decision** — what was chosen, dated.
4. **Expected outcome** — 30 / 90 / 180-day predictions, which is what makes a later prediction-vs-actual review possible at all.
5. **Review date**.
6. **Related** — cross-links.

Template: `<templates_folder>/decision.md`.

## Which decisions warrant an ADR

Significant ones only: project pivots, protocol changes, structural decisions about the vault itself, anything you would otherwise re-argue from scratch later. Not trivial choices — those stay as daily-note one-liners.

The failure mode in both directions is real. File everything and the folder becomes noise nobody reads; file nothing and you rebuild the same argument annually. The test is whether you would want the *rejected* options back in front of you if the question resurfaced.
