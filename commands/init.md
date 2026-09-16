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

- **Which folders hold subject folders needing a landing note?** Usually the Projects and Areas folders. **Recommend leaving `folder_landing` off for now** — it refuses writes into any folder lacking a landing note, which is disruptive before the structure settles. `METHOD.md` says turn it on at about a month in.
- **Which files or sections do you write yourself, rather than the agent?** A daily-note reflection heading, a journal folder, first-person notes about people. Explain that leaving this empty **silently disables** both the do-not-overwrite rule and the provenance measurement.
- **Which checks do you want on?** For a new vault, all except `folder_landing`. For an existing vault, warn that `hard_wrapped_prose` will refuse writes to notes following a different convention — offer to start it off and turn it on after they have seen what it catches.

## 5. Write the config and templates

Copy `${CLAUDE_PLUGIN_ROOT}/.scriptorium.example.json` to `<vault>/.scriptorium.json` and fill in the answers. Keep the `$comment` lines — they are the only documentation the user will have to hand. Show them the result.

Copy `${CLAUDE_PLUGIN_ROOT}/templates/` into the folder named by `templates_folder`. If files collide, list them and ask.

## 6. Prove the guard fires — do not skip, do not simulate

An inert guard and a working guard are indistinguishable until one says no.

Pick a basename **not** in `root_allowlist` and try to write it at the vault root with the Write tool — for example `scriptorium-probe.md` containing `test`.

- **Refused:** quote the refusal back so they see what one looks like. Confirm no file was created.
- **Succeeded:** the guard is NOT running. Delete the file and say so plainly. Diagnose in order and report which failed: `claude plugin list` shows `scriptorium@scriptorium` **enabled**; `jq . .scriptorium.json` parses; `command -v jq python3` both resolve; the check is not off in `checks`.

## 7. First note, so the vault is not empty

Create today's daily note from the template. If they scaffolded, offer to create one Area for something ongoing in their life, with its landing note — a worked example beats a description.

## 8. Hand over

Four or five lines: which checks are on, that `.scriptorium.json` changes behaviour with no reinstall, that `/scriptorium:verify` re-runs the proof, and where `METHOD.md` is for how to actually run the thing.

Say plainly that writes made through shell commands bypass the guard entirely — that is the largest gap and they should know it on day one, not discover it. Point at `SECURITY.md`.
