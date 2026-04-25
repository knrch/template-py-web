#!/usr/bin/env bash
# Production smoke test. Runs after Railway deploy, before commit.
# Required env: SMOKE_URL
set -euo pipefail

: "${SMOKE_URL:?SMOKE_URL must be set (Railway public URL)}"

GREEN=$'\033[32m'
RED=$'\033[31m'
RESET=$'\033[0m'
FAIL=0

check() {
    local name="$1"
    local url="$2"
    local expect_status="${3:-200}"
    local body
    local status

    body=$(curl -sS -w "\n%{http_code}" "$url" || echo $'\n000')
    status="${body##*$'\n'}"
    body="${body%$'\n'*}"

    if [[ "$status" == "$expect_status" ]]; then
        echo "${GREEN}OK${RESET}   $name ($status)"
    else
        echo "${RED}FAIL${RESET} $name (got $status, expected $expect_status)"
        echo "       URL: $url"
        echo "       Body: ${body:0:200}"
        FAIL=1
    fi
}

echo "Smoke target: $SMOKE_URL"
echo

check "health" "$SMOKE_URL/health"
# Add critical-path checks here, e.g.:
# check "list_users" "$SMOKE_URL/api/v1/users"

echo
if [[ $FAIL -eq 0 ]]; then
    echo "${GREEN}All smoke checks passed.${RESET}"
    exit 0
else
    echo "${RED}Smoke FAILED. Do not commit.${RESET}"
    exit 1
fi
