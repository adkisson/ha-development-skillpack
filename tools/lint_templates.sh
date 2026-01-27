#!/usr/bin/env bash
# lint_templates.sh — flag non-compliant HA Jinja patterns in YAML/Jinja files.
set -euo pipefail

ROOT="${1:-.}"
shopt -s globstar nullglob

patterns=(
  "\.get\("
  "\.items\("
  "\.append\("
  "\.split\("
  "\.replace\("
  "\.format\("
  "\.total_seconds\("
  "states\.[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+"
  "\.lower\("
  "\.upper\("
  "\.strip\("
  "state_not:"
  "\bfloat\("
  "\bint\("
)

violations=0

for file in "$ROOT"/**/*.{yaml,yml,jinja,txt}; do
  [[ -f "$file" ]] || continue
  for p in "${patterns[@]}"; do
    if grep -nE --color=never "$p" "$file" >/dev/null; then
      echo "VIOLATION: $file matches /$p/"
      grep -nE --color=never "$p" "$file" | sed 's/^/  line /'
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
