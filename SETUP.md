# Setup

**Four commands, then one question-and-answer pass.** Everything you paste below is literal — there is nothing to substitute.

## Requirements

`jq` and `python3` must be on your `PATH`. The hook silently does nothing without them.

```bash
brew install jq          # macOS; python3 already ships with the OS
```

**Claude Code itself:**

```bash
curl -fsSL https://claude.ai/install.sh | bash
claude auth login
```

Two things that cost people an hour:

- **The Claude desktop app's login does not carry to the CLI.** They authenticate separately.
- **If the login shell has no profile** — a fresh account on bash with no `~/.bash_profile` — nothing you install lands on `PATH` in a normal Terminal, and everything appears broken. Create one with Homebrew's `shellenv`, `~/.local/bin` and `~/.bun/bin`.

**`claude auth login` must be run in a terminal on the machine itself.** An SSH session cannot read the login Keychain, so `claude auth status` will report logged-out over SSH even when it is fine locally. `claude plugin …` commands work over SSH regardless.

Obsidian is optional — the laws are about the markdown on disk, so any editor works.

## Install

Paste these into Claude Code, one at a time:

```
/plugin marketplace add billylui/scriptorium
```

```
/plugin install scriptorium@scriptorium
```

Confirm it loaded before continuing:

```
/plugin list
```

You want `scriptorium@scriptorium` showing **enabled**. If it shows an error instead, stop — a plugin that fails to load enforces nothing, and the symptom is identical to having no plugin at all.

## Configure

Open Claude Code **in your vault directory**, then run:

```
/scriptorium:init
```

It looks at your vault, proposes values, asks you three questions, writes `.scriptorium.json` at your vault root, offers to copy the templates, and then **makes the guard refuse a write in front of you** so you can see it working.

That last step is the point. Skip it and you have no idea whether anything is protecting you.

## Search — do this or two laws stay inert

Two laws tell the agent to search the vault before answering. Both do nothing until `search_command` points at a real tool.

**Anything works.** `ripgrep` is fine, already installed, and needs no setup — set `search_command` to an `rg` invocation with `{query}` where the term goes and you are done.

**A semantic search tool** indexes meaning rather than words, which suits a vault you query in natural language. Budget for it honestly:

- It may need Node even if its README offers a Bun install — a `#!/usr/bin/env node` shebang fails without it, and the native postinstall steps need Node too.
- First run downloads models. Expect **1–2.5 GB** total across embedding, reranking and query expansion, and several minutes before the first query returns. A multilingual embedding model is at the top of that range.
- **Your inbox gets indexed too.** Anything you drop there — a medical report, a bank statement — becomes searchable and gets sent to the model when read. Add an ignore rule if that is not what you want.

Whatever you pick, **run it once and confirm it returns results** before relying on it.

## Check it any time

```
/scriptorium:verify
```

Run this after changing `.scriptorium.json`, after updating the plugin, or whenever you are about to rely on it. It attempts a write that should be refused and tells you plainly if it was not.

---

## Doing it by hand

If you would rather not run the command:

1. Copy `.scriptorium.example.json` from this repo to `.scriptorium.json` at your vault root. **The vault root is wherever that file lives** — there is no path setting.
2. Edit the folder names to match yours. Every key is documented inline.
3. Ask your agent to write a markdown file at your vault root with a basename not in `root_allowlist`. It must be refused. If it is not, the guard is not running.

## Setting up someone else's machine

Send them this repo link and tell them to paste the four commands above. `/scriptorium:init` handles the vault-specific decisions by asking, so you do not need to know how their vault is organised.

The only things you cannot do for them are below.

---

## What you must do yourself

**`claude auth login`** — interactive browser sign-in. Also note the credential expires roughly every 30 days from each login, machine-wide, and does not roll forward on use. Put a reminder in your calendar.

**Decide about `--dangerously-skip-permissions`** — if you plan to run the agent unattended. It means an incoming message drives an agent with unsupervised access to your filesystem. Defensible on your own hardware; it should be a decision, not something you inherit from a setup guide.

**macOS permission prompts** — Full Disk Access and Automation are GUI-gated. Grant them when asked.

## If something is wrong

| Symptom | Cause |
|---|---|
| Write succeeds that should be refused | Plugin not loaded (`/plugin list`), no `.scriptorium.json` at the vault root, `jq` missing, or that check is off in `checks` |
| Refusals you did not expect | `landing_note_parents` names a folder whose children are not subject folders, or `hard_wrapped_prose` is on for a vault that wraps deliberately. Switch a check off in `checks` — it takes effect immediately, no reinstall |
| `/scriptorium:init` not found | Plugin installed but not loaded; check `/plugin list` for a load error |
