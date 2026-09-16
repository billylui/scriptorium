@AGENTS.md

## Claude Code

This repository *is* a Claude Code plugin, so two things are worth knowing when working on it.

**Changing a check means changing behaviour for everyone who installs it.** Before editing `scripts/vault-guard.sh`, read [`CONTRIBUTING.md`](CONTRIBUTING.md) — any new or modified check must be seen to refuse something before it ships.

**Bumping `version` in `.claude-plugin/plugin.json` is what actually ships a change.** Installed copies update on the version field, not on a push, so a fix committed without a bump reaches nobody.
