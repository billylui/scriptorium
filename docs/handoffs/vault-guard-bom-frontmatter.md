# Vault guard: content starting with a byte-order mark defeats frontmatter and fence detection

**Status:** OPEN · **Opened:** 2026-09-17 · **Owner:** unassigned

`scripts/vault-guard.sh` is the `PreToolUse` hook (matcher `Write|Edit`) that refuses vault-corrupting writes. Several of its content checks look at the very first characters of the content or of a line. When the content begins with a UTF-8 byte-order mark (U+FEFF), those tests miss, and the guard misbehaves in **both** directions: it allows writes it should refuse, and refuses a write it should allow. Confirmed on `main` at `841ed3d` (plugin 0.5.2).

## What already shipped (LIVE — do not redo)

- The same defect shape was fixed in the leak scanner's denylist parsing in PR #1 (0.5.2): `clean()` in `scripts/leak-scan.py` trims whitespace and Unicode format characters (category Cf, which includes U+FEFF) from token edges. That fix does **not** touch `vault-guard.sh`; nothing here has been changed yet.
- 0.5.1 taught check D to track multi-line HTML comment state; that logic is unaffected by this item.

## P2 — Check B allows comma-joined wikilink strings (fail-open)

Check B has two paths, and a leading BOM breaks both.

**Frontmatter path.** It only runs when the content matches `case "$content" in ---*)` (around line 67), and its awk then requires `NR==1 && /^---[[:space:]]*$/` (around line 69). With a leading BOM neither matches, so frontmatter is never scanned. The fallback path below only matches keys listed in `wikilink_keys`, so a comma-joined string on any **other** key — `mentions:`, `attendees:`, `sources:` — passes.

**Fallback (listed-key) path.** It scans every line for `"^[[:space:]]*(" keys "):"` (around line 90) and skips fenced code by toggling on lines matching `/^[[:space:]]*```/` (around line 88). The BOM sits in front of the first line only, so:

- content whose **first line** is a listed key — e.g. an Edit fragment that is just `related: "[[A]], [[B]]"` — is not recognised as that key, and passes;
- content whose first line is a fence opener is not recognised as a fence, so the parser's fence state is inverted for the rest of the content: the closing fence turns skipping **on**, and a real `related: "[[A]], [[B]]"` line after the block is skipped and passes.

A listed key that is *not* on the first line and not after a leading fence is still denied with a BOM (via the fallback message "…on a frontmatter key"), which is why the gap is easy to miss.

**Evidence** (temp vault from `.scriptorium.example.json`, results as no BOM → with a leading U+FEFF):

- Write of frontmatter with `mentions: "[[A]], [[B]]"` → **DENY → allow**
- Write whose entire content is `related: "[[A]], [[B]]"` → **DENY → allow**
- Edit whose `new_string` is a fenced block followed by `related: "[[A]], [[B]]"` → **DENY → allow**
- Write of frontmatter with `related: "[[A]], [[B]]"` on line 3 → DENY → DENY (different message)

**Why it matters.** These are the writes the check exists to stop: Obsidian parses the whole string as one link target and a ghost node appears at the vault root immediately. Content with a BOM reaches the Write and Edit tools when an agent copies text from a file saved by a Windows editor or an importer.

## P2 — Check D refuses valid frontmatter as hard-wrapped prose (false refusal)

**Problem.** Check D's embedded Python sets `fm = bool(lines) and lines[0].strip() == "---"` (around line 150). `str.strip()` does not remove U+FEFF, so with a BOM the frontmatter is treated as prose, and a long YAML value continued on an indented line — valid YAML, a multi-line plain scalar — looks like a wrap.

**Evidence.** Write of `---`, `type: log`, `summary: <text long enough to reach the wrap boundary>`, `  <indented continuation>`, `---`, body. PyYAML parses that frontmatter into `{type, summary}`. No BOM → allow; leading U+FEFF → **DENY** ("hard-wrapped prose detected").

**Why it matters.** A false refusal on legitimate content pushes people to switch the check off, and then it protects nothing.

## Fix (all items together)

Normalise once, at the single point content enters the checks, rather than patching each comparison: strip a leading U+FEFF from `content` immediately after this line near the top of the script (around line 40):

```
content="$(printf '%s' "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null)"
```

Every content check reads `$content` from there (check B's `case` and both awk scripts, check D's Python), and checks A and C only look at the file path, so this one change covers all the sites above. Decide deliberately whether to also trim other Cf characters before the first line (to match `clean()` in `leak-scan.py`) and state the choice in the CHANGELOG.

Before fixing, enumerate every content-position comparison and record the list in the PR, so the choke-point claim is checked rather than assumed. A starting grep — extend it if it misses anything you find by reading:

```bash
grep -nE 'NR==1|lines\[0\]|case "\$content"|\^---|\^\[\[:space:\]\]\*|"\$content"' scripts/vault-guard.sh
```

**Files.** `scripts/vault-guard.sh`, `CHANGELOG.md`, both version fields.

**Done when.** Every no-BOM/BOM pair in the probe below gives the same result as its no-BOM line (the four check B shapes are denied, the indented frontmatter is allowed); every existing refusal still fires (stray root `.md`, comma-joined links on listed and unlisted keys, a genuine hard wrap in body prose, a wrap immediately after a multi-line comment); `/scriptorium:verify` passes in a real vault.

## Re-verify ground truth before acting

From the repo root. The probe builds a throwaway vault from `.scriptorium.example.json` and pipes `PreToolUse` JSON straight into the hook, so no Claude session or real vault is involved. It first checks the hook is actually working — `vault-guard.sh` exits silently, allowing everything, when `jq` is missing or no config is found, which would make every pair look "fixed":

```bash
python3 - <<'PY'
import json, shutil, subprocess, sys, tempfile
from pathlib import Path
if not shutil.which("jq"):
    sys.exit("jq is not on PATH: vault-guard.sh allows everything without it, so this probe would prove nothing")
