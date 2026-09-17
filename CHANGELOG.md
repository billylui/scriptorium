# Changelog

Notable changes to this project. Versions follow [SemVer](https://semver.org/); for a rules project, **major** means a law changed such that a previously-accepted write is now refused.

## [Unreleased]

## [0.4.0] — 2026-09-17

### Added
- **`/scriptorium:init` now writes the vault's `CLAUDE.md`.** Without it the agent had no instructions and none of the laws applied — the plugin installed a hook and some skills, then left the vault behaving like any other directory. Generated from a template with the vault's own folder names, and lines about folders the vault does not have are dropped rather than left dangling.
- `vault-wrap` skill — the closing pass. The daily loop was missing its third step: nothing synthesised the day, swept the inbox, found orphans, flagged stale projects, or linted what the write-time hook cannot see.
- `init` now sets up search (the two research laws are inert until `search_command` points at something real), creates a `type: profile` hub note, and helps pick starter Areas — while pushing back on over-building.

## [0.3.0] — 2026-09-17

### Added
- `METHOD.md` — the system the conventions belong to: folder taxonomy, projects vs areas by completion criterion, the capture loop, the people system, review cadence, first month.
- `CHANNELS.md` — reaching a vault from Telegram, Discord or iMessage, with the concurrency model and the permission trade-off stated plainly.
- `/scriptorium:init` scaffolds a structure for an empty vault, and deliberately does not impose one on an existing vault.

### Changed
- `leak-scan` exemptions are now per-pattern. The blanket kind is dangerous: exempting a file to allow an intentional folder listing would also disable the name checks, which are the ones that catch real leaks.

## [0.2.0] — 2026-09-17

### Fixed
- **The plugin did not load.** `plugin.json` declared `hooks` and `skills`, but both are auto-discovered at their standard paths; declaring them raised "Duplicate hooks file detected" and the whole plugin failed. The guard ran for nobody. Found by installing it for the first time.
- Setup was not followable: the install command contained a placeholder, and the reader was told to copy files from a versioned cache path that changes on every update.
- Corrected an overstated claim. A comma-joined wikilink does not immediately create a file — it puts a phantom entry in the graph, which becomes a file when clicked. A project about correctness should not overstate its own mechanism.

### Added
- `/scriptorium:init` and `/scriptorium:verify`.
- README now leads with the measured before/after, and carries a diagram.

### Changed
- `folder_landing` now defaults **off** — it enforces a convention Obsidian has no native concept of.
- Removed `userConfig`; it demanded a `vault_path` the design does not use.

## [0.1.0] — 2026-09-16

First release.

### Added
- `PreToolUse` hook enforcing four write-integrity checks: stray root markdown, multi-wikilink YAML, missing folder landing note, hard-wrapped prose. Each refuses the write rather than reporting afterwards.
- `LAWS.md` — 13 laws as rule / what breaks / config key.
- `AUTHORSHIP.md` — protected surfaces, provenance, truth hierarchy. The laws that govern reading a vault an agent wrote.
- `ARCHITECTURE.md`, `SETUP.md` (agent-executable), `SECURITY.md` (what the guard cannot protect against).
- 7 templates, 3 skills, parameterized against `.scriptorium.json`.
- `leak-scan.py` + pre-commit hook; `first-party-inventory.sh`.

### Notes
- The vault root is wherever `.scriptorium.json` lives — there is no path setting.
- Laws 5–13 are agent-held: specifications for checks that do not exist yet, not softer rules.
