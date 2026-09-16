---
description: Prove the Scriptorium guard is actually running by making it refuse a write
---

Verify the guard is live in the user's vault. This takes about ten seconds and should be re-run after any config change.

## 1. Locate the config

Find `.scriptorium.json` by walking up from the current directory. That directory is the vault root. If none is found, stop: outside a configured vault the hook is inert by design, and there is nothing to verify.

Report the vault root and which checks are enabled.

## 2. Make it say no

Pick a basename **not** in `root_allowlist` and attempt to write it at the vault root with the Write tool, containing the text `test`.

## 3. Report honestly

- **Refused** — quote the reason. Confirm the file does not exist. The guard is live.
- **Succeeded** — the guard is **not** running. Delete the file. Do not soften this: the user believes they are protected and they are not.

Then diagnose in order and report which check failed:
1. `claude plugin list` — is `scriptorium@scriptorium` present and `enabled`? A plugin that fails to load reports an error here.
2. `jq . <vault>/.scriptorium.json` — does it parse?
3. `command -v jq` and `command -v python3` — both are required; the hook fails open without them.
4. Is the check itself switched off in `checks`?

## 4. State the limits

Whatever the result, remind the user that this verifies one check on the `Write` path only. It does not prove the other checks work, and it says nothing about writes made through shell commands, sync, or another editor — those bypass the hook entirely. See `SECURITY.md`.
