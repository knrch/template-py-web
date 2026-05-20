#!/usr/bin/env bash
# Audited frontend dependency operations.
#
# Wraps `pnpm` so that any change to frontend/pnpm-lock.yaml is followed by
# `pnpm audit` + `osv-scanner` against the new lockfile. If ANY new advisory
# (any severity, including low/info) is introduced that was not present
# before, the lockfile is restored and the change is rejected.
#
# Usage:
#   scripts/safe-pnpm.sh install
#   scripts/safe-pnpm.sh add <pkg>[@version]...
#   scripts/safe-pnpm.sh add -D <pkg>...
#   scripts/safe-pnpm.sh update [<pkg>...]
#   scripts/safe-pnpm.sh remove <pkg>...

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

FRONTEND_DIR="$REPO_ROOT/frontend"
LOCKFILE="$FRONTEND_DIR/pnpm-lock.yaml"

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") <pnpm-subcommand> [args...]" >&2
  echo "Common: install | add <pkg> | update | remove <pkg>" >&2
  exit 64
fi

require_tool pnpm pnpm "https://pnpm.io/installation"
require_tool osv-scanner osv-scanner "https://google.github.io/osv-scanner/installation/"

if [[ ! -f "$LOCKFILE" ]]; then
  log_error "Lockfile not found: $LOCKFILE"
  exit 2
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

LOCK_BACKUP="$WORK_DIR/pnpm-lock.yaml.before"
PRE_AUDIT="$WORK_DIR/pre.json"
POST_AUDIT="$WORK_DIR/post.json"
PRE_OSV="$WORK_DIR/pre.osv.json"
POST_OSV="$WORK_DIR/post.osv.json"

log_info "Snapshotting pnpm-lock.yaml"
cp "$LOCKFILE" "$LOCK_BACKUP"

log_info "Auditing current lockfile (before)"
( cd "$FRONTEND_DIR" && pnpm audit --json >"$PRE_AUDIT" 2>/dev/null ) || true
osv-scanner --lockfile "$LOCKFILE" --format json >"$PRE_OSV" 2>/dev/null || true

log_info "Running: pnpm $*"
( cd "$FRONTEND_DIR" && pnpm "$@" )

log_info "Auditing new lockfile (after)"
( cd "$FRONTEND_DIR" && pnpm audit --json >"$POST_AUDIT" 2>/dev/null ) || true
osv-scanner --lockfile "$LOCKFILE" --format json >"$POST_OSV" 2>/dev/null || true

extract_pnpm_all() {
  local file="$1"
  if [[ ! -s "$file" ]]; then echo ""; return 0; fi
  python3 - "$file" <<'PY'
import json, sys
try:
  d = json.load(open(sys.argv[1]))
except Exception:
  sys.exit(0)
adv = d.get("advisories") or {}
for k, v in adv.items():
  sev = (v.get("severity") or "unknown").lower()
  print(f"pnpm:{k}:{sev}")
PY
}

extract_osv_all() {
  local file="$1"
  if [[ ! -s "$file" ]]; then echo ""; return 0; fi
  python3 - "$file" <<'PY'
import json, sys
try:
  d = json.load(open(sys.argv[1]))
except Exception:
  sys.exit(0)
for result in d.get("results", []):
  for pkg in result.get("packages", []):
    for v in pkg.get("vulnerabilities", []):
      ds = v.get("database_specific") or {}
      sev = (ds.get("severity") or "").lower()
      if not sev:
        for s in v.get("severity", []) or []:
          if isinstance(s, dict) and s.get("type") == "CVSS_V3":
            sev = (s.get("score") or "").lower()
      print(f"osv:{v.get('id','?')}:{sev or 'unknown'}")
PY
}

PRE_SET="$WORK_DIR/pre.set"
POST_SET="$WORK_DIR/post.set"
{ extract_pnpm_all "$PRE_AUDIT"; extract_osv_all "$PRE_OSV"; } | sort -u >"$PRE_SET" || true
{ extract_pnpm_all "$POST_AUDIT"; extract_osv_all "$POST_OSV"; } | sort -u >"$POST_SET" || true

NEW_VULNS="$(comm -13 "$PRE_SET" "$POST_SET" || true)"

if [[ -z "$NEW_VULNS" ]]; then
  log_ok "No new advisories of any severity. ($(wc -l <"$POST_SET" | tr -d ' ') existing total.)"
  exit 0
fi

log_error "New advisories introduced by this operation (any severity blocks):"
echo "$NEW_VULNS" | sed 's/^/    /' >&2

log_warn "Restoring previous lockfile and reinstalling clean tree"
cp "$LOCK_BACKUP" "$LOCKFILE"
( cd "$FRONTEND_DIR" && pnpm install --frozen-lockfile )
log_warn "Lockfile restored. Operation rejected."
exit 1
