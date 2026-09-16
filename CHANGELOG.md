# Changelog

Notable changes to this project. Versions follow [SemVer](https://semver.org/); for a rules project, **major** means a law changed such that a previously-accepted write is now refused.

## [Unreleased]

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
