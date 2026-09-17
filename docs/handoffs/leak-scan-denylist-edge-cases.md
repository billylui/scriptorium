# Leak scan: denylist edge cases

**Status:** OPEN · **Opened:** 2026-09-17 · **Owner:** unassigned

`scripts/leak-scan.py` is the pre-commit gate that keeps personal material out of this public repository (`.githooks/pre-commit` runs it; install with `git config core.hooksPath .githooks`). It has two layers: built-in structural patterns, and deny terms read from the gitignored `.leakterms.local`. Everything below concerns the second layer — the only one that catches a name. Four independent items, ordered by priority; each can ship as its own PR.

## What already shipped (LIVE — do not redo)

- **PR #1, merged as `841ed3d`, released as 0.5.2.** The summary distinguishes a missing denylist, a denylist with no deny terms, and a denylist with N terms, and both no-terms states warn on stderr (exit codes unchanged). A new `clean()` trims whitespace and Unicode format characters (category Cf — byte-order mark, zero-width spaces and joiners, bidi marks, soft hyphen) from both ends of every denylist token: the line, the `!` exemption body, and the glob and label of `!glob:label` (glob/label trim Cf only, so an exemption with spaces around `:` stays inert as before).
- Verification at merge: a red-then-green behaviour check of 13 cases / 22 assertions in throwaway git repos; reviewer-authored harnesses showed 21 adversarial inputs correct and 0 outcome differences across 13 ordinary denylist variants versus the pre-change scanner. Review: two-seat panel over three checkpoints, 0 blocker/should-fix at the final round.
- **Not a defect, do not "fix":** a zero-width character *inside* a term (e.g. `Al` + U+200B + `ice`) is kept as written — `clean()` only trims token edges, deliberately.

## P2 — Deny terms whose first or last character is not a regex word character fail to match

**Problem.** Terms are joined into `r"(?i)\b(?:" + "|".join(re.escape(t) for t in custom) + r")\b"` (`scripts/leak-scan.py`, the `pats["private-term"]` line in `main()`, around line 150). `\b` needs a word/non-word transition at each end. When a term's first or last character is not a word character — `C++`, `.NET`, `@examplehandle`, `Acme!` — that edge only matches if the neighbouring character in the text *is* a word character. So `C++` matches inside `C++11` but not in `we use C++ here`, and `.NET` matches inside `ASP.NET Core` but not in `we use .NET; x`. The term is still counted, so the summary reports `N local terms` for names that mostly are not being caught.

**The same failure hits real names ending in a combining mark.** Python's `\w` does not match combining marks (category Mn/Mc), so a name whose last character is one — most Devanagari words (`नमस्ते` ends in U+0947, `हिंदी` in U+0940), many Indic and Southeast Asian scripts, and Latin names typed in decomposed form (`Zoe` followed by U+0308 COMBINING DIAERESIS, which renders as Zoë) — gets a trailing `\b` that can only match before another word character. These names never match in ordinary text today.

**Evidence (main at `841ed3d`).** Each punctuation term alone against a tracked file containing `we use C++ and .NET; ping @examplehandle; Acme! rocks` → `leak-scan: clean (1 files, 7 built-in patterns, 1 local term)`, exit 0, for all four. Control: the word term `rocks` → exit 1. Denylist `नमस्ते` against `नमस्ते दुनिया`, `हिंदी` against `मैं हिंदी बोलता हूँ`, and decomposed Zoë (`Zoe` + U+0308) against `hello` + that name + `today` → exit 0 for all three.

**Why it matters.** Handles, company names with punctuation, product names and names in non-Latin scripts are exactly the terms people list. A gate that counts a term it cannot match reports coverage it does not have — and for the combining-mark case, the silently unprotected terms are people's names.

**Fix — a design decision, not just a regex tweak.** Two boundary designs were tried in scratch copies on 2026-09-17. Both fix the punctuation cases and the sentence cases; they differ on text where a combining mark follows the term.

