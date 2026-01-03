#!/usr/bin/env bash
# entity_snapshot.sh — snapshot entities by grepping HA .storage registry files.
# Usage:
#   export HA_CONFIG="/config"   # path to HA config directory (where .storage lives)
#   ./entity_snapshot.sh > entity_snapshot.json
#
# Produces a JSON object mapping entities to basic metadata (device/area if present).
# Requires: jq

set -euo pipefail

CONF="${HA_CONFIG:-/config}"
STORE="$CONF/.storage"

files=(
  "$STORE/core.entity_registry"
  "$STORE/core.device_registry"
  "$STORE/core.area_registry"
)

for f in "${files[@]}"; do
  [[ -f "$f" ]] || { echo "Missing $f" >&2; exit 1; }
done

entities=$(jq -c '.data.entities[] | {entity_id, name, device_id}' "$STORE/core.entity_registry")
devices=$(jq -c '.data.devices[] | {id, name_by_user, name}' "$STORE/core.device_registry")

declare -A DEV_NAME
while IFS= read -r d; do
  id=$(jq -r '.id' <<<"$d")
  n1=$(jq -r '.name_by_user // empty' <<<"$d")
  n2=$(jq -r '.name // empty' <<<"$d")
  DEV_NAME["$id"]="${n1:-$n2}"
done <<< "$devices"

echo '{'
first=1
while IFS= read -r e; do
  eid=$(jq -r '.entity_id' <<<"$e")
  ename=$(jq -r '.name // empty' <<<"$e")
  did=$(jq -r '.device_id // empty' <<<"$e")
  dname="${DEV_NAME[$did]:-}"
  [[ $first -eq 0 ]] && echo ',' || first=0
  printf '  "%s": {"name": %s, "device_name": %s}
' "$eid" "$(jq -Rn --arg x "$ename" '$x')" "$(jq -Rn --arg x "$dname" '$x')"
done <<< "$entities"
echo '}'
