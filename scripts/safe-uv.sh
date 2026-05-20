#!/usr/bin/env bash
# Audited backend dependency operations.
#
# Wraps `uv` so that any change to backend/uv.lock is followed by
# `osv-scanner` + `pip-audit` against the new lockfile. If ANY new advisory
# (any severity, including low/info) is introduced that was not present
# before, the lockfile is restored and the change is rejected.
#
# Usage:
#   scripts/safe-uv.sh sync
#   scripts/safe-uv.sh add <pkg>[==version]...
#   scripts/safe-uv.sh add --dev <pkg>...
#   scripts/safe-uv.sh remove <pkg>...
#   scripts/safe-uv.sh lock --upgrade

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

BACKEND_DIR="$REPO_ROOT/backend"
LOCKFILE="$BACKEND_DIR/uv.lock"

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") <uv-subcommand> [args...]" >&2
  echo "Common: sync | add <pkg> | remove <pkg> | lock --upgrade" >&2
  exit 64
fi

require_tool uv uv "https://docs.astral.sh/uv/getting-started/installation/"
require_tool osv-scanner osv-scanner "https://google.github.io/osv-scanner/installation/"
require_tool pip-audit pip-audit "https://github.com/pypa/pip-audit#installation"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

LOCK_BACKUP="$WORK_DIR/uv.lock.before"
PRE_OSV="$WORK_DIR/pre.osv.json"
POST_OSV="$WORK_DIR/post.osv.json"
PRE_PIP="$WORK_DIR/pre.pip.json"
POST_PIP="$WORK_DIR/post.pip.json"
PRE_REQ="$WORK_DIR/pre.requirements.txt"
POST_REQ="$WORK_DIR/post.requirements.txt"

if [[ -f "$LOCKFILE" ]]; then
  log_info "Snapshotting uv.lock"
  cp "$LOCKFILE" "$LOCK_BACKUP"
  log_info "Auditing current lockfile (before)"
  osv-scanner --lockfile "$LOCKFILE" --format json >"$PRE_OSV" 2>/dev/null || true
  ( cd "$BACKEND_DIR" && uv export --no-hashes --no-dev --format requirements-txt >"$PRE_REQ" 2>/dev/null ) || true
  if [[ -s "$PRE_REQ" ]]; then
    pip-audit -r "$PRE_REQ" --format json >"$PRE_PIP" 2>/dev/null || true
  fi
else
  log_warn "uv.lock not found yet (first sync?). Skipping pre-audit."
  : >"$PRE_OSV"; : >"$PRE_PIP"
fi

log_info "Running: uv $*"
( cd "$BACKEND_DIR" && uv "$@" )

if [[ ! -f "$LOCKFILE" ]]; then
  log_error "uv.lock still missing after operation; aborting."
  exit 2
fi

log_info "Auditing new lockfile (after)"
osv-scanner --lockfile "$LOCKFILE" --format json >"$POST_OSV" 2>/dev/null || true
( cd "$BACKEND_DIR" && uv export --no-hashes --no-dev --format requirements-txt >"$POST_REQ" 2>/dev/null ) || true
if [[ -s "$POST_REQ" ]]; then
  pip-audit -r "$POST_REQ" --format json >"$POST_PIP" 2>/dev/null || true
fi

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

extract_pip_all() {
  local file="$1"
  if [[ ! -s "$file" ]]; then echo ""; return 0; fi
  python3 - "$file" <<'PY'
import json, sys
try:
  d = json.load(open(sys.argv[1]))
except Exception:
  sys.exit(0)
deps = d.get("dependencies") or d.get("packages") or []
for dep in deps:
  vulns = dep.get("vulns") or dep.get("vulnerabilities") or []
  for v in vulns:
    sev = (v.get("severity") or "unknown").lower()
    print(f"pip:{v.get('id','?')}:{sev}")
PY
}

PRE_SET="$WORK_DIR/pre.set"
POST_SET="$WORK_DIR/post.set"
{ extract_osv_all "$PRE_OSV"; extract_pip_all "$PRE_PIP"; } | sort -u >"$PRE_SET" || true
{ extract_osv_all "$POST_OSV"; extract_pip_all "$POST_PIP"; } | sort -u >"$POST_SET" || true

NEW_VULNS="$(comm -13 "$PRE_SET" "$POST_SET" || true)"

if [[ -z "$NEW_VULNS" ]]; then
  log_ok "No new advisories of any severity. ($(wc -l <"$POST_SET" | tr -d ' ') existing total.)"
  exit 0
fi

log_error "New advisories introduced by this operation (any severity blocks):"
echo "$NEW_VULNS" | sed 's/^/    /' >&2

if [[ -f "$LOCK_BACKUP" ]]; then
  log_warn "Restoring previous uv.lock and re-syncing"
  cp "$LOCK_BACKUP" "$LOCKFILE"
  ( cd "$BACKEND_DIR" && uv sync --frozen )
  log_warn "Lockfile restored. Operation rejected."
else
  log_warn "No prior lockfile to restore; current uv.lock kept but contains new advisories."
fi
exit 1
