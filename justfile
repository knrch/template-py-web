# Project task runner. Run `just` for the list.

set shell := ["bash", "-uc"]

# default: show available recipes
default:
    @just --list

# install backend and frontend deps from lockfiles
install:
    cd backend && uv sync --frozen
    cd frontend && pnpm install --frozen-lockfile

# run backend and frontend in dev mode (two terminals recommended)
dev-backend:
    cd backend && uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

dev-frontend:
    cd frontend && pnpm dev

# unit tests for both stacks
test:
    cd backend && uv run pytest
    cd frontend && pnpm test --run

# integration tests (requires docker-compose up)
test-int:
    cd backend && uv run pytest -m integration

# end-to-end (requires services running)
test-e2e:
    cd frontend && pnpm exec playwright test

# lint & format check (no autofix; CI runs this)
lint:
    cd backend && uv run ruff check . && uv run ruff format --check .
    cd backend && uv run pyright
    cd frontend && pnpm exec eslint . --max-warnings 0
    cd frontend && pnpm exec vue-tsc --noEmit

# autofix what's autofixable
fmt:
    cd backend && uv run ruff check --fix . && uv run ruff format .
    cd frontend && pnpm exec eslint . --fix

# build both Dockerfiles
docker-build:
    docker compose build

# bring up local stack (postgres, backend, frontend)
docker-up:
    docker compose up -d
    @echo "Backend: http://localhost:8000  Frontend: http://localhost:5173"

# bring up stack with Caddy proxy in front (http://localhost:8080)
docker-up-proxy:
    docker compose --profile proxy up -d
    @echo "Proxy: http://localhost:8080  Backend: http://localhost:8000  Frontend: http://localhost:5173"

docker-down:
    docker compose down -v

# tail compose logs
logs-local:
    docker compose logs -f

# tail Railway logs
logs:
    railway logs --json | jq -r '.message // .'

# deploy to Railway prod (after local + docker tests pass)
deploy:
    @echo "==> Verifying clean state"
    @git diff --quiet || (echo "Uncommitted changes against last commit; review with 'git status'"; true)
    @echo "==> Running tests"
    just test
    @echo "==> Deploying to Railway"
    railway up

# run smoke tests against $SMOKE_URL (defaults to .env)
smoke:
    SMOKE_URL=${SMOKE_URL:?set SMOKE_URL or source .env} ./smoke.sh

# database migration helpers
db-revision message:
    cd backend && uv run alembic revision --autogenerate -m "{{message}}"

db-upgrade:
    cd backend && uv run alembic upgrade head

db-downgrade:
    cd backend && uv run alembic downgrade -1

# pre-commit setup (lefthook if available, else core.hooksPath)
hooks-install:
    scripts/install-hooks.sh

# Supply-chain audits ------------------------------------------------------

# Lockfile + source scans (gitleaks + semgrep). No image scanning.
audit:
    scripts/audit-all.sh

# Above + Trivy on digest-pinned bases (HIGH/CRITICAL gate).
audit-images:
    scripts/audit-all.sh --with-images

# Above, but Trivy findings are advisory (used in scheduled CI).
audit-images-informational:
    scripts/audit-all.sh --with-images-informational

# Audited dependency operations — never bare `uv add` or `pnpm add`.
safe-uv +args:
    scripts/safe-uv.sh {{args}}

safe-pnpm +args:
    scripts/safe-pnpm.sh {{args}}

# SBOM for the built image (optional artifact)
sbom:
    syft scan dir:. -o spdx-json > sbom.json
