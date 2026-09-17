---
description: Set up a vault from scratch or adopt an existing one — structure, config, templates, and a live proof the guard works
---

Set up Scriptorium in the user's vault. Read `METHOD.md` in the plugin root first if you have not — you are setting up that system, and the user may ask why a folder exists.

Work in order. Do not skip step 6.

## 1. Find or create the vault

If the working directory looks like a vault (has `.obsidian/`, or markdown in folders), use it. Otherwise ask for the path, or offer to create one. Confirm the path back before writing anything.

If `.scriptorium.json` already exists, say so and ask whether to reconfigure. **Never overwrite it silently** — it encodes decisions you cannot see.

## 2. Decide: scaffold, or adopt?

**Ask which situation applies.** The whole setup differs.

**(a) Empty or near-empty vault — scaffold it.** Create the structure from `METHOD.md`:

```
00-Inbox  01-Daily  02-People  03-Projects  04-Areas
05-Knowledge  06-Resources  07-Archive  08-Templates  09-Attachments
```

Also create `index.md` at the root. Explain as you go, briefly — especially that `00-Inbox/` is the only entry point, and that numeric prefixes make the sidebar sort into workflow order. Do not lecture; two sentences each.

**(b) Existing vault with its own structure — adopt it.** Do **not** impose these folders. List what they have, map their folders onto the config keys, and leave the shape alone. Someone with three years of notes has a working system; your job is to guard it, not restructure it.

## 3. Look before asking

List top-level folders and count `.md` files. Propose values from what you find. A user who just installed this does not yet know what `landing_note_parents` means, and asking cold produces guesses.

## 4. Ask only what you cannot infer

One message, plain questions, each with your proposed answer:

- **Which folders hold subject folders needing a landing note?** Usually the Projects and Areas folders. **If you scaffolded the structure, fill this in from what you created** — leaving it `[]` means the check does nothing even after they switch it on, which is a silent no-op they will not notice. **Recommend leaving `folder_landing` off for now** — it refuses writes into any folder lacking a landing note, which is disruptive before the structure settles. `METHOD.md` says turn it on at about a month in.
- **Which files or sections do you write yourself, rather than the agent?** A daily-note reflection heading, a journal folder, first-person notes about people. Explain that leaving this empty **silently disables** both the do-not-overwrite rule and the provenance measurement.
- **Which checks do you want on?** For a new vault, all except `folder_landing`. For an existing vault, warn that `hard_wrapped_prose` will refuse writes to notes following a different convention — offer to start it off and turn it on after they have seen what it catches.

## 5. Write the config and templates

Copy `${CLAUDE_PLUGIN_ROOT}/.scriptorium.example.json` to `<vault>/.scriptorium.json` and fill in the answers. Keep the `$comment` lines — they are the only documentation the user will have to hand. Show them the result.

Copy `${CLAUDE_PLUGIN_ROOT}/templates/` into the folder named by `templates_folder`. If files collide, list them and ask.

## 6. Write the vault's `CLAUDE.md` — do not skip this

**Without it the agent has no instructions and none of the laws apply.** The plugin installs a hook and some skills; it does not tell the agent how to run the vault. A vault with a structure and an empty `CLAUDE.md` behaves like any other directory.

Generate `<vault>/CLAUDE.md` from `${CLAUDE_PLUGIN_ROOT}/templates/vault-CLAUDE.md`, substituting every `{{placeholder}}` with the values you just wrote into `.scriptorium.json`:

- `{{structure}}` — their actual folders, with a one-line purpose each
- `{{root_allowlist}}`, `{{landing_note_parents}}`, `{{required_frontmatter}}`, `{{day_boundary_hour}}`, `{{inbox_folder}}`, `{{daily_folder}}`, `{{index_filename}}`, `{{protected_surfaces}}`, `{{search_command}}` — from their config
- `{{inbox_line}}` — one sentence on the inbox being the only entry point. Omit if they have no inbox folder
- `{{untrusted_line}}` — the trust-boundary rule naming their `untrusted_folders`. **Omit entirely if that list is empty** rather than leaving a rule about nothing

**Never leave a `{{placeholder}}` in the output**, and never write a law about a folder they do not have. If a key is unset, drop that line — a rule referring to a nonexistent folder teaches the agent to ignore rules.

Show them the result and say plainly: this file is theirs, it loads every session, and anything about how *they* work goes at the bottom.

If a `CLAUDE.md` already exists, **do not overwrite it.** Show what you would add and let them merge.

## 7. Search — the laws depend on it

Two laws tell the agent to search before answering. Both are inert until `search_command` points at something real.

Ask what they want to use. Any tool works — ripgrep is fine and already installed. A semantic search tool indexes better for this kind of vault, at the cost of an install and an index step. Set `search_command` with `{query}` where the term goes, and **verify it returns results before moving on.**

If they have no preference, set ripgrep now so the laws work today, and tell them it is swappable by editing one config line.

## 8. A profile note, and their first Areas

**Profile.** Create one note with `type: profile` as the canonical hub for facts about them — the entry point other notes link to when they need something personal. It should link out to the authoritative note per topic rather than storing everything itself. Exactly one per vault.

**Areas.** Ask what is genuinely ongoing in their life — domains with no finish line. Propose four to six and let them cut the list. Create the folder and its landing note together.

**Push back on over-building.** Three real Areas beat ten speculative ones; the empty ones become clutter that makes the vault feel like a chore. Say so if they start listing aspirations rather than things they actually attend to.

## 9. Prove the guard fires — do not skip, do not simulate

An inert guard and a working guard are indistinguishable until one says no.

Pick a basename **not** in `root_allowlist` and write it at the vault root with the Write tool — for example `scriptorium-probe.md` containing `test`.

⚑ **Insist on the exact path, and do not let good behaviour substitute for the test.** If the vault's `CLAUDE.md` says stray root files belong in the inbox, you will helpfully file it there instead and the hook never fires — which proves the *instructions* work, not the guard. The write must be attempted at the root.

- **Refused:** quote the refusal back so they see what one looks like. Confirm no file was created.
- **Succeeded:** the guard is NOT running. Delete the file and say so plainly. Diagnose in order and report which failed: `claude plugin list` shows `scriptorium@scriptorium` **enabled**; `jq . .scriptorium.json` parses; `command -v jq python3` both resolve; the check is not off in `checks`.

## 10. If you create an index, do not link folders

A root `index.md` is useful. **Write folder names as plain text or backticked paths, never as `[[wikilinks]]`.** A wikilink resolves only to a note basename, so `[[04-Areas]]` resolves to nothing and creates an empty file at the vault root the first time anyone clicks it — Law 1, produced by the setup that is supposed to prevent it.

Link *notes* freely. Never link a folder.

Also: **do not write a placeholder URL.** If you reference `METHOD.md`, link the file in the plugin or name it in text — an unresolved `https://` placeholder in a brand-new vault is the first broken thing they will find.

## 11. First note, so the vault is not empty

Create today's daily note from the template. If they scaffolded, offer to create one Area for something ongoing in their life, with its landing note — a worked example beats a description.

## 12. Hand over

Four or five lines: which checks are on, that `.scriptorium.json` changes behaviour with no reinstall, that `/scriptorium:verify` re-runs the proof, and where `METHOD.md` is for how to actually run the thing.

Say plainly that writes made through shell commands bypass the guard entirely — that is the largest gap and they should know it on day one, not discover it. Point at `SECURITY.md`.
