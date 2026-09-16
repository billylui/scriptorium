#!/usr/bin/env python3
"""Refuse to publish personal material.

This repository is developed inside its author's own live vault, so every commit
is an opportunity for a private name, folder or measurement to escape into public
rule text. That risk is structural and does not diminish with care, so it is
checked by a script on every commit rather than by remembering the policy at the
moment of editing.

Two layers:
  1. Built-in patterns — absolute home paths, emails, tokens, private keys.
     These are universal and always on.
  2. Your own terms — names, folders, projects that must never appear. Put them
     in `.leakterms.local`, one per line. That file is gitignored: publishing a
     list of the words you are hiding would defeat the exercise.

Exit 1 on any hit, so it works as a pre-commit hook.
"""
import re, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

BUILTIN = {
    "home-path":   r"/(?:Users|home)/(?!runner\b)[a-z0-9_.-]+",
    "email":       r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
    "private-key": r"BEGIN [A-Z ]*PRIVATE KEY",
    "token":       r"(?i)(?:bot[_-]?token|api[_-]?key|secret)\s*[=:]\s*['\"]?[A-Za-z0-9_\-]{16,}",
    "tg-token":    r"\b[0-9]{8,10}:[A-Za-z0-9_-]{30,}\b",
}
SKIP_SUFFIX = {".png", ".jpg", ".jpeg", ".gif", ".pdf", ".zip", ".lock"}
SELF = Path(__file__).name


def terms():
    f = ROOT / ".leakterms.local"
    if not f.exists():
        return []
    out = []
    for line in f.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            out.append(line)
    return out


def files():
    try:
        r = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True)
        listed = [ROOT / p for p in r.stdout.split("\n") if p]
    except Exception:
        listed = [p for p in ROOT.rglob("*") if ".git" not in p.parts]
    return [p for p in listed if p.is_file() and p.suffix not in SKIP_SUFFIX and p.name != SELF]


def main():
    custom = terms()
    pats = dict(BUILTIN)
    if custom:
        pats["private-term"] = r"(?i)\b(?:" + "|".join(re.escape(t) for t in custom) + r")\b"

    hits = []
    for f in files():
        try:
            text = f.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue
        for n, line in enumerate(text.split("\n"), 1):
            for label, pat in pats.items():
                for m in {mm.group(0) for mm in re.finditer(pat, line)}:
                    hits.append((f.relative_to(ROOT), n, label, m[:48]))

    if not hits:
        n = len(custom)
        print(f"leak-scan: clean ({len(files())} files, {len(BUILTIN)} built-in patterns"
              + (f", {n} local term{'s' if n != 1 else ''})" if n else ", no .leakterms.local)"))
        return 0

    print("leak-scan: BLOCKED — personal material found\n", file=sys.stderr)
    for path, n, label, tok in hits:
        print(f"  {path}:{n}  [{label}]  {tok!r}", file=sys.stderr)
    print(f"\n{len(hits)} hit(s). Fix them, or add a deliberate exception to .leakterms.local.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
