#!/usr/bin/env bash
# Shared helpers for the supply-chain wrapper scripts.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

c_red()    { printf '\033[31m%s\033[0m' "$*"; }
c_green()  { printf '\033[32m%s\033[0m' "$*"; }
c_yellow() { printf '\033[33m%s\033[0m' "$*"; }
c_bold()   { printf '\033[1m%s\033[0m' "$*"; }

log_info()  { printf '%s %s\n' "$(c_bold "[info]")" "$*"; }
log_ok()    { printf '%s %s\n' "$(c_green "[ ok ]")" "$*"; }
log_warn()  { printf '%s %s\n' "$(c_yellow "[warn]")" "$*"; }
log_error() { printf '%s %s\n' "$(c_red "[fail]")" "$*" >&2; }

# require_tool TOOL "BREW_PACKAGE" "MANUAL_URL"
# Verifies the given executable is on PATH; if not, prints install instructions and exits.
require_tool() {
  local tool="$1"
  local brew_pkg="${2:-$tool}"
  local manual_url="${3:-}"

  if command -v "$tool" >/dev/null 2>&1; then
    return 0
  fi

  log_error "Required tool not found: $tool"
  echo "" >&2
  echo "  Install with Homebrew:" >&2
  echo "    brew install $brew_pkg" >&2
  if [[ -n "$manual_url" ]]; then
    echo "" >&2
    echo "  Or follow upstream instructions:" >&2
    echo "    $manual_url" >&2
  fi
  echo "" >&2
  echo "  This wrapper never auto-installs tools by design (see docs/Security.md)." >&2
  exit 127
}
