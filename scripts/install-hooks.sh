#!/usr/bin/env bash
# Install git hooks for this clone. Two install modes:
#   1. lefthook (default if `lefthook` is on PATH) — runs scripts/git-hooks/pre-commit
#      from lefthook.yml.
#   2. core.hooksPath (fallback) — points git at scripts/git-hooks directly.
# Idempotent.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

HOOKS_DIR="$REPO_ROOT/scripts/git-hooks"

if [[ ! -d "$HOOKS_DIR" ]]; then
  log_error "Hooks directory not found: $HOOKS_DIR"
  exit 1
fi

chmod +x "$HOOKS_DIR"/* 2>/dev/null || true

cd "$REPO_ROOT"

if command -v lefthook >/dev/null 2>&1; then
  log_info "Installing via lefthook"
  lefthook install
  log_ok "lefthook hooks installed (pre-commit calls scripts/git-hooks/pre-commit)."
else
  CURRENT="$(git config --local --get core.hooksPath || true)"
  TARGET="scripts/git-hooks"
  if [[ "$CURRENT" == "$TARGET" ]]; then
    log_ok "Hooks already installed (core.hooksPath=$TARGET)."
  else
    git config --local core.hooksPath "$TARGET"
    log_ok "Installed: core.hooksPath=$TARGET"
  fi
fi

echo
log_info "Verifying audit tools are on PATH..."
MISSING=0
for tool in osv-scanner pip-audit pnpm uv trivy gitleaks semgrep; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '  %s %s\n' "$(c_green '[ ok ]')" "$tool"
  else
    printf '  %s %s (missing)\n' "$(c_yellow '[warn]')" "$tool"
    MISSING=1
  fi
done

if [[ "$MISSING" -eq 1 ]]; then
  echo
  log_warn "Some audit tools are missing. Install with:"
  echo "    brew install osv-scanner pip-audit aquasecurity/trivy/trivy gitleaks semgrep" >&2
  echo "    brew install pnpm uv  # if not already installed" >&2
  echo
  log_warn "The pre-commit hook will fail until these are available."
  exit 0
fi

log_ok "Pre-commit security audit is now active."
