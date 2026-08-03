#!/usr/bin/env bash
set -uo pipefail

SCOPES="basic advanced"

DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="${SCOPES_CONFIG:-$DIR/test-scopes.yaml}"

test -f "$CONFIG"        || { echo "error: config not found: $CONFIG" >&2; exit 1; }
command -v yq >/dev/null || { echo "error: yq (v4) is required" >&2; exit 1; }
command -v jq >/dev/null || { echo "error: jq is required" >&2; exit 1; }

ALL="${ALL:-0}"
if [ "$ALL" != "1" ] && [ -z "${CHANGED:-}" ]; then
  BASE="${1:-origin/main}"
  CHANGED="$(git diff --name-only @{upstream})"
fi
CHANGED="${CHANGED:-}"

matches() {
  local pattern="$1"
  local scope="$2"
  test -n "$pattern" || return 1
  printf '%s\n' "$CHANGED" | grep -qE "$pattern"
  if [ $? -eq 0 ]; then
    printf "%s matches provisioning test scope '%s'\n" $(printf '%s\n' "$CHANGED" | grep -E "$pattern") $scope >&2
  else
    printf "%s does not match provisioning test scope '%s'\n" $(printf '%s\n' "$CHANGED" | grep -E "$pattern") $scope >&2
    return 1
  fi
}

selected=""
if [ "$ALL" = "1" ] || matches "$(yq '.full | join("|")' "$CONFIG")" "full"; then
  printf "Triggering all scopes" >&2
  selected="$SCOPES"                                 # run every scope
else
  for scope in $SCOPES; do
    if matches "$(yq ".scopes.$scope.paths | join(\"|\")" "$CONFIG")" $scope; then
      selected="$selected $scope"                    # add this scope to the list
    fi
  done
fi
#echo "resolve: selected scopes: [$(echo "$selected" | xargs)]" >&2

yq -o=json '.' "$CONFIG" | jq -c --arg selected "$selected" '
  {
    include: [
      ($selected | split(" ") | map(select(length > 0))[]) as $scope
      | (.scopes[$scope].tests // [])[]
      | { TEST_RUN_REGEX: .regex }
    ]
  }
'
