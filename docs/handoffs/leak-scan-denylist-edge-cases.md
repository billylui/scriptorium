# Leak scan: denylist edge cases

**Status:** OPEN · **Opened:** 2026-09-17 · **Owner:** unassigned

`scripts/leak-scan.py` is the pre-commit gate that keeps personal material out of this public repository (`.githooks/pre-commit` runs it; install with `git config core.hooksPath .githooks`). It has two layers: built-in structural patterns, and deny terms read from the gitignored `.leakterms.local`. Everything below concerns the second layer — the only one that catches a name. Four independent items, ordered by priority; each can ship as its own PR.

## What already shipped (LIVE — do not redo)

- **PR #1, merged as `841ed3d`, released as 0.5.2.** The summary distinguishes a missing denylist, a denylist with no deny terms, and a denylist with N terms, and both no-terms states warn on stderr (exit codes unchanged). A new `clean()` trims whitespace and Unicode format characters (category Cf — byte-order mark, zero-width spaces and joiners, bidi marks, soft hyphen) from both ends of every denylist token: the line, the `!` exemption body, and the glob and label of `!glob:label` (glob/label trim Cf only, so an exemption with spaces around `:` stays inert as before).
- Verification at merge: a red-then-green behaviour check of 13 cases / 22 assertions in throwaway git repos; reviewer-authored harnesses showed 21 adversarial inputs correct and 0 outcome differences across 13 ordinary denylist variants versus the pre-change scanner. Review records: two-seat panel over three checkpoints, 0 blocker/should-fix at the final round.
- **Not a defect, do not "fix":** a zero-width character *inside* a term (e.g. `Al` + U+200B + `ice`) is kept as written — `clean()` only trims token edges, deliberately.

## P2 — Deny terms that start or end with punctuation never match

**Problem.** Terms are joined into `r"(?i)\b(?:" + "|".join(re.escape(t) for t in custom) + r")\b"` (`scripts/leak-scan.py`, the `pats["private-term"]` line in `main()`). `\b` needs a word/non-word transition, so a term whose first or last character is not a word character — `C++`, `.NET`, `@handle`, `Acme!` — can never match next to a space, punctuation or line end. The term is still counted, so the summary reports `N local terms` for names that are not being checked.

**Evidence (main at `841ed3d`).** A denylist of `C++`, `.NET`, `@nicky`, `Acme!` against a tracked file containing `we use C++ and .NET; ping @nicky; Acme! rocks` → `leak-scan: clean (1 files, 7 built-in patterns, 4 local terms)`, exit 0. Control: denylist `rocks` on the same file → exit 1.

**Why it matters.** Handles, company names with punctuation and product names are exactly the terms people list. A silent non-match on a gate that reports the term as counted is the failure this project exists to prevent.

**Fix.** Build per-term boundaries: use `(?<!\w)` before a term only when its first character is a word character, and `(?!\w)` after only when its last character is one (or apply lookarounds unconditionally and prove ordinary word terms match the same inputs as before). Keep `(?i)`. Consider warning at load time about any term that still cannot match.

**Files.** `scripts/leak-scan.py` (`main()`, pattern construction), `CHANGELOG.md`, both version fields.

**Done when.** Each of the four terms above blocks the example file; an ordinary word term blocks and does not match inside a longer word (`Alice` vs `Alicent`) exactly as before; a clean tree still exits 0.

## P3 — Unreadable or non-UTF-8 denylist crashes with a raw traceback

