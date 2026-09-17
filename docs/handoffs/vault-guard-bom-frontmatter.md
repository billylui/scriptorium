# Vault guard: content starting with a byte-order mark defeats frontmatter detection

**Status:** OPEN · **Opened:** 2026-09-17 · **Owner:** unassigned

`scripts/vault-guard.sh` is the `PreToolUse` hook (matcher `Write|Edit`) that refuses vault-corrupting writes. Two of its checks decide whether a write starts with YAML frontmatter by looking at the very first characters of the content. When the content begins with a UTF-8 byte-order mark (U+FEFF), neither sees `---`, and the guard misbehaves in **both** directions: it allows a write it should refuse, and refuses a write it should allow. Confirmed on `main` at `841ed3d` (plugin 0.5.2).

## What already shipped (LIVE — do not redo)

- The same defect shape was fixed in the leak scanner's denylist parsing in PR #1 (0.5.2): a new `clean()` in `scripts/leak-scan.py` trims whitespace and Unicode format characters (category Cf, which includes U+FEFF) from token edges. That fix does **not** touch `vault-guard.sh`; nothing here has been changed yet.
- 0.5.1 taught check D to track multi-line HTML comment state; that logic is unaffected by this item.

## P2 — Check B allows a comma-joined wikilink string on an unlisted key (fail-open)

**Problem.** Check B has two paths. The frontmatter path only runs when the content matches `case "$content" in ---*)` (around line 67), and its awk then requires `NR==1 && /^---[[:space:]]*$/` (around line 69). With a leading BOM, both fail, so frontmatter is never scanned. The fallback path only matches keys listed in `wikilink_keys` (around line 86). A comma-joined string on any **other** key — `mentions:`, `attendees:`, `sources:` — passes.

**Evidence.** In a temp vault with the example config, a Write of `---`, `type: log`, `mentions: "[[A]], [[B]]"`, `---`, `Body.`:
- without a BOM → **denied** ("multi-wikilink YAML string in frontmatter");
- with a leading U+FEFF → **allowed**.
A listed key (`related: "[[A]], [[B]]"`) is still denied with a BOM, but via the fallback message ("…on a frontmatter key"), which is why the gap is easy to miss.

**Why it matters.** This is the write the check exists to stop: Obsidian parses the whole string as one link target and a ghost node appears at the vault root immediately. Content with a BOM reaches the Write tool when an agent copies text from a file saved by a Windows editor or an importer.

## P2 — Check D refuses valid frontmatter as hard-wrapped prose (false refusal)

**Problem.** Check D's embedded Python sets `fm = bool(lines) and lines[0].strip() == "---"` (around line 150). `str.strip()` does not remove U+FEFF, so with a BOM the frontmatter is treated as prose, and a long YAML value continued on the next line looks like a wrap.

**Evidence.** Same temp vault, a Write whose frontmatter has `summary:` followed by a value long enough to reach the wrap boundary, continued on the next line (indented or not):
- without a BOM → allowed;
- with a leading U+FEFF → **denied** ("hard-wrapped prose detected").

**Why it matters.** A false refusal on legitimate content trains people to switch checks off; `CONTRIBUTING.md` treats a guard that fires on nothing wrong as worse than no guard.

## Fix (both items together)

Normalise once, at the single point content enters the checks, rather than patching each comparison: strip a leading U+FEFF from `content` right after it is extracted with `jq` (the `content="$(printf '%s' "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty')"` line near the top). Then the `case`, the awk `NR==1` test and the Python `lines[0]` test all see `---`. Decide deliberately whether to also trim other Cf characters before the first `---` (match `clean()` in `leak-scan.py` for consistency) and state the choice in the CHANGELOG.

Before fixing, enumerate every content-position comparison in the script (`grep -nE 'NR==1|lines\[0\]|case "\$content"|\^---' scripts/vault-guard.sh`) so no third site is missed; record the list in the PR. Checks A (path only) and C (path only) do not read content.

**Files.** `scripts/vault-guard.sh`, `CHANGELOG.md`, both version fields.

**Done when.** With a leading BOM, the unlisted-key comma-joined write is denied and the wrap-shaped frontmatter is allowed — matching the no-BOM results; every existing refusal still fires (stray root `.md`, comma-joined links on listed and unlisted keys, a genuine hard wrap in body prose, a wrap immediately after a multi-line comment); `/scriptorium:verify` passes in a real vault.

## Re-verify ground truth before acting

From the repo root. The probe builds a throwaway vault from `.scriptorium.example.json` and pipes `PreToolUse` JSON straight into the hook, so no Claude session or real vault is involved:

```bash
python3 - <<'PY'
import json, shutil, subprocess, tempfile
from pathlib import Path
vault = Path(tempfile.mkdtemp())
shutil.copy(".scriptorium.example.json", vault / ".scriptorium.json")
(vault / "Notes").mkdir()
def guard(content, name):
    payload = json.dumps({"tool_name": "Write",
                          "tool_input": {"file_path": str(vault / "Notes" / f"{name}.md"), "content": content}})
    out = subprocess.run(["scripts/vault-guard.sh"], input=payload, capture_output=True, text=True).stdout.strip()
    return "allow" if not out else "DENY: " + json.loads(out)["hookSpecificOutput"]["permissionDecisionReason"][:70]
BOM = "﻿"
unlisted = '---\ntype: log\nmentions: "[[A]], [[B]]"\n---\n\nBody.\n'
listed   = '---\ntype: log\nrelated: "[[A]], [[B]]"\n---\n\nBody.\n'
wrapped_fm = ("---\ntype: log\nsummary: this frontmatter value is deliberately long enough that it reaches the wrap\n"
              "boundary and continues on a plain unindented line here\n---\n\nBody on one line.\n")
for label, text in [("unlisted key", unlisted), ("listed key", listed), ("wrap-shaped frontmatter", wrapped_fm)]:
    print(f"{label:24} no BOM: {guard(text, 'a')}")
    print(f"{label:24} BOM   : {guard(BOM + text, 'b')}")
PY
```

Expected on `841ed3d`: unlisted key — no BOM DENY, BOM **allow**; listed key — DENY both (different messages); wrap-shaped frontmatter — no BOM allow, BOM **DENY**. After the fix every pair should match its no-BOM result. If they already match, the item was fixed since — mark it DONE here and in `README.md`.

Per the repo `CLAUDE.md`, read `CONTRIBUTING.md` before editing `vault-guard.sh`: any modified check must be seen to refuse something before it ships, and installed copies only update when `version` is bumped in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. Open a PR; `main` is not pushed directly.
