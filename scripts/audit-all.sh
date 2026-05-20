#!/usr/bin/env bash
# One-shot security audit: dependency lockfiles (+ optional Docker images),
# gitleaks (per-path source scan), and Semgrep (TS/Vue + Python).
#
# Usage:
#   scripts/audit-all.sh
#   scripts/audit-all.sh --with-images
#   scripts/audit-all.sh --with-images-informational
#   scripts/audit-all.sh --supply-chain-only
#   scripts/audit-all.sh --skip-gitleaks --skip-semgrep
#
# Exit code 0 if no findings (any severity where applicable), 1 if any failed,
# 127 if a required tool is missing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

WITH_IMAGES=0
IMAGES_INFORMATIONAL=0
SKIP_GITLEAKS="${SKIP_GITLEAKS:-0}"
SKIP_SEMGREP="${SKIP_SEMGREP:-0}"
RUN_STATIC_SCANS=1

for arg in "$@"; do
  case "$arg" in
    --with-images) WITH_IMAGES=1 ;;
    --with-images-informational) WITH_IMAGES=1; IMAGES_INFORMATIONAL=1 ;;
    --skip-gitleaks) SKIP_GITLEAKS=1 ;;
    --skip-semgrep) SKIP_SEMGREP=1 ;;
    --supply-chain-only) RUN_STATIC_SCANS=0 ;;
    -h|--help)
      cat <<USAGE
Usage: $(basename "$0") [options]

  --with-images                 Scan pinned Docker bases with Trivy (HIGH/CRITICAL;
                                distro OS packages). Counts toward exit code.
  --with-images-informational   Same image policy, but failures do not change the exit code.
  --skip-gitleaks               Skip secret scan (or set SKIP_GITLEAKS=1).
  --skip-semgrep                Skip Semgrep (or set SKIP_SEMGREP=1).
  --supply-chain-only           Lockfiles + pip-audit + optional trivy only
                                (used from pre-commit after staged Gitleaks/Semgrep).

With no flags: lockfiles + gitleaks + semgrep are run.
USAGE
      exit 0 ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 64 ;;
  esac
done

require_tool osv-scanner osv-scanner "https://google.github.io/osv-scanner/installation/"
require_tool pnpm pnpm "https://pnpm.io/installation"
require_tool pip-audit pip-audit "https://github.com/pypa/pip-audit#installation"
require_tool uv uv "https://docs.astral.sh/uv/getting-started/installation/"
if [[ "$WITH_IMAGES" -eq 1 ]]; then
  require_tool trivy trivy "https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
fi

# shellcheck source=_static_scan.sh
source "$SCRIPT_DIR/_static_scan.sh"

FAIL=0

echo
log_info "=== Frontend (pnpm-lock.yaml) — all severities ==="
( cd "$REPO_ROOT/frontend" && pnpm audit --audit-level=low ) || FAIL=1
osv-scanner --lockfile "$REPO_ROOT/frontend/pnpm-lock.yaml" || FAIL=1

echo
log_info "=== Backend (uv.lock) — all severities ==="
osv-scanner --lockfile "$REPO_ROOT/backend/uv.lock" || FAIL=1
TMPREQ="$(mktemp)"
trap 'rm -f "$TMPREQ"' EXIT
( cd "$REPO_ROOT/backend" && uv export --no-hashes --no-dev --format requirements-txt >"$TMPREQ" )
pip-audit -r "$TMPREQ" --strict || FAIL=1

if [[ "$RUN_STATIC_SCANS" -eq 1 ]]; then
  if [[ "$SKIP_GITLEAKS" != "1" ]]; then
    run_gitleaks_audit_all || FAIL=1
  else
    echo
    log_warn "Skipping Gitleaks (SKIP_GITLEAKS / --skip-gitleaks)."
  fi
  if [[ "$SKIP_SEMGREP" != "1" ]]; then
    run_semgrep_audit_all || FAIL=1
  else
    echo
    log_warn "Skipping Semgrep (SKIP_SEMGREP / --skip-semgrep)."
  fi
else
  echo
  log_info "Static scans skipped (--supply-chain-only; pre-commit ran Gitleaks/Semgrep)."
fi

IMAGE_FAIL=0

# Digest-pinned bases — MUST match docker-compose.yml + backend/Dockerfile +
# frontend/Dockerfile + proxy/Dockerfile.
RUNTIME_IMAGES=(
  "python:3.14-slim@sha256:PIN_ME_AT_BOOTSTRAP"
  "node:24-alpine@sha256:PIN_ME_AT_BOOTSTRAP"
  "nginx:alpine@sha256:PIN_ME_AT_BOOTSTRAP"
  "caddy:2-alpine@sha256:PIN_ME_AT_BOOTSTRAP"
  "postgres:16-alpine@sha256:PIN_ME_AT_BOOTSTRAP"
)
UV_IMAGE="ghcr.io/astral-sh/uv:0.11.8@sha256:PIN_ME_AT_BOOTSTRAP"
TRIVY_IGNORE="$REPO_ROOT/.trivyignore"

if [[ "$WITH_IMAGES" -eq 1 ]]; then
  echo
  if [[ "$IMAGES_INFORMATIONAL" -eq 1 ]]; then
    log_info "=== Docker base images (Trivy) — INFORMATIONAL ==="
  else
    log_info "=== Docker base images (Trivy) — HIGH/CRITICAL gate ==="
  fi

  scan_runtime_image() {
    local img="$1"
    if [[ "$img" == *PIN_ME_AT_BOOTSTRAP* ]]; then
      log_warn "Skipping unresolved digest: $img — pin it during bootstrap."
      return 0
    fi
    log_info "Scanning ${img} (distro pkgs)"
    local ign=()
    [[ -f "$TRIVY_IGNORE" ]] && ign+=(--ignorefile "$TRIVY_IGNORE")
    if ! trivy image --scanners vuln --pkg-types os \
      --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 --no-progress \
      "${ign[@]}" "$img"; then
      IMAGE_FAIL=1
    fi
  }

  for tag in "${RUNTIME_IMAGES[@]}"; do
    scan_runtime_image "$tag"
  done

  if [[ "$UV_IMAGE" != *PIN_ME_AT_BOOTSTRAP* ]]; then
    log_info "Scanning ${UV_IMAGE} (uv binaries)"
    if ! trivy image --scanners vuln --severity HIGH,CRITICAL \
      --exit-code 1 --no-progress "${UV_IMAGE}"; then
      IMAGE_FAIL=1
    fi
  fi

  if [[ "$IMAGES_INFORMATIONAL" -eq 0 && "$IMAGE_FAIL" -eq 1 ]]; then
    FAIL=1
  fi
fi

echo
if [[ "$FAIL" -eq 0 ]]; then
  if [[ "$IMAGE_FAIL" -eq 1 ]]; then
    log_warn "Lockfile / static scans clean; image findings were informational only."
  else
    log_ok "All audits clean."
  fi
else
  log_error "One or more audits failed. See output above."
fi
exit "$FAIL"
