# Handoffs

Open follow-up work that a fresh session can pick up without the conversation that found it. Each doc states what already shipped (so it is not redone), each open item as Problem / Why / Fix / Files with evidence, and the exact commands to re-verify the current state before acting — the evidence is a snapshot, so re-check it.

When an item ships, flip its status in the doc and in this index in the same PR. When every item in a doc is done, mark the doc DONE or delete it.

| Topic | Priority | Status | Opened |
|---|---|---|---|
| [Vault guard: BOM defeats frontmatter and fence detection](vault-guard-bom-frontmatter.md) — a leading byte-order mark makes check B allow comma-joined wikilink strings, and makes check D both refuse valid content (frontmatter, a leading comment) and allow wrapped prose after a leading fence; fix once at the content choke point | P2 | OPEN | 2026-09-17 |
| [Channels: Telegram script follow-ups](channels-telegram-followups.md) — the scripts' tests are not in the repo; a watchdog restart loses the conversation (resume via `--resume <id>`, unverified with `--channels`); the watchdog has not yet been seen to fire on a real stall | P3 | OPEN | 2026-09-18 |
| [Leak scan: denylist edge cases](leak-scan-denylist-edge-cases.md) — terms starting or ending with punctuation, and names ending in a combining mark (Devanagari, decomposed accents), fail to match in ordinary text — the fix is a boundary design decision, fail-closed recommended (P2); unreadable/UTF-16 denylist traceback, non-format invisible characters, nondeterministic hit order (P3) | P2 / P3 | OPEN | 2026-09-17 |
