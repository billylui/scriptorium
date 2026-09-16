# Scriptorium

**Fail-closed guardrails for agent-written Obsidian vaults.**

A `PreToolUse` hook that refuses malformed writes to a markdown vault **before they reach disk**, plus the laws it enforces. For people whose notes are largely written by an AI agent.

## What it refuses

| Check | What goes wrong without it |
|---|---|
| **Stray root markdown** | Files accumulate at the vault root as broken-link debris |
| **Multi-wikilink YAML** | `related: "[[A]], [[B]]"` parses as *one* link target and spawns a ghost note at your vault root |
| **Missing folder landing** | `[[Folder]]` resolves only to `Folder.md` — without it, clicking the link silently creates an empty stub |
| **Hard-wrapped prose** | An 80-column wrap is invisible on GitHub and renders as a mid-sentence `<br>` in Obsidian |

Nine further laws are specified in [`LAWS.md`](LAWS.md) and held by the agent rather than the hook — they are the specification for the checks that should replace them.

## Install

```
/plugin marketplace add <owner>/scriptorium
/plugin install scriptorium@scriptorium
```

Then copy [`.scriptorium.example.json`](.scriptorium.example.json) to `.scriptorium.json` at your vault root and edit it.

**The vault root is wherever that file lives** — there is no path to configure and no environment variable to export. Outside a directory containing one, the hook does nothing, so installing it globally leaves every other directory untouched.

Start with the checks you want and switch the rest off. A check that fires constantly on a vault that does not follow that convention will get the whole plugin uninstalled.

**Installing with an agent:** [`SETUP.md`](SETUP.md) is written to be executed rather than read. Paste this into Claude Code or Codex CLI:

> Read `SETUP.md` from this repo and set it up on my machine. Stop at every step marked **HUMAN** and tell me what to do.

## Verify it is running

**Do this after installing, and again after changing the config.** An inert guard and a working guard look identical — nothing fires either way — so the only way to know is to make it say no.

Ask your agent to write a stray markdown file at your vault root, assuming that basename is not in `root_allowlist`:

```
Write "test" to <your-vault>/probe.md
```

**Expected: refused, with a reason naming the root-allowlist rule.** If it succeeds, the guard is not running — check that the plugin is installed, that `.scriptorium.json` is at your vault root, and that `jq` is on your `PATH`.

---

## Why a hook and not an instruction

A rule was added to a vault's instruction file: *never hard-wrap prose, because Obsidian renders a single newline as a visible line break mid-sentence.* It was written clearly, at the top of the file, in a section the agent reads every session.

**It was violated 27 minutes later.** The next day, over a hundred files needed repairing.

The rule was not unclear and the agent was not careless. The problem is structural: **an instruction is a suggestion with good intentions.** An agent writing hundreds of files will eventually violate any rule it is merely *told*, and markdown corruption is quiet — nothing errors, nothing crashes, and you find out weeks later when a link resolves to a file you never created.

### Prevention, not detection

Other tools validate *after* the write and repair the damage. Scriptorium refuses it.

For some invariants the difference is cosmetic — a wrapped paragraph reflows fine either way. For others it is not: a multi-wikilink YAML string **creates a ghost node the instant it is written**, and the note it spawns carries no record of which file produced it. Repair means reconciling stubs against every link that could have made them. Refusal means the stub never exists.

The lint pass is the backstop. The hook is the mechanism.

**This is not a rivalry with vault-memory projects.** They give an agent somewhere durable to think; this refuses the malformed writes that accumulate in whatever it thinks into. If you already run one, this guards the vault it gave you.

## Limitations

Read [`SECURITY.md`](SECURITY.md) before relying on this. The short version:

- **The hook fires on `Write` and `Edit`.** An agent with shell access bypasses every check with a heredoc or `sed -i` — and bulk shell edits are exactly when a convention gets violated at scale.
- **Nothing else is covered.** Sync services, mobile apps, your editor, other agents, `git checkout`.
- **Shape, not truth.** A perfectly formatted note that is completely wrong passes.
- **It fails open when it cannot run** — no `jq`, no config file, check disabled. Absence of refusals is not evidence of coverage.
- **Not a security boundary.** It assumes a cooperative agent and a trusted operator.

## Documentation

| File | For | Contents |
|---|---|---|
| [`LAWS.md`](LAWS.md) | both | The complete rule set: the mechanism each law prevents, and the config key that parameterizes it |
| [`AUTHORSHIP.md`](AUTHORSHIP.md) | both | Protected surfaces, provenance, and the truth hierarchy — the laws that govern *reading* a vault an agent wrote |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | humans | Where a write is stopped, and which directory owns a change. Diagrams |
| [`SETUP.md`](SETUP.md) | agents | Executable install steps, with the four no agent can do marked **HUMAN** |
| [`SECURITY.md`](SECURITY.md) | both | What the guard cannot protect against |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | both | The leak-scan rule, and "demonstrate the red" |

## Portability

| Component | Works with |
|---|---|
| Laws, skills, templates | Claude Code, Codex CLI, and other [Agent Skills](https://agentskills.io) hosts |
| The `PreToolUse` hook | Claude Code — hook contracts are per-harness, inert elsewhere |

A Codex user gets the laws and the skills and does not get the refusal, which is exactly the gap this project argues matters.

## Status and support

**This is a published artifact of a working system, not a supported product.** It runs daily against a real vault, which is why the rules exist — every one of them was written after something broke.

Issues are welcome as signal and may sit. PRs may sit longer. If you need a guarantee, fork it — that is a genuine suggestion, not a brush-off.

The most useful thing anyone can send is a case where the guard passes a write it should have refused.

## License

[MIT](LICENSE).
