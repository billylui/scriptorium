---
description: Set up Scriptorium in a vault — writes .scriptorium.json, copies templates, verifies the guard fires
---

Set up Scriptorium in the user's vault. Work through this in order and do not skip the verification at the end.

## 1. Find the vault

If the current working directory looks like a notes vault (contains `.obsidian/`, or many `.md` files in folders), use it. Otherwise ask the user for the absolute path. Confirm the path back to them before writing anything.

If `.scriptorium.json` already exists there, say so and ask whether to reconfigure or stop. **Never overwrite it silently** — it is the user's own config and may encode decisions you cannot see.

## 2. Look before you ask

List the vault's top-level folders and count the `.md` files. Use what you find to propose values rather than asking cold — a user who just installed this does not yet know what `landing_note_parents` means, and an empty vault has different answers from one with three years of notes.

## 3. Ask only what you cannot infer

Ask these as plain questions, one message, with your proposed answer for each:

- **Which folders hold subject folders that should each have a landing note?** (e.g. a Projects folder, an Areas folder.) If they have no such structure, leave this empty and the check stays off. Explain that wrong values here cause refusals they will not expect.
- **Which files or sections do they write themselves, rather than the agent?** A daily-note reflection heading, a journal folder, first-person notes about people. Explain that leaving this empty silently disables both the do-not-overwrite rule and the provenance measurement.
- **Which checks do they want on?** Default all four on for a new vault. For an existing vault, warn that `hard_wrapped_prose` will refuse writes to any note that follows a different convention, and offer to start with it off.

## 4. Write the config

Copy `${CLAUDE_PLUGIN_ROOT}/.scriptorium.example.json` to `<vault>/.scriptorium.json` and fill in the answers. Keep the `$comment` lines — they are the only documentation the user will have to hand.

Show them the finished file.

## 5. Copy the templates (offer, do not assume)

Ask whether they want the starter templates. If yes, copy `${CLAUDE_PLUGIN_ROOT}/templates/` into the folder named by `templates_folder`. If that folder already has files with the same names, list the collisions and ask before overwriting.

## 6. Prove the guard actually fires

**Do not skip this and do not simulate it.** An inert guard and a working guard are indistinguishable until one of them says no.

Pick a basename that is *not* in `root_allowlist` and try to write it at the vault root with the Write tool — for example `<vault>/scriptorium-probe.md` containing `test`.

- **If the write is refused:** the guard is live. Quote the refusal reason back to the user so they see what a refusal looks like, then confirm no file was created.
- **If the write succeeds:** the guard is NOT running. Delete the file and tell the user plainly. Then check, in order: `claude plugin list` shows `scriptorium@scriptorium` as `enabled`; `.scriptorium.json` is at the vault root and is valid JSON (`jq . .scriptorium.json`); `jq` is on PATH. Report which one failed rather than guessing.

## 7. Tell them what changed

In three or four lines: which checks are on, where the config lives, that editing `.scriptorium.json` changes behaviour with no reinstall, and that `/scriptorium:verify` re-runs step 6 any time.

Mention that `SECURITY.md` in the repo lists what the guard cannot catch — above all that writes made through shell commands bypass it entirely.
