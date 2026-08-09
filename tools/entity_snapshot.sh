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

# Associative-array lookup that tolerates an empty key (e.g. an entity with
# no device_id) — bash raises "bad array subscript" on `${ARR[$empty]}`
# directly, which is fatal under `set -e`.
lookup() {
  local -n _map="$1"
  local key="$2"
  [[ -n "$key" ]] || return 0
  printf '%s' "${_map[$key]:-}"
}

entities=$(jq -c '.data.entities[] | {entity_id, name, device_id, area_id}' "$STORE/core.entity_registry")
devices=$(jq -c '.data.devices[] | {id, name_by_user, name, area_id}' "$STORE/core.device_registry")
areas=$(jq -c '.data.areas[] | {area_id, name}' "$STORE/core.area_registry")

declare -A DEV_NAME
declare -A DEV_AREA
while IFS= read -r d; do
  id=$(jq -r '.id' <<<"$d")
  n1=$(jq -r '.name_by_user // empty' <<<"$d")
  n2=$(jq -r '.name // empty' <<<"$d")
  DEV_NAME["$id"]="${n1:-$n2}"
  DEV_AREA["$id"]=$(jq -r '.area_id // empty' <<<"$d")
done <<< "$devices"

declare -A AREA_NAME
while IFS= read -r a; do
  aid=$(jq -r '.area_id' <<<"$a")
  AREA_NAME["$aid"]=$(jq -r '.name // empty' <<<"$a")
done <<< "$areas"

echo '{'
first=1
while IFS= read -r e; do
  eid=$(jq -r '.entity_id' <<<"$e")
  ename=$(jq -r '.name // empty' <<<"$e")
  did=$(jq -r '.device_id // empty' <<<"$e")
  dname="$(lookup DEV_NAME "$did")"
  # Entity-level area_id overrides the device's area when set; otherwise
  # the entity inherits its device's area.
  eaid=$(jq -r '.area_id // empty' <<<"$e")
  aid="$eaid"
  [[ -n "$aid" ]] || aid="$(lookup DEV_AREA "$did")"
  aname="$(lookup AREA_NAME "$aid")"
  [[ $first -eq 0 ]] && echo ',' || first=0
  printf '  "%s": {"name": %s, "device_name": %s, "area_name": %s}
' "$eid" "$(jq -Rn --arg x "$ename" '$x')" "$(jq -Rn --arg x "$dname" '$x')" "$(jq -Rn --arg x "$aname" '$x')"
done <<< "$entities"
echo '}'
