#!/usr/bin/env python3
"""Refuse to publish personal material.

This repository is developed inside its author's own live vault, so every commit
is an opportunity for a private name, folder or measurement to escape into public
rule text. That risk is structural and does not diminish with care, so it is
checked by a script on every commit rather than by remembering the policy at the
moment of editing.

Two layers:
  1. Built-in patterns — home paths, emails, tokens, keys, private decision-
     register citations, literal numbered folders. Universal, always on, and the
     only layer that catches a leak carrying no name at all.
  2. Your own terms — names, folders, projects that must never appear. Put them
     in `.leakterms.local`, one per line. That file is gitignored: publishing a
     list of the words you are hiding would defeat the exercise.

NECESSARY, NOT SUFFICIENT. Layer 2 only finds what you remembered to list, and
the terms you forget are exactly the ones you do not think of as sensitive. In
this repository's own first pass, a hand-written denylist passed seven files that
a careful read then found leaks in — a register citation and a private folder
name, neither on the list. Treat a clean run as "no known pattern matched",
never as "reviewed". Read the diff.

Exit 1 on any hit, so it works as a pre-commit hook.
"""
import re, subprocess, sys
from fnmatch import fnmatch
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

BUILTIN = {
    "home-path":     r"/(?:Users|home)/(?!runner\b)[a-z0-9_.-]+",
    "email":         r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
    "private-key":   r"BEGIN [A-Z ]*PRIVATE KEY",
    "token":         r"(?i)(?:bot[_-]?token|api[_-]?key|secret)\s*[=:]\s*['\"]?[A-Za-z0-9_\-]{16,}",
    "tg-token":      r"\b[0-9]{8,10}:[A-Za-z0-9_-]{30,}\b",
    # Structural leaks: these carry no name, so a denylist never catches them.
    # A citation like "(Decision 14d)" points into a private decision register,
    # and a literal numbered folder is one vault's structure where published rule
    # text should carry a config placeholder instead.
    "decision-cite": r"\((?:Decision|D)\s?\d{1,2}[a-z]?\)|\bDecision \d{1,2}[a-z]?\b",
    "numbered-dir":  r"\b\d{2}-[A-Z][a-z]+/",
}
SKIP_SUFFIX = {".png", ".jpg", ".jpeg", ".gif", ".pdf", ".zip", ".lock"}
SELF = Path(__file__).name


DENYLIST = ".leakterms.local"


def terms():
    """Read the denylist. Lines starting with '!' are path exemptions.

    An exemption exists for the narrow case where a real name is *required* to
    be published — a copyright line being the canonical example. Keep the list
    short: each entry is a file nobody is checking any more.
    """
    f = ROOT / DENYLIST
    if not f.exists():
        return [], []
    deny, allow = [], []
    for line in f.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("!"):
            # "!path" exempts a file entirely; "!path:label" exempts one pattern
            # in that file. Prefer the second — a blanket exemption also switches
            # off the name checks, which are the ones that catch real leaks.
            body = line.lstrip("!").strip()
            allow.append(tuple(body.split(":", 1)) if ":" in body else (body, None))
        else:
            deny.append(line)
    return deny, allow


def files():
    try:
        r = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True)
        listed = [ROOT / p for p in r.stdout.split("\n") if p]
    except Exception:
        listed = [p for p in ROOT.rglob("*") if ".git" not in p.parts]
    # Never scan the denylist itself: it is a list of the very terms being
    # hunted, and it should be gitignored anyway — but if someone commits it by
    # mistake, a wall of self-matches is a useless way to find that out.
    skip = {SELF, DENYLIST}
    return [p for p in listed if p.is_file() and p.suffix not in SKIP_SUFFIX and p.name not in skip]


def denylist_state(custom):
    """Summary fragment and optional warning for the denylist.

    A missing file and a file holding only comments and exemptions both mean no
    name is being checked, and the built-in patterns never catch a name. Saying
    "no .leakterms.local" about a file that exists hides exactly that, so the two
    states are reported separately and both warn.
    """
    if not (ROOT / DENYLIST).exists():
        return (f"no {DENYLIST}",
                f"leak-scan: warning — no {DENYLIST}, so no names are checked. "
                f"Built-in patterns do not catch names. Copy .leakterms.example to {DENYLIST} and list them.")
    if not custom:
        return (f"{DENYLIST} has no deny terms",
                f"leak-scan: warning — {DENYLIST} exists but lists no deny terms (only comments or '!' exemptions), "
                f"so no names are checked. Built-in patterns do not catch names.")
    n = len(custom)
    return f"{n} local term{'s' if n != 1 else ''}", None


def main():
    custom, exempt = terms()
    summary, warning = denylist_state(custom)
    if warning:
        # stderr, never a failure: an empty denylist is a gap to see, not a leak to block.
        print(warning, file=sys.stderr)
    pats = dict(BUILTIN)
    if custom:
        pats["private-term"] = r"(?i)\b(?:" + "|".join(re.escape(t) for t in custom) + r")\b"

    def exempted(rel, label):
        return any(fnmatch(rel, g) and (lab is None or lab == label)
                   for g, lab in exempt)

    hits = []
    scanned = [f for f in files()
               if not exempted(str(f.relative_to(ROOT)), None)]
    for f in scanned:
        try:
            text = f.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue
        for n, line in enumerate(text.split("\n"), 1):
            for label, pat in pats.items():
                if exempted(str(f.relative_to(ROOT)), label):
                    continue
                for m in {mm.group(0) for mm in re.finditer(pat, line)}:
                    hits.append((f.relative_to(ROOT), n, label, m[:48]))

    if not hits:
        ex = f", {len(exempt)} exempt" if exempt else ""
        print(f"leak-scan: clean ({len(scanned)} files{ex}, {len(BUILTIN)} built-in patterns, {summary})")
        return 0

    print("leak-scan: BLOCKED — personal material found\n", file=sys.stderr)
    for path, n, label, tok in hits:
        print(f"  {path}:{n}  [{label}]  {tok!r}", file=sys.stderr)
    print(f"\n{len(hits)} hit(s). Fix them, or exempt a path with a '!glob' line in .leakterms.local.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
