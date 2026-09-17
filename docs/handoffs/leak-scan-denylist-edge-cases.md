# Leak scan: denylist edge cases

**Status:** OPEN · **Opened:** 2026-09-17 · **Owner:** unassigned

`scripts/leak-scan.py` is the pre-commit gate that keeps personal material out of this public repository (`.githooks/pre-commit` runs it; install with `git config core.hooksPath .githooks`). It has two layers: built-in structural patterns, and deny terms read from the gitignored `.leakterms.local`. Everything below concerns the second layer — the only one that catches a name. Four independent items, ordered by priority; each can ship as its own PR.

## What already shipped (LIVE — do not redo)

- **PR #1, merged as `841ed3d`, released as 0.5.2.** The summary distinguishes a missing denylist, a denylist with no deny terms, and a denylist with N terms, and both no-terms states warn on stderr (exit codes unchanged). A new `clean()` trims whitespace and Unicode format characters (category Cf — byte-order mark, zero-width spaces and joiners, bidi marks, soft hyphen) from both ends of every denylist token: the line, the `!` exemption body, and the glob and label of `!glob:label` (glob/label trim Cf only, so an exemption with spaces around `:` stays inert as before).
- Verification at merge: a red-then-green behaviour check of 13 cases / 22 assertions in throwaway git repos; reviewer-authored harnesses showed 21 adversarial inputs correct and 0 outcome differences across 13 ordinary denylist variants versus the pre-change scanner. Review: two-seat panel over three checkpoints, 0 blocker/should-fix at the final round.
- **Not a defect, do not "fix":** a zero-width character *inside* a term (e.g. `Al` + U+200B + `ice`) is kept as written — `clean()` only trims token edges, deliberately.

## P2 — Deny terms whose first or last character is not a regex word character fail to match

**Problem.** Terms are joined into `r"(?i)\b(?:" + "|".join(re.escape(t) for t in custom) + r")\b"` (`scripts/leak-scan.py`, the `pats["private-term"]` line in `main()`, around line 150). `\b` needs a word/non-word transition at each end. When a term's first or last character is not a word character — `C++`, `.NET`, `@examplehandle`, `Acme!` — that edge only matches if the neighbouring character in the text *is* a word character. So `C++` matches inside `C++11` but not in `we use C++ here`, and `.NET` matches inside `ASP.NET Core` but not in `we use .NET; x`. The term is still counted, so the summary reports `N local terms` for names that mostly are not being caught.

**The same failure hits real names ending in a combining mark.** Python's `\w` does not match combining marks (category Mn/Mc), so a name whose last character is one — most Devanagari words (`नमस्ते` ends in U+0947, `हिंदी` in U+0940), many Indic and Southeast Asian scripts, and Latin names typed in decomposed form (`Zoë` as `e` + U+0308) — gets a trailing `\b` that can only match before another word character. These names never match in ordinary text today.

**Evidence (main at `841ed3d`).** Each punctuation term alone against a tracked file containing `we use C++ and .NET; ping @examplehandle; Acme! rocks` → `leak-scan: clean (1 files, 7 built-in patterns, 1 local term)`, exit 0, for all four. Control: the word term `rocks` → exit 1. Denylist `नमस्ते` against `नमस्ते दुनिया`, `हिंदी` against `मैं हिंदी बोलता हूँ`, and decomposed `Zoë` against `hello Zoë today` → exit 0 for all three.

**Why it matters.** Handles, company names with punctuation, product names and names in non-Latin scripts are exactly the terms people list. A gate that counts a term it cannot match reports coverage it does not have — and for the combining-mark case, the silently unprotected terms are people's names.

**Fix.** Replace the fixed `\b…\b` with a per-term boundary that treats letters, digits, `_` **and combining marks** as word characters. Python's `re` has no `\p{M}`, so either (a) build the pattern without boundaries and filter each candidate match in Python — reject it if the character just before a word-edged start, or just after a word-edged end, is `\w` or has `unicodedata.category(c)` starting with `M` — or (b) generate an explicit character class for combining marks from `unicodedata` once at load. "Word-edged" means the term's own first/last character is `\w` or a combining mark; a punctuation-edged side gets no boundary check at all. Test edges with `re.match(r"\w", c)` plus the category check, not `str.isalnum()` — they differ on `_`, and `isalnum()` would make the term `_priv` newly match inside `my_priv`.

