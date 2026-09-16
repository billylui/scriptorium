# Security and scope

## What this is not

Scriptorium is **not a security boundary.** It is a correctness guard against an agent that is trying to help and gets the format wrong. It assumes a cooperative agent and a trusted operator.

If your threat model includes an agent or a person actively trying to write bad content, this is the wrong tool and there is no configuration of it that becomes the right one.

## What the guard cannot protect against

Publishing this list matters more than the feature list. **An inert guard and a working guard look identical from the outside** — nothing fires either way — so anyone relying on this deserves to know exactly where the coverage ends.

### 1. Writes that do not go through the agent's file tools

This is the largest gap, and it is structural rather than a bug.

The hook fires on `Write` and `Edit`. It does not fire on:

```bash
cat > note.md <<'EOF'      # heredoc
sed -i '' 's/x/y/' note.md  # in-place edit
python3 -c "open('note.md','w').write(...)"
```

**An agent with shell access bypasses every check by using the shell.** This is not hypothetical — it is the normal way an agent writes a file when it is scripting a bulk change, and bulk changes are exactly when a convention is most likely to be violated at scale.

There is no fix inside the hook contract. Treat the guard as covering the *interactive* write path and use the lint pass for the rest.

### 2. Files arriving from anywhere else

Sync services, mobile apps, the editor itself, other agents, MCP servers with filesystem access, `git checkout`, restores from backup. None of these pass through a `PreToolUse` hook on your machine. A vault that syncs between devices is only guarded on the devices running the guard.

### 3. Shape, not truth

Every check is about **well-formedness**. The guard will happily accept a perfectly formatted note that is completely wrong, and it has no opinion about whether the agent understood you.

### 4. Its own failure modes

The hook exits silently and lets the write through when `jq` or `python3` is missing, when no `.scriptorium.json` is found above the file, or when the config disables a check. This is deliberate — see *Fail-closed on detection, fail-open on failure* in [`ARCHITECTURE.md`](ARCHITECTURE.md) — but it means **absence of refusals is not evidence of coverage.**

### 5. Heuristic checks

The hard-wrap check infers intent from line geometry: a line is flagged when it plus the next line's first word would have crossed a column boundary. Deliberate short lines that happen to look like wraps are missed, and the threshold is a judgment call rather than a law of nature.

### 6. The trust-boundary law is a law, not a check

`untrusted_folders` marks content that must be treated as data and never as instruction. **Nothing enforces that.** It is a rule the agent follows, which is precisely the category of thing this project argues is unreliable. It is documented in `LAWS.md` as a law because no one has written the check, not because it is softer.

## Verify the guard is actually running

Do this after install, and again after changing the config. It takes ten seconds.

Ask your agent to write a file the guard should refuse — a stray markdown file at your vault root, assuming that basename is not in `root_allowlist`:

```
Write "test" to <your-vault>/probe.md
```

**Expected: the write is refused, with a reason naming the root-allowlist rule.**

If it succeeds, the guard is not running. Check that the plugin is installed, that `.scriptorium.json` sits at your vault root, and that `jq` is on your `PATH`. Delete `probe.md` if it was created.

Repeat this whenever you would otherwise assume you are protected. A guard is only ever as good as the last time you saw it say no.

## Reporting a problem

Open an issue. Do not include vault content, absolute paths from your machine, or anything from a private note — a redacted repro is more useful anyway, and this project's whole premise is that personal material leaks through channels nobody was watching.

If you find a way for the guard to pass a write it should refuse, that is an ordinary bug, not a vulnerability. Say what you wrote and what you expected.
