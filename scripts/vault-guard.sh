#!/usr/bin/env bash
# vault-guard.sh — PreToolUse hook (matcher: Write|Edit) for a markdown vault.
#
# Enforces four write-integrity invariants that are otherwise only "rules the
# agent must remember". Each blocks a documented way an LLM silently corrupts an
# Obsidian vault:
#   A. stray root-level .md          — broken-link debris at the vault root
#   B. multi-wikilink YAML string    — spawns a ghost node at the vault root
#   C. missing folder landing note   — [[Folder]] links resolve to an empty stub
#   D. hard-wrapped prose            — renders as mid-sentence <br> in Obsidian
#
# Contract: reads PreToolUse JSON on stdin; to block, prints a deny decision to
# stdout and exits 0. Non-vault / non-markdown writes pass straight through.
# Fails OPEN — a bug here must never block legitimate work.
#
# Configuration: the vault root is the nearest ancestor directory containing a
# `.scriptorium.json`. That file is yours and is never published; see
# `.scriptorium.example.json`. With no config present this hook does nothing,
# which is the correct behaviour outside a vault.

command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
fp="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[ -n "$fp" ] || exit 0
[ "${fp##*.}" = "md" ] || exit 0

# --- locate the vault: nearest ancestor holding .scriptorium.json ---
CONFIG=""; VAULT=""
dir="$(dirname "$fp")"
while [ "$dir" != "/" ] && [ -n "$dir" ]; do
  if [ -f "$dir/.scriptorium.json" ]; then CONFIG="$dir/.scriptorium.json"; VAULT="$dir"; break; fi
  dir="$(dirname "$dir")"
done
[ -n "$CONFIG" ] || exit 0   # not inside a configured vault — nothing to guard

cfg() { jq -r "$1" "$CONFIG" 2>/dev/null; }
enabled() { [ "$(cfg ".checks.$1 // true")" != "false" ]; }

content="$(printf '%s' "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null)"
rel="${fp#"$VAULT"/}"

deny() {
  printf '%s' "$1" | jq -Rs '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:.}}'
  exit 0
}

# ---------- Check A: stray root-level .md ----------
if enabled stray_root_markdown; then
  case "$rel" in
    */*) : ;;
    *)
      base="$(basename "$rel")"
      allowed="$(cfg '.root_allowlist // ["README.md","index.md"] | .[]')"
      if ! printf '%s\n' "$allowed" | grep -qxF "$base"; then
        deny "Vault law — no root-level .md except: $(printf '%s' "$allowed" | tr '\n' ' '). Writing '$base' at the vault root creates broken-link debris. File it under the correct folder."
      fi
      ;;
  esac
fi

# ---------- Check B: multi-wikilink YAML frontmatter string ----------
# Correct forms have at most ONE [[...]] per frontmatter line. Two or more on a
# single line is the comma-joined-string antipattern: Obsidian parses the whole
# string as ONE link target and spawns a ghost node at the vault root.
if enabled yaml_multi_wikilink; then
  case "$content" in ---*)
    fmbad="$(printf '%s\n' "$content" | awk '
      NR==1 && /^---[[:space:]]*$/ {infm=1; next}
      infm && /^---[[:space:]]*$/ {exit}
      infm { c = gsub(/\[\[/, "[["); if (c >= 2) print "    " $0 }
    ')"
    if [ -n "$fmbad" ]; then
      deny "Vault law — multi-wikilink YAML string in frontmatter. Obsidian parses a comma-joined string of wikilinks as ONE giant link target, spawning a ghost node at the vault root. Offending line(s):
$fmbad
Use YAML list form:
  related:
    - \"[[Note-A]]\"
    - \"[[Note-B]]\""
    fi
  ;; esac

  # Edits arrive as fragments with no frontmatter delimiters, so match known
  # link-bearing keys instead. Fenced code is skipped so documentation may show
  # the antipattern without being blocked.
  keys="$(cfg '.wikilink_keys // ["related","companions","area","project","supersedes","superseded-by"] | join("|")')"
  keybad="$(printf '%s\n' "$content" | awk -v keys="$keys" '
    /^[[:space:]]*```/ { infence = !infence; next }
    infence { next }
    $0 ~ "^[[:space:]]*(" keys "):" {
      c = gsub(/\[\[/, "[["); if (c >= 2) print "    " $0
    }
  ')"
  if [ -n "$keybad" ]; then
    deny "Vault law — multi-wikilink YAML string on a frontmatter key. This spawns a root-level ghost node. Offending line(s):
$keybad
Split into a YAML list (one \"[[Link]]\" per line)."
  fi
fi

# ---------- Check C: folder landing note ----------
# A wikilink [[Folder]] resolves only to Folder.md — never to Folder/index.md.
# Without the landing note, clicking the link silently creates an empty stub.
if enabled folder_landing; then
  for parent in $(cfg '.landing_note_parents // [] | .[]'); do
    case "$rel" in
      "$parent"/*/*)
        rest="${rel#"$parent"/}"
        folder="${rest%%/*}"
        landing="$VAULT/$parent/$folder/$folder.md"
        if [ "$fp" != "$landing" ] && [ ! -f "$landing" ]; then
          deny "Vault law — folder landing note missing. '$parent/$folder/' has no '$folder.md', so a [[$folder]] link would create a ghost stub. Create $parent/$folder/$folder.md FIRST, then retry this write."
        fi
        ;;
    esac
  done