vault = Path(tempfile.mkdtemp())
shutil.copy(".scriptorium.example.json", vault / ".scriptorium.json")
(vault / "Notes").mkdir()
def guard(tool, content):
    ti = {"file_path": str(vault / "Notes" / "probe.md")}
    if tool == "Write":
        ti["content"] = content
    else:
        ti.update(old_string="placeholder", new_string=content)
    out = subprocess.run(["scripts/vault-guard.sh"], input=json.dumps({"tool_name": tool, "tool_input": ti}),
                         capture_output=True, text=True).stdout.strip()
    return "allow" if not out else "DENY: " + json.loads(out)["hookSpecificOutput"]["permissionDecisionReason"][:60]
if guard("Write", "stray") != "allow" or not guard("Write", '---\ntype: log\nmentions: "[[A]], [[B]]"\n---\n').startswith("DENY"):
    sys.exit("the hook did not refuse a known-bad write: probe environment is broken, results would be meaningless")
BOM = "﻿"
cases = [
    ("B frontmatter, unlisted key", "Write", '---\ntype: log\nmentions: "[[A]], [[B]]"\n---\n\nBody.\n'),
    ("B listed key on first line", "Write", 'related: "[[A]], [[B]]"\n'),
    ("B fence then listed key", "Edit", '```\nexample\n```\nrelated: "[[A]], [[B]]"\n'),
    ("B frontmatter, listed key", "Write", '---\ntype: log\nrelated: "[[A]], [[B]]"\n---\n\nBody.\n'),
    ("D indented frontmatter", "Write", "---\ntype: log\nsummary: this frontmatter value is deliberately long enough that it reaches the wrap\n"
                                        "  boundary and continues on an indented continuation line here\n---\n\nBody on one line.\n"),
]
for label, tool, text in cases:
    print(f"{label:30} no BOM: {guard(tool, text):62} BOM: {guard(tool, BOM + text)}")
PY
```

Expected on `841ed3d`: the probe does not exit early; the first three lines are `DENY` without a BOM and **`allow`** with one; `B frontmatter, listed key` is `DENY` on both sides (different messages); `D indented frontmatter` is `allow` without a BOM and **`DENY`** with one. If the probe exits early, fix the environment first — do not read anything into the results. The items count as fixed only when every line's BOM result equals its no-BOM result; then mark this doc DONE here and in `README.md`.

Per the repo `CLAUDE.md`, read `CONTRIBUTING.md` before editing `vault-guard.sh`: any modified check must be seen to refuse something before it ships, and installed copies only update when `version` is bumped in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. Open a PR; `main` is not pushed directly.