**Do not** apply `(?<!\w)` / `(?!\w)` to every term unconditionally: that fixes the ordinary-text case but *stops* matches that block today — `.NET` in `ASP.NET Core`, `C++` in `C++11`, `@examplehandle` in `bob@examplehandle` would all pass. On a leak gate that narrowing is a regression. And do not test edges with `\w` alone: that classifies `नमस्ते` as punctuation-edged and would let it match inside a longer word.

**Files.** `scripts/leak-scan.py` (`main()`, pattern construction), `CHANGELOG.md`, both version fields.

**Done when.** Each punctuation-edged term, **tested alone**, blocks the ordinary-text file above; the three combining-mark names block their sentences, and `नमस्ते` does not match inside a longer word such as `नमस्तेजी`; every match that blocks today still blocks (`C++` in `C++11`, `.NET` in `ASP.NET Core`, `@examplehandle` in `bob@examplehandle`); word terms are unchanged (`Alice` blocks `hello Alice`, not `Alicent`; `_priv` blocks `x _priv y`, not `my_priv`); a clean tree still exits 0.

## P3 — Unreadable or non-UTF-8 denylist crashes with a raw traceback

**Problem.** `terms()` calls `f.read_text(encoding="utf-8")` (around line 90) with no error handling. A `.leakterms.local` that is a directory, unreadable, UTF-16 (Windows Notepad's "Unicode" save) or contains invalid UTF-8 raises out of the script.

**Evidence (main at `841ed3d`).** Directory → `IsADirectoryError`, exit 1. Mode 0000 → `PermissionError`, exit 1. UTF-16 → `UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff in position 0`, exit 1. Latin-1 byte `\xe9` → `UnicodeDecodeError`, exit 1.

**Why it matters.** It fails closed (the commit is blocked), which is correct, but a multi-line Python traceback from a pre-commit hook reads as a broken tool and invites `--no-verify`. Behaviour is unchanged from before 0.5.2.

**Fix.** Catch `OSError` and `UnicodeDecodeError` in `terms()` and exit 1 with one plain line naming the file and the cause (e.g. "`.leakterms.local` is not readable UTF-8 — re-save it as UTF-8"). Keep it a failure: do **not** fall back to scanning without the denylist.

**Files.** `scripts/leak-scan.py` (`terms()`).

**Done when.** All four inputs above exit 1 with a single-line message on stderr and no traceback; valid denylists are unaffected.

## P3 — Invisible characters that are not format characters still create phantom terms

**Problem.** `clean()` trims whitespace and category Cf only. Some invisible or near-invisible characters are in other categories: variation selectors (e.g. U+FE0F, category Mn), the combining grapheme joiner (U+034F, Mn), the Hangul filler (U+3164, Lo).

**Evidence (main at `841ed3d`).** Denylist line U+FE0F + `# only a comment` → `1 local term`, no warning, exit 0. Denylist line U+034F + `Alice` against a file containing `hello Alice` → exit 0 (the name is not blocked). This is documented as out of scope in the 0.5.2 CHANGELOG entry.

**Why it matters.** Lower likelihood than a byte-order mark, same failure shape: the count claims coverage that does not exist.

**Fix — decide first.** Trim a small, explicit set of known-invisible non-Cf characters at token edges (variation selectors U+FE00–U+FE0F and U+E0100–U+E01EF, U+034F, U+115F, U+1160, U+3164, U+FFA0), and record the list and the reason in a comment and the CHANGELOG. **Avoid** two tempting alternatives: trimming category Mn wholesale, or warning whenever a term's last character is not a letter, digit or punctuation. Combining marks legitimately end real names — `नमस्ते` ends in U+0947 (Mn), `हिंदी` in U+0940 (Mc), a decomposed `Zoë` in U+0308 (Mn) — so both would mangle or flag genuine terms. (Those names do not *match* today either, but that is the P2 boundary item above, not this one.)

**Files.** `scripts/leak-scan.py` (`clean()`).

**Done when.** Both evidence cases behave like their plain versions (the comment is not a term and the no-terms warning appears; `Alice` blocks); `clean()` returns `नमस्ते`, `हिंदी` and decomposed `Zoë` unchanged (their final combining mark is kept); the 0.5.2 Cf behaviour is unchanged.

## P3 — Hit order is nondeterministic

**Problem.** Hits on one line are collected from a set: `for m in {mm.group(0) for mm in re.finditer(pat, line)}:` in `main()` (around line 168). Set iteration order depends on the string hash seed.

**Evidence (main at `841ed3d`).** The same file and denylist (five terms on one line) run with `PYTHONHASHSEED` 1, 2, 3, 4 reported the five hits in four different orders.

**Why it matters.** Cosmetic, but it makes output diffs noisy and any future golden-output test flaky.

**Fix.** Deduplicate while preserving first-occurrence order, e.g. `dict.fromkeys(mm.group(0) for mm in re.finditer(pat, line))`.

**Files.** `scripts/leak-scan.py` (`main()`).

**Done when.** The order probe prints the same order — the order of first occurrence in the line — for all four seeds, and repeated occurrences of one term on a line are still reported once.

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
text = {"notes.md": b"we use C++ and .NET; ping @examplehandle; Acme! rocks\n"}
for term in ["C++", ".NET", "@examplehandle", "Acme!"]:
    print(f"P2 alone {term:15}:", run(term.encode() + b"\n", text))
print("P2 control word term  :", run(b"rocks\n", text))
keep = {"C++": b"migrating to C++11\n", ".NET": b"built on ASP.NET Core\n", "@examplehandle": b"mail bob@examplehandle\n"}
for term, body in keep.items():
    print(f"P2 must stay blocked {term:15}:", run(term.encode() + b"\n", {"k.md": body}))
print("P2 word: Alice / Alicent :", run(b"Alice\n", {"a.md": b"hello Alice\n"}), "//", run(b"Alice\n", {"a.md": b"Alicent\n"}))
print("P2 word: _priv / my_priv :", run(b"_priv\n", {"a.md": b"x _priv y\n"}), "//", run(b"_priv\n", {"a.md": b"my_priv\n"}))
zoe = "Zoë"
for term, sentence in [("नमस्ते", "नमस्ते दुनिया"), ("हिंदी", "मैं हिंदी बोलता हूँ"), (zoe, f"hello {zoe} today")]:
    print(f"P2 combining-mark name {term!r:12}:", run((term + "\n").encode(), {"t.md": sentence.encode()}))
print("P2 no match inside word  :", run("नमस्ते\n".encode(), {"t.md": "नमस्तेजी\n".encode()}))
print("P3 denylist is a dir  :", run(None, {"a.md": b"x\n"}, as_dir=True))
print("P3 unreadable         :", run(b"Name\n", {"a.md": b"x\n"}, mode=0))
print("P3 UTF-16 denylist    :", run("Name\n".encode("utf-16"), {"a.md": b"x\n"}))
print("P3 invalid UTF-8      :", run(b"Caf\xe9\n", {"a.md": b"x\n"}))
print("P3 VS16 + comment     :", run("️# only a comment\n".encode(), {"a.md": b"x\n"}))
print("P3 CGJ + name         :", run("͏Alice\n".encode(), {"n.md": b"hello Alice\n"}))
for seed in "1234":
    print(f"P3 order seed {seed}      :", run(b"Zed\nAlpha\nMike\nBravo\nKilo\n",
          {"n.md": b"Zed Alpha Mike Bravo Kilo\n"}, env={"PYTHONHASHSEED": seed}))
PY
```

Expected on `841ed3d`: the four `P2 alone` lines each exit 0 with `1 local term`, and the control exits 1; the three `must stay blocked` lines exit 1; `Alice` exits 1 then 0, `_priv` exits 1 then 0; the three combining-mark names exit 0 (the defect) and `no match inside word` exits **1** (today's `\b` also lets `नमस्ते` match inside `नमस्तेजी`, because the next character is a word character — the boundary is wrong in both directions for these names); the four unreadable cases exit 1 with a Python exception as the last stderr line; both non-Cf cases exit 0; the four order lines differ. After a fix, compare against that item's **Done when**, not against "the output changed". An item counts as already fixed only if every line for it matches its Done when — a partial fix (for example, only the trailing boundary) turns some `P2 alone` lines to exit 1 but not all.

Per `CONTRIBUTING.md`, any change to this gate must be seen to refuse something before it ships, and per `CLAUDE.md` a fix reaches installed copies only with a version bump in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. Open a PR; `main` is not pushed directly.