fi

# ---------- Check D: hard-wrapped prose ----------
# Obsidian's `Strict line breaks` defaults OFF, so a single newline renders as a
# visible <br> in BOTH Reading view and Live Preview. An 80-column wrap that is
# invisible on GitHub appears here as a mid-sentence line break.
#
# A hard wrap = a line >=55 chars where the line PLUS the next line's first word
# would have crossed column 76 — i.e. the break is explained by a wrap boundary
# rather than by intent. A flat "line is long" proxy misses lines that ended
# short only because the next token was long, such as a [[wikilink]].
#
# python3, not awk: macOS awk counts BYTES and aborts with a multibyte
# conversion failure on CJK and symbols, which both inflates line lengths and
# silently skips the check. Fails OPEN if python3 is absent.
if enabled hard_wrapped_prose && command -v python3 >/dev/null 2>&1; then
  wrapbad="$(printf '%s' "$content" | python3 -c '
import re, sys

BLOCK = re.compile(r"^\s*(?:[-*+]\s|\d+[.)]\s|#{1,6}\s|>|\||```|~~~|<!--|<[a-zA-Z/]|<-|---\s*$|\[\^)")
LABEL = re.compile(r"^\s*(?:\*\*|__|[A-Za-z][A-Za-z0-9 /&_-]{0,20}:\s)")
FLOOR, COL = 55, 76

def wrapped(cur, ns):
    c = cur.rstrip()
    if len(c) < FLOOR:
        return False
    word = ns.split(" ", 1)[0] if ns else ""
    return len(c) + 1 + len(word) > COL

lines = sys.stdin.read().split("\n")
fence = False
fm = bool(lines) and lines[0].strip() == "---"
hits = []
for i, line in enumerate(lines):
    s = line.strip()
    if fm:
        if i and s == "---":
            fm = False
        continue
    if s.startswith("```") or s.startswith("~~~"):
        fence = not fence
        continue
    if fence or i + 1 >= len(lines):
        continue
    nxt = lines[i + 1]
    ns = nxt.strip()
    if not ns or BLOCK.match(nxt) or LABEL.match(ns):
        continue
    if ("|" in line and "|" in nxt) or line.endswith("  "):
        continue
    if not wrapped(line, ns):
        continue
    hits.append("    ..." + line.rstrip()[-46:] + "  [BREAK]  " + ns[:40] + "...")
for h in hits[:4]:
    print(h)
if len(hits) > 4:
    print("    (+%d more)" % (len(hits) - 4))
' 2>/dev/null)"
  if [ -n "$wrapbad" ]; then
    deny "Vault law — hard-wrapped prose detected. Obsidian runs with \`Strict line breaks\` OFF, so every single newline renders as a visible <br>: these breaks appear mid-sentence in both Reading view and Live Preview. Offending wrap point(s):
$wrapbad
Write ONE paragraph per line and let the editor soft-wrap. Deliberate single-newline stacks (\`**Label:** value\`) are fine and are not flagged."
  fi
fi

exit 0
