#!/usr/bin/env bash
# lint_templates.sh — flag non-compliant HA Jinja patterns in YAML/Jinja files.
set -euo pipefail

ROOT="${1:-.}"
shopt -s globstar nullglob

# NOTE: `| float(...)` / `| int(...)` are Jinja filters, not Python method
# calls, and the pack explicitly requires them as safe defaults — they are
# intentionally NOT in this list. Do not add \bfloat\(/\bint\( back; that
# flags the pack's own recommended pattern, not a violation of it.
patterns=(
  "\.get\("
  "\.items\("
  "\.append\("
  "\.split\("
  "\.replace\("
  "\.format\("
  "\.total_seconds\("
  "states\.[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+"
  "\.lower\("
  "\.upper\("
  "\.strip\("
  "state_not:"
)

violations=0

for file in "$ROOT"/**/*.{yaml,yml,jinja,txt}; do
  [[ -f "$file" ]] || continue
  for p in "${patterns[@]}"; do
    # Match against the original file (correct line numbers), then drop
    # matches on full-line comments (YAML `#...`) so illustrative text in
    # comments (e.g. "no .items()") doesn't trip the lint. Known
    # limitation: doesn't drop inline trailing comments or Jinja {# ... #}
    # spans embedded mid-line.
    matches="$(grep -nE --color=never "$p" "$file" | grep -vE '^[0-9]+:[[:space:]]*#' || true)"
    if [[ -n "$matches" ]]; then
      echo "VIOLATION: $file matches /$p/"
      sed 's/^/  line /' <<<"$matches"
      violations=$((violations+1))
    fi
  done
done

if [[ $violations -gt 0 ]]; then
  echo "Found $violations violation(s)"
  exit 2
else
  echo "No HA Jinja violations detected."
fi