**Problem.** `terms()` calls `f.read_text(encoding="utf-8")` with no error handling. A `.leakterms.local` that is a directory, unreadable, UTF-16 (Windows Notepad's "Unicode" save) or contains invalid UTF-8 raises out of the script.

**Evidence (main at `841ed3d`).** Directory → `IsADirectoryError`, exit 1. Mode 0000 → `PermissionError`, exit 1. UTF-16 → `UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff in position 0`, exit 1. Latin-1 byte `\xe9` → `UnicodeDecodeError`, exit 1.

**Why it matters.** It fails closed (the commit is blocked), which is correct, but a multi-line Python traceback from a pre-commit hook reads as a broken tool and invites `--no-verify`. Behaviour is unchanged from before 0.5.2.

**Fix.** Catch `OSError` and `UnicodeDecodeError` in `terms()` and exit 1 with one plain line naming the file and the cause (e.g. "`.leakterms.local` is not readable UTF-8 — re-save it as UTF-8"). Keep it a failure: do **not** fall back to scanning without the denylist.

**Files.** `scripts/leak-scan.py` (`terms()`).

**Done when.** All four inputs above exit 1 with a single-line message and no traceback; valid denylists are unaffected.

## P3 — Invisible characters that are not format characters still create phantom terms

**Problem.** `clean()` trims whitespace and category Cf only. Other invisible or near-invisible characters are in other categories: variation selectors (e.g. U+FE0F, category Mn), the combining grapheme joiner (U+034F, Mn), the Hangul filler (U+3164, Lo).

**Evidence (main at `841ed3d`).** Denylist line U+FE0F + `# only a comment` → `1 local term`, no warning, exit 0. Denylist line U+034F + `Alice` against a file containing `hello Alice` → exit 0 (the name is not blocked). This is documented as out of scope in the 0.5.2 CHANGELOG entry.

**Why it matters.** Lower likelihood than a BOM, same failure shape: the count claims coverage that does not exist.

**Fix — decide first.** Options: (a) trim a small explicit set of known-invisible non-Cf characters at token edges; (b) instead of trimming, warn when a token's first or last character is not a letter, digit or ordinary punctuation. Do **not** trim category Mn wholesale — combining marks are legitimate at the end of words in many scripts. Record the decision in the CHANGELOG.

**Files.** `scripts/leak-scan.py` (`clean()` or `terms()`).

## P3 — Hit order is nondeterministic

**Problem.** Hits on one line are collected from a set: `for m in {mm.group(0) for mm in re.finditer(pat, line)}:` in `main()`. Set iteration order depends on the string hash seed.

**Evidence (main at `841ed3d`).** The same file and denylist (five terms on one line) run with `PYTHONHASHSEED` 1, 2, 3, 4 reported the five hits in four different orders.

**Why it matters.** Cosmetic, but it makes output diffs noisy and any future golden-output test flaky.

**Fix.** Deduplicate while preserving first-occurrence order, e.g. `dict.fromkeys(mm.group(0) for mm in re.finditer(pat, line))`.

**Files.** `scripts/leak-scan.py` (`main()`).

## Re-verify ground truth before acting

The scanner locates its denylist next to its own copy (`ROOT = Path(__file__).resolve().parent.parent`), so test in throwaway git repos holding a copy of the script — never edit your real `.leakterms.local` to test. From the repo root:

```bash
python3 - <<'PY'
import os, shutil, subprocess, sys, tempfile
from pathlib import Path
SCAN = Path("scripts/leak-scan.py").resolve()
def run(deny, files, as_dir=False, mode=None, env=None):
    d = Path(tempfile.mkdtemp()); (d / "scripts").mkdir()
    shutil.copy(SCAN, d / "scripts" / "leak-scan.py")
    for name, data in files.items():
        (d / name).write_bytes(data)
    subprocess.run(["git", "init", "-q"], cwd=d); subprocess.run(["git", "add", "-A"], cwd=d)
    p = d / ".leakterms.local"
    if as_dir: p.mkdir()
    elif deny is not None: p.write_bytes(deny)
    if mode is not None: os.chmod(p, mode)
    r = subprocess.run([sys.executable, "scripts/leak-scan.py"], cwd=d, capture_output=True, text=True,
                       env={**os.environ, **(env or {})})
    if env:  # order probe: list the reported hit tokens in the order printed
        return " ".join(line.split()[-1] for line in r.stderr.splitlines() if "[private-term]" in line)
    err = (r.stderr.strip().splitlines() or [""])[-1]
    return f"exit={r.returncode} | {r.stdout.strip()} | {err[:100]}"
leaky = {"notes.md": b"we use C++ and .NET; ping @nicky; Acme! rocks\n"}
print("P2 punctuation terms :", run(b"C++\n.NET\n@nicky\nAcme!\n", leaky))
print("   control word term :", run(b"rocks\n", leaky))
print("P3 denylist is a dir :", run(None, {"a.md": b"x\n"}, as_dir=True))
print("P3 unreadable        :", run(b"Name\n", {"a.md": b"x\n"}, mode=0))
print("P3 UTF-16 denylist   :", run("Name\n".encode("utf-16"), {"a.md": b"x\n"}))
print("P3 invalid UTF-8     :", run(b"Caf\xe9\n", {"a.md": b"x\n"}))
print("P3 VS16 + comment    :", run("️# only a comment\n".encode(), {"a.md": b"x\n"}))
print("P3 CGJ + name        :", run("͏Alice\n".encode(), {"n.md": b"hello Alice\n"}))
for seed in "1234":
    print(f"P3 order seed {seed}     :", run(b"Zed\nAlpha\nMike\nBravo\nKilo\n",
          {"n.md": b"Zed Alpha Mike Bravo Kilo\n"}, env={"PYTHONHASHSEED": seed}))
PY
```

Expected on `841ed3d`: P2 exits 0 with `4 local terms` (control exits 1); the four unreadable cases exit 1 with a Python exception as the last stderr line; both non-Cf cases exit 0; the order lines differ. If any item already behaves correctly, it was fixed since — mark it DONE here and in `README.md`.

Per `CONTRIBUTING.md`, any change to this gate must be seen to refuse something before it ships, and per `CLAUDE.md` a fix reaches installed copies only with a version bump in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. Open a PR; `main` is not pushed directly.
