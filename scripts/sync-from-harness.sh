#!/usr/bin/env bash
# Pull the latest cursor rules + prompts from cursor-harness into this
# project's .cursor/ directory.
#
# Locates the harness via (in order):
#   1. $CURSOR_HARNESS env var
#   2. ~/Documents/Workspace/Templates/cursor-harness
#   3. ~/Workspace/Templates/cursor-harness
#   4. ../cursor-harness (sibling on disk)
#
# If none exist, prints clone instructions and exits non-zero.
#
# By default the harness is `git pull`'d before syncing so the project
# gets the actual latest. Pass --no-pull to skip (useful when testing
# local harness edits).

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
PULL=1
for arg in "$@"; do
  case "$arg" in
    --no-pull) PULL=0 ;;
    -h|--help)
      sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; exit 64 ;;
  esac
done

CANDIDATES=(
  "${CURSOR_HARNESS:-}"
  "$HOME/Documents/Workspace/Templates/cursor-harness"
  "$HOME/Workspace/Templates/cursor-harness"
  "$PROJECT_ROOT/../cursor-harness"
)

HARNESS=""
for c in "${CANDIDATES[@]}"; do
  [[ -z "$c" ]] && continue
  if [[ -x "$c/scripts/sync-to-template.sh" ]]; then
    HARNESS="$(cd "$c" && pwd)"
    break
  fi
done

if [[ -z "$HARNESS" ]]; then
  cat >&2 <<EOF
Could not locate cursor-harness. Tried:
  \$CURSOR_HARNESS env var (unset or invalid)
  $HOME/Documents/Workspace/Templates/cursor-harness
  $HOME/Workspace/Templates/cursor-harness
  $PROJECT_ROOT/../cursor-harness

Clone it once:
  gh repo clone knrch/cursor-harness $HOME/Documents/Workspace/Templates/cursor-harness

Or set CURSOR_HARNESS:
  export CURSOR_HARNESS=/path/to/cursor-harness
EOF
  exit 1
fi

echo "Using harness: $HARNESS"

if [[ "$PULL" -eq 1 ]] && [[ -d "$HARNESS/.git" ]]; then
  echo "Pulling harness latest..."
  if ! ( cd "$HARNESS" && git pull --ff-only ); then
    echo "Warning: git pull failed — syncing from current local state." >&2
  fi
fi

"$HARNESS/scripts/sync-to-template.sh" "$PROJECT_ROOT"
