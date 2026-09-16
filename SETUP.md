# Setup

**This document is written to be executed by a coding agent.** Paste this into Claude Code, Codex CLI, or any agent with shell access:

> Read `SETUP.md` from https://github.com/<owner>/scriptorium and set this up on my machine. Stop at every step marked **HUMAN** and tell me what to do.

It also works as a human checklist — the steps are the same, an agent just runs them faster. Steps marked **HUMAN** cannot be automated by anyone: they need a browser, a phone, or a decision.

---

## Agent instructions

Work through the steps in order. After each step, run its **Verify** command and confirm the expected result before continuing. If a verify fails, stop and report — do not proceed or work around it.

Never perform a **HUMAN** step. Print exactly what the person must do, wait, then verify.

---

## Step 1 — Prerequisites

```bash
command -v jq python3 git tmux || true
```

Install whatever is missing. On macOS:

```bash
brew install jq git tmux
```

`python3` ships with macOS. On Linux use the system package manager.

**Verify:** `jq --version && python3 --version && git --version` prints three versions.

## Step 2 — Obsidian

Obsidian is optional. Every law here is about the markdown on disk, so the vault works with any editor — but the hard-wrap law exists because of how Obsidian specifically renders single newlines, and the folder-landing law is about how Obsidian resolves `[[wikilinks]]`. Without Obsidian, both still keep the files clean; they just matter less.

```bash
brew install --cask obsidian   # macOS; otherwise download from obsidian.md
```

**Verify:** the app launches, or the person confirms they are using a different editor.

## Step 3 — Install the plugin

In Claude Code:

```
/plugin marketplace add <owner>/scriptorium
/plugin install scriptorium@scriptorium
```

**Verify:** `/plugin list` shows `scriptorium`.

**On Codex CLI or another harness:** there is no plugin mechanism, and the `PreToolUse` hook will not run. Clone the repo instead and point the agent at `LAWS.md` and `AUTHORSHIP.md`; the laws, skills and templates all apply, the automatic refusal does not. See *Portability* in the README.

## Step 4 — Create or choose the vault

If starting fresh, create a directory. If the person already has a vault, use it — nothing here requires an empty one.

```bash
mkdir -p ~/my-vault && cd ~/my-vault
```

**Verify:** `pwd` prints the intended vault path.

## Step 5 — Configure

Copy the example config to the vault root and edit it.

```bash
cp <plugin_root>/.scriptorium.example.json ./.scriptorium.json
```

**The vault root is wherever `.scriptorium.json` lives.** There is no path to set and no environment variable to export.

Fill in the keys that match the person's actual folder names. Every key is documented inline in the example file. **Ask the person about these two rather than guessing:**

- `landing_note_parents` — which folders hold subject folders that each need a landing note. Wrong values here cause spurious refusals.
- `protected_surfaces` — which files or sections they wrote themselves. This drives both the do-not-overwrite rule and the provenance measurement, so an empty list silently disables both. See `AUTHORSHIP.md`.

Start with the checks the person wants and switch the rest off in `checks`. A check that fires constantly on a vault that does not follow that convention will get the whole plugin uninstalled.

**Verify:** `jq . .scriptorium.json` parses without error.

## Step 6 — Confirm the guard is live

Try to write a file the guard should refuse — a stray markdown file at the vault root:

```bash
echo "test" > /tmp/scriptorium-probe.md
```

Then ask the agent to write that content to `<vault>/probe.md`. **The write should be refused with a reason.**

**Verify:** the write is denied and the reason names the root-allowlist rule. If it succeeds, the hook is not running — check `/plugin list` and that `.scriptorium.json` is at the vault root.

Delete `probe.md` if it was created.

## Step 7 — Scaffold the vault (optional)

If the vault is empty, create the folders named in `.scriptorium.json` and copy the templates:

```bash
cp -r <plugin_root>/templates ./<templates_folder>
```

**Verify:** the folders in `landing_note_parents` exist and `<templates_folder>` contains the template files.

## Step 8 — Search (optional)

Laws 9 and 11 reference `search_command` — the content search run before answering a question. Any tool works: ripgrep, a semantic search CLI, or your editor's search. Set `search_command` to the invocation, using `{query}` where the search term goes.

**Verify:** running the configured command with a test term returns results.

---

## HUMAN steps

These need a browser, a phone, or a judgment call. **An agent must not attempt them.**

### HUMAN 1 — Authenticate the agent

```bash
claude auth login
```

Interactive browser OAuth. Nobody can do this for you.

⚠️ **Put a recurring reminder in your calendar.** The credential expires roughly every 30 days from each login, machine-wide, and it does not roll forward on use. Every interactive session on the machine rides it. Unattended jobs die silently when it lapses; interactive sessions show a prompt.

### HUMAN 2 — Decide on permission bypass

Some setups run the agent with permission checks disabled so it can work unattended. **Understand what that means before enabling it:** an inbound message drives an agent with unsupervised access across your filesystem.

That is defensible on your own hardware, for your own vault. It should be a decision you make, not a default you inherit from someone's setup guide.

### HUMAN 3 — Messaging bridge (optional)

If driving the vault from a chat app, create the bot and copy its token yourself. Tokens must not pass through an agent's context.

### HUMAN 4 — OS permissions

macOS gates Full Disk Access and Automation behind GUI prompts. Grant them when asked, in System Settings.

---

## Done

```bash
<plugin_root>/scripts/first-party-inventory.sh
```

Prints how much of the vault its owner actually wrote. On a new vault the answer is everything; the number becomes interesting after a few months, and it is usually lower than expected. `AUTHORSHIP.md` explains why that matters.
