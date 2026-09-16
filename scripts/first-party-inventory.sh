#!/usr/bin/env bash
# first-party-inventory.sh — measure how much of a vault its owner actually wrote.
#
# Provenance (AUTHORSHIP.md Law 2) depends on a number most people guess wrong:
# the share of a vault that is genuinely first-party. This counts it instead.
#
# Reads `protected_surfaces` from .scriptorium.json — the same list that Law 1
# protects from overwriting, because the surfaces worth protecting are exactly
# the surfaces admissible as evidence.
#
# Usage:  scripts/first-party-inventory.sh [/path/to/vault]
# With no argument, walks up from $PWD to find .scriptorium.json.

set -uo pipefail

vault="${1:-}"
if [ -z "$vault" ]; then
  d="$PWD"
  while [ "$d" != "/" ]; do
    [ -f "$d/.scriptorium.json" ] && { vault="$d"; break; }
    d="$(dirname "$d")"
  done
fi
[ -n "$vault" ] && [ -d "$vault" ] || { echo "No vault found. Pass a path, or add .scriptorium.json to your vault root." >&2; exit 1; }

cfg="$vault/.scriptorium.json"
[ -f "$cfg" ] || { echo "No .scriptorium.json at $vault" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq required." >&2; exit 1; }

total=$(find "$vault" -name '*.md' -not -path '*/.*' | wc -l | tr -d ' ')

echo "Vault: $vault"
echo "Total markdown files: $total"
echo
echo "First-party surfaces (from .scriptorium.json → protected_surfaces):"

surfaces=$(jq -r '.protected_surfaces // [] | .[]' "$cfg" 2>/dev/null)
if [ -z "$surfaces" ]; then
  echo "  (none configured — populate protected_surfaces to measure anything)"
  exit 0
fi

fp_total=0
while IFS= read -r pat; do
  [ -n "$pat" ] || continue
  # A surface is either a glob of files, or "glob::heading" for a section
  # within files that is only first-party when non-empty.
  path="${pat%%::*}"
  head="${pat#*::}"
  [ "$head" = "$pat" ] && head=""

  files=$(find "$vault" -path "$vault/$path" -name '*.md' -not -path '*/.*' 2>/dev/null | wc -l | tr -d ' ')
  if [ -z "$head" ]; then
    n=$files
    printf "  %-44s %4s file(s)\n" "$path" "$n"
  else
    n=0
    while IFS= read -r f; do
      # Count the section as populated only if it has a non-blank line before
      # the next heading — an empty prompt is not first-party content.
      awk -v h="$head" '
        $0 ~ "^#+ *" h { inside=1; next }
        inside && /^#+ / { exit }
        inside && NF { found=1; exit }
        END { exit !found }
      ' "$f" 2>/dev/null && n=$((n+1))
    done < <(find "$vault" -path "$vault/$path" -name '*.md' -not -path '*/.*' 2>/dev/null)
    printf "  %-44s %4s of %s populated\n" "$path :: $head" "$n" "$files"
  fi
  fp_total=$((fp_total + n))
done <<< "$surfaces"

echo
if [ "$total" -gt 0 ]; then
  pct=$(awk -v a="$fp_total" -v b="$total" 'BEGIN{printf "%.1f", 100*a/b}')
  echo "First-party: $fp_total of $total files (${pct}%)"
else
  echo "First-party: $fp_total"
fi
echo
echo "Reminder: your own messages to the agent are usually a larger and more"
echo "current first-party corpus than anything counted above — and in most"
echo "setups they live outside the vault and expire on a rolling window."