- **B — fail-closed (recommended for this gate).** Per term, add `(?<!\w)` in front only if the term's first character is a word character that is not a combining mark, and `(?!\w)` after only if its last character is; a punctuation-edged or mark-edged side gets no boundary. Join the bounded terms with `|` under `(?i)`. This matches a strict **superset** of today's pattern: every `\b` edge it keeps is equivalent to `(?<!\w)`/`(?!\w)` on a word-character edge, and every edge it drops only removes a constraint. So it can over-block (e.g. `नमस्ते` inside `नमस्तेजी`) but never unblocks anything that blocks today (a randomized comparison on 2026-09-17 of 200,000 term/text pairs over letters, digits, `_`, punctuation, combining marks and spaces found 0 cases where today's pattern matched and B did not) — including inflected forms where a suffix vowel sign follows a name, such as the Bengali possessive `রাজেশের` ("Rajesh's") for the term `রাজেশ`, or `Zoe` + U+0308 + `y` (a decomposed Zoëy) for the term `Zoe` + U+0308.
- **A — combining marks count as word characters.** Build a class `[\w` + every code point whose category starts with `M` + `]` once at load and use it in the lookarounds on word- or mark-edged sides. Tighter (no match inside `नमस्तेजी`), but it **stops blocking** matches that block today: `রাজেশ` in `রাজেশের`, `Zoe` + U+0308 inside `Zoe` + U+0308 + `y`, `Jose` inside `Jose` + U+0301 (a decomposed José), and a term beginning with a bare combining mark. On a leak gate that is a regression; choose A only deliberately, and record the trade-off in the CHANGELOG.

Test character classes with `re.match(r"\w", c)` and `unicodedata.category(c).startswith("M")`, not `str.isalnum()` — they differ on `_`, and `isalnum()` would make the term `_priv` newly match inside `my_priv`. Write regex fragments as raw strings (`r"\w"`); a plain `"\w"` string prints a `SyntaxWarning` on every run of the hook.

**Do not** filter unbounded matches afterwards in Python ("match the term anywhere, then reject candidates whose neighbours are word characters"). `re.finditer` returns only the leftmost non-overlapping match of the alternation, so rejecting a candidate loses a longer term that starts at the same place: with denylist `Ann` and `Anna`, the text `met Anna today` would stop being blocked. Lookarounds let the regex engine backtrack to `Anna`, as `\b` does today.

**Do not** apply `(?<!\w)` / `(?!\w)` to every term unconditionally: it stops matches that block today — `.NET` in `ASP.NET Core`, `C++` in `C++11`, `@examplehandle` in `bob@examplehandle`.

**Files.** `scripts/leak-scan.py` (`main()`, pattern construction), `CHANGELOG.md`, both version fields.

**Done when** (a minimum — the probe cannot enumerate every script and form, so also reason about the superset property directly):

- each punctuation-edged term, **tested alone**, blocks the ordinary-text file above, and the three combining-mark names block their sentences;
- names that share a prefix still block (denylist `Ann` + `Anna` blocks `met Anna today`; `Bob` + `Bobby` blocks `hi Bobby`);
- ordinary word terms are unchanged (`Alice` blocks `hello Alice`, not `Alicent`; `_priv` blocks `x _priv y`, not `my_priv`), and a clean tree still exits 0;
- with design B: nothing that blocks today stops blocking — in the probe, `no match inside word` and `Jose / decomposed Jose` stay exit 1. With design A: those two become exit 0, and that change is stated as deliberate in the PR and CHANGELOG.

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

**Fix — decide first.** Trim, at token edges, the characters Unicode itself marks as invisible: the `Default_Ignorable_Code_Point` property from `DerivedCoreProperties.txt`, minus what `clean()` already trims (category Cf). Python's `unicodedata` does not expose that property, so vendor the ranges for a pinned Unicode version in a comment-sourced constant rather than writing a list from memory — a hand list is how the first attempt missed characters. For orientation, the non-Cf members include variation selectors (U+180B–U+180D, U+180F, U+FE00–U+FE0F, U+E0100–U+E01EF), U+034F COMBINING GRAPHEME JOINER, U+17B4–U+17B5 KHMER VOWEL INHERENT AQ/AA, and the Hangul fillers U+115F, U+1160, U+3164, U+FFA0 — check against the pinned file, do not copy this sentence as the list. Record the Unicode version in the CHANGELOG. **Avoid** two tempting alternatives: trimming category Mn wholesale, or warning whenever a term's last character is not a letter, digit or punctuation. Combining marks legitimately end real names — `नमस्ते` ends in U+0947 (Mn), `हिंदी` in U+0940 (Mc), a decomposed Zoë (`Zoe` + U+0308, Mn) — so both would mangle or flag genuine terms. (Those names do not *match* today either, but that is the P2 boundary item above, not this one.)

**Files.** `scripts/leak-scan.py` (`clean()`).

**Done when.** Both evidence cases behave like their plain versions (the comment is not a term and the no-terms warning appears; `Alice` blocks); `clean()` returns `नमस्ते`, `हिंदी` and decomposed Zoë (`Zoe` + U+0308) unchanged (their final combining mark is kept); the 0.5.2 Cf behaviour is unchanged.

## P3 — Hit order is nondeterministic

**Problem.** Hits on one line are collected from a set: `for m in {mm.group(0) for mm in re.finditer(pat, line)}:` in `main()` (around line 168). Set iteration order depends on the string hash seed.

**Evidence (main at `841ed3d`).** The same file and denylist (five terms on one line) run with `PYTHONHASHSEED` 1, 2, 3, 4 reported the five hits in four different orders.

**Why it matters.** Cosmetic, but it makes output diffs noisy and any future golden-output test flaky.

**Fix.** Deduplicate while preserving first-occurrence order, e.g. `dict.fromkeys(mm.group(0) for mm in re.finditer(pat, line))`.

**Files.** `scripts/leak-scan.py` (`main()`).

**Done when.** The order probe prints the same list for all four seeds — each term once, in order of first occurrence in the line (printed as `'Zed' 'Alpha' 'Mike' 'Bravo' 'Kilo'`), even though `Zed` appears twice on that line.

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
zoe = "Zoe\u0308"
for term, sentence in [("नमस्ते", "नमस्ते दुनिया"), ("हिंदी", "मैं हिंदी बोलता हूँ"), (zoe, f"hello {zoe} today")]:
    print(f"P2 combining-mark name {term!r:12}:", run((term + "\n").encode(), {"t.md": sentence.encode()}))
print("P2 no match inside word  :", run("नमस्ते\n".encode(), {"t.md": "नमस्तेजी\n".encode()}))
print("P2 prefix Ann+Anna / Anna :", run(b"Ann\nAnna\n", {"t.md": b"met Anna today\n"}))
print("P2 prefix Bob+Bobby/Bobby :", run(b"Bob\nBobby\n", {"t.md": b"hi Bobby\n"}))
print("P2 Jose / decomposed Jose :", run(b"Jose\n", {"t.md": ("hi Jose" + "\u0301" + "\n").encode()}))
print("P3 denylist is a dir  :", run(None, {"a.md": b"x\n"}, as_dir=True))
print("P3 unreadable         :", run(b"Name\n", {"a.md": b"x\n"}, mode=0))
print("P3 UTF-16 denylist    :", run("Name\n".encode("utf-16"), {"a.md": b"x\n"}))
print("P3 invalid UTF-8      :", run(b"Caf\xe9\n", {"a.md": b"x\n"}))
print("P3 VS16 + comment     :", run("\ufe0f# only a comment\n".encode(), {"a.md": b"x\n"}))
print("P3 CGJ + name         :", run("\u034fAlice\n".encode(), {"n.md": b"hello Alice\n"}))
for seed in "1234":
    print(f"P3 order seed {seed}      :", run(b"Zed\nAlpha\nMike\nBravo\nKilo\n",
          {"n.md": b"Zed Alpha Mike Bravo Kilo Zed\n"}, env={"PYTHONHASHSEED": seed}))
PY
```

Expected on `841ed3d`: the four `P2 alone` lines each exit 0 with `1 local term`, and the control exits 1; the three `must stay blocked` lines exit 1; `Alice` exits 1 then 0, `_priv` exits 1 then 0; the three combining-mark names exit 0 (the defect) and `no match inside word` exits **1** (today's `\b` lets `नमस्ते` match inside `नमस्तेजी`, because the next character is a word character; stays 1 with design B, becomes 0 with design A); both `prefix` lines exit 1 (they must stay 1 after a fix); `Jose / decomposed Jose` exits 1 (stays 1 with design B, becomes 0 with design A); the four unreadable cases exit 1 with a Python exception as the last stderr line; both non-Cf cases exit 0; the four order lines differ, and each lists every term once. After a fix, compare against that item's **Done when**, not against "the output changed". The probe is a minimum, not a proof: a partial fix (for example, only the trailing boundary) turns some `P2 alone` lines to exit 1 but not all, and some wrong designs pass every line — read each Fix paragraph's constraints as part of the acceptance bar.

Per `CONTRIBUTING.md`, any change to this gate must be seen to refuse something before it ships, and per `CLAUDE.md` a fix reaches installed copies only with a version bump in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. Open a PR; `main` is not pushed directly.
