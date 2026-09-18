# Changelog

Notable changes to this project. Versions follow [SemVer](https://semver.org/); for a rules project, **major** means a law changed such that a previously-accepted write is now refused.

## [Unreleased]

## [0.6.0] — 2026-09-18

Everything here came from the same always-on Telegram install as 0.5.x.

### Added
- **`channels/telegram/`: three optional scripts for an always-on Telegram bot,** documented in `CHANNELS.md`. They are not part of the guard and nothing installs them.
  - `vault-bot-typing`, a `PreToolUse` hook that keeps Telegram's "typing…" indicator alive while the bot works. The plugin sends it once per message and Telegram clears it after about five seconds, so long work looked like a dead session.
  - `vault-remind`, durable reminders sent straight to Telegram from a file by a once-a-minute job, each to one chat through the bot that set it; a reminder is claimed in the file before it is sent, so nothing is sent twice. Claude Code's `CronCreate` keeps jobs only in the running session, so every reminder the bot set was lost at its next restart.
  - `vault-bot-watchdog`, which restarts the bot when Telegram reports messages still pending across two minutes of checks. A reported fourteen-minute reply was three and a half minutes of work behind 11 to 35 minutes in which the plugin's long poll had silently stopped receiving.
- **`CHANNELS.md`:** how to tell a delivery stall from a slow model using the `<channel>` tag's `ts` and the plugin's MCP log; the `ackReaction` setting and a concrete progress-message rule for the vault's `CLAUDE.md`; disabling `CronCreate CronDelete CronList` in the bot session; a restart loop that re-reads its script on every start; three new troubleshooting rows.

## [0.5.3] — 2026-09-17

### Added
- **`CHANNELS.md`: question menus hang an always-on Telegram session.** With the official Telegram plugin, a multiple-choice follow-up (`AskUserQuestion`) or plan-mode approval renders only in the terminal, so the chat shows nothing and the session waits indefinitely. Neither permission relay nor `--dangerously-skip-permissions` covers it. Documents `--disallowedTools AskUserQuestion EnterPlanMode ExitPlanMode` (verified to remove the tools), the `CLAUDE.md` line that sends questions through `reply` instead, and why an edited loop script needs the tmux session restarted. Tmux bridges such as ccbot already forward questions and are unaffected.

## [0.5.2] — 2026-09-17

### Fixed
- **The leak scanner said `no .leakterms.local` when the file existed but listed no deny terms.** A denylist holding only comments and `!` exemptions checks no names at all, and the message made that look like a missing file rather than an empty list, so the gap was easy to miss. The summary now distinguishes a missing file, a file with no deny terms, and a file with N terms, and both no-terms states print a warning on stderr. Exit codes are unchanged: a warning never blocks a commit, and a real hit still does.
- **Unicode format characters in `.leakterms.local` counted as deny terms or broke real ones.** `strip()` removes whitespace but not format characters (Unicode category Cf) — a byte-order mark, zero-width spaces and joiners, bidi marks, soft hyphens. One at the start of a comment turned it into a "term", so a denylist checking no names reported one and suppressed the warning; one next to a real name meant that name never matched. Each line and each `!` exemption body is now trimmed of whitespace and format characters at both ends, by category rather than a fixed list; the path and label either side of an exemption's `:` are trimmed of format characters only, so an exemption with spaces around its `:` stays inert exactly as before. Characters inside a term are left as written. Invisible characters that are not format characters — variation selectors, the combining grapheme joiner, filler characters — are not trimmed and behave as they did. Denylists without format characters behave exactly as before.

## [0.5.1] — 2026-09-17

### Fixed
- **The hard-wrap check false-positived on multi-line HTML comments.** It tracked fenced code blocks but not comment state, so only a comment's opening line was recognised and every continuation line read as wrapped prose. Found by checking the repo's own files against the rule they publish — the new `CLAUDE.md` template failed it. Regression-tested with a comment that must pass and two genuine wraps that must still be refused.

## [0.5.0] — 2026-09-17

Everything here came from a real install on someone else's machine. Each item is a defect that reached a user.

### Fixed
- **Five of seven templates violated this repo's own `required_frontmatter`** — missing `status` and `created`, and `project.md` had no `type:` at all. Every note created from them broke Law 5 on write.
- **The guard verification was vacuous.** Asked to write a stray root file, an agent following the vault's own instructions helpfully files it in the inbox instead, so the hook never fires and the test passes without proving anything. Both `init` and `verify` now insist on the root path.
- **`CHANNELS.md` said a permission prompt stalls the session.** The Telegram plugin has relayed prompts to chat with Allow/Deny buttons since 0.0.7 — a middle option between stalling and turning permissions off entirely, and the right default for most people.
- **The backtick rule was stated in a way that invited the opposite error.** Backticking links meant to be followed renders them as code and disconnects the note, which is worse and more common than the failure the rule was written for.

### Added
- `CHANNELS.md`: the always-on failure modes. A channel plugin enabled at user scope starts its server in **every** session, and Telegram kills the previous poller on start — so an ordinary `claude` in another folder silently steals the bot. Fix is to disable at user scope and enable per-session with `--settings`. Also: a failed channel server is cached in `mcp-needs-auth-cache.json` and never retried; slash commands are not forwarded over channels; and the agent must be told to use the `reply` tool or answers land in the terminal.
- `SETUP.md`: the Claude Code install command, that the desktop app's login does not carry to the CLI, that a shell with no profile leaves everything off `PATH`, that SSH cannot read the login Keychain, and an honest model-download budget for semantic search — including that the inbox gets indexed.
- `init`: never generate folder wikilinks or placeholder URLs into an index, and populate `landing_note_parents` when scaffolding rather than leaving a check that silently does nothing.

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
