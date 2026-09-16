# Scriptorium

**Fail-closed guardrails for agent-written Obsidian vaults.**

A scriptorium was where scribes copied manuscripts under strict rules, with correctors verifying the work before it left the room. This is that, for an AI agent writing into your notes.

---

## The 27-minute problem

A rule was added to a vault's instruction file: *never hard-wrap prose, because Obsidian renders a single newline as a visible line break mid-sentence.* It was written clearly, at the top of the file, in a section the agent reads every session.

**It was violated 27 minutes later.** The next day, over a hundred files needed repairing.

The rule was not unclear and the agent was not careless. The problem is structural: **an instruction is a suggestion with good intentions.** An agent writing hundreds of files will eventually violate any rule it is merely *told*, and markdown corruption is quiet — nothing errors, nothing crashes, and you find out weeks later when a link resolves to a file you never created.

Scriptorium turns those rules into code that refuses the write.

## What it blocks

Four ways an agent silently corrupts a markdown vault. Each runs on `PreToolUse`, so a bad write **never reaches disk**:

| Check | What goes wrong without it |
|---|---|
| **Stray root markdown** | Files accumulate at the vault root as broken-link debris |
| **Multi-wikilink YAML** | `related: "[[A]], [[B]]"` parses as *one* link target and spawns a ghost note at your vault root |
| **Missing folder landing** | `[[Folder]]` resolves only to `Folder.md` — without it, clicking the link silently creates an empty stub |
| **Hard-wrapped prose** | An 80-column wrap is invisible on GitHub and renders as a mid-sentence `<br>` in Obsidian |

Nine further laws are specified in [`LAWS.md`](LAWS.md) and enforced by the agent rather than the hook — they are the specification for the checks that should replace them.

### Prevention, not detection

Other tools validate *after* the write and repair the damage. Scriptorium refuses it.

For some invariants the difference is cosmetic — a wrapped paragraph reflows fine either way. For others it is not: a multi-wikilink YAML string **creates a ghost node the instant it is written**. Detecting that afterwards means hunting debris across the vault. Refusing it means the debris never exists.

The lint pass is the backstop. The hook is the mechanism.

## Install

```
/plugin marketplace add <owner>/scriptorium
/plugin install scriptorium@scriptorium
```

Then create `.scriptorium.json` at your vault root — copy `.scriptorium.example.json` and edit.

**The vault root is wherever that file lives**, so there is no path to configure and no environment variable to export. Outside a directory containing one, the hook does nothing. Every check is individually switchable, and the folder rules are driven entirely by your own folder names.

## Documentation

| File | Contents |
|---|---|
| [`LAWS.md`](LAWS.md) | The complete rule set: the mechanism each law prevents, and the config key that parameterizes it |
| [`AUTHORSHIP.md`](AUTHORSHIP.md) | Protected surfaces, provenance, and the truth hierarchy — the laws that govern *reading* a vault an agent wrote |
| [`AGENTS.md`](AGENTS.md) | Cross-harness entry point |

## Portability

| Component | Works with |
|---|---|
| Skills, `AGENTS.md`, `LAWS.md` | Claude Code, Codex CLI, and other [Agent Skills](https://agentskills.io) hosts |
| `PreToolUse` hook | Claude Code (hook contracts are per-harness; elsewhere it is inert) |

## Maintenance contract

**This is a published artifact of a working system, not a supported product.** It runs daily against a real vault of a couple of thousand notes, which is why the rules exist — every one of them was written after something broke.

Issues are welcome as signal. PRs may sit. If you need guarantees, fork it.

## License

MIT.
