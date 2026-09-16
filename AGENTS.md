# Scriptorium

**Fail-closed guardrails for agent-written Obsidian vaults.** A scriptorium was where scribes copied manuscripts under strict rules, with correctors verifying the work before it left the room.

The repository ships three things: a `PreToolUse` hook that refuses four classes of vault-corrupting write before they reach disk, the laws those checks enforce, and a leak scanner that keeps personal material out of published rule text.

**Read [`LAWS.md`](LAWS.md) before writing into a vault.** It is the complete rule set and the specification the hook is written against. The laws are not summarized here — a summary of a law is the failure mode this project exists to prevent.

Laws are parameterized by `.scriptorium.json` at the vault root; copy `.scriptorium.example.json` and edit. The vault root is wherever that file lives, so there is no path to configure. Outside a directory containing one, the hook does nothing and the laws do not apply.

Four further laws are documented separately: AI-Write Boundaries, Provenance and the Truth Hierarchy in [`AUTHORSHIP.md`](AUTHORSHIP.md); Vault Structure in the shape spec named by `shape_spec`.

**Contributing:** never commit personal material. `scripts/leak-scan.py` runs as a pre-commit hook (`git config core.hooksPath .githooks`) and rejects the commit on any hit.
