# Contributing

## Read this first

**Never commit personal material.** This project is developed inside a real, private vault, and the whole repository exists because rules that are merely stated get violated. That applies to this one, so it is enforced rather than requested:

```bash
git config core.hooksPath .githooks
cp .leakterms.example .leakterms.local   # then fill it in
```

`scripts/leak-scan.py` now runs on every commit and rejects it on any hit. `.leakterms.local` is gitignored — publishing the list of words you are hiding would defeat the exercise.

**A clean run means "no known pattern matched", not "reviewed."** The built-in patterns catch structural leaks — home paths, tokens, private decision-register citations, literal numbered folders. Your denylist catches named ones. Neither catches a paraphrase, and the terms people forget are the ones they do not think of as sensitive. In this repository's own first pass, a hand-written denylist passed seven files that a careful read then found leaks in. Read your diff.

## Demonstrate the red

**Any new guard, check, or config constraint must have been seen to fire.** Break it deliberately, watch it refuse, revert. Say which case you tried, in one line, in the PR.

This is not ceremony. A guard that silently never fires is indistinguishable from a guard that works, and the failure is invisible from the user's side — which is the exact failure this project exists to prevent. A check nobody has watched refuse anything is a check nobody has tested.

## Laws

Laws live in `LAWS.md` and are parameterized by `.scriptorium.json`. Two rules:

**Never name a folder.** Every reference is a config key. If your law needs a value that has no key, add the key to `.scriptorium.example.json` with a `$comment` line and use it consistently.

**State the mechanism, not the rule.** A law says what actually breaks — which parser, which renderer, which resolution step — because an agent that knows *why* a write is refused will also refuse the variant no check catches. "Don't do X" is not a law, it is a preference.

Keep the shape: **Rule / What breaks / Config.**

## Line format

**One paragraph per physical line. Never hard-wrap prose at a column.** Obsidian renders a single newline as a visible break mid-sentence, and these files get read inside Obsidian. The repository's own prose is checked against the rule it publishes; a hard-wrapped contribution to a project about not hard-wrapping will be sent back.

Deliberate `**Label:** value` single-newline stacks are fine.

## Agent-written contributions

Agent-assisted PRs are welcome — this project exists because of agent-written prose, so refusing them would be strange.

Two conditions. **You have read the diff and can explain every line**, including the ones you did not write; and the PR says which parts were agent-generated. A PR whose author cannot answer "why this check and not the simpler one" is a review burden transferred, not work contributed.

An agent that has read `LAWS.md` will produce something close to house style. One that has not usually produces a plausible-looking check that has never refused anything — see *Demonstrate the red* above.

## Scope

In scope: new checks, sharper mechanism explanations, harness portability, false-positive fixes.

Out of scope: anything that requires the guard to understand *content* rather than *shape*, and anything that makes it a security boundary. See [`SECURITY.md`](SECURITY.md) — that line is deliberate and moving it would misrepresent what this does.

## What to expect from the maintainer

**This is a published artifact of a working system, not a supported product.** Issues are welcome as signal and may sit. PRs may sit longer. If you need a guarantee, fork it — that is a genuine suggestion, not a brush-off.

If you have found a case where the guard passes a write it should refuse, say so plainly with a repro. That is the most useful thing anyone can send.
