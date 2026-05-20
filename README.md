# <PROJECT_NAME>

> Generated from `template-py-web`. See `cursor-harness` for the workflow
> that drives this template.

## Stack

- Backend: Python 3.14, FastAPI, SQLAlchemy async, Alembic, Postgres
- Frontend: Vue 3, Vite, TypeScript, ESLint (+ eslint-plugin-vue + typescript-eslint), vitest, playwright
- Container: digest-pinned mainstream public images (`python:3.14-slim`,
  `node:24-alpine`, `nginx:alpine`, `caddy:2-alpine`, `postgres:16-alpine`)
- Deploy: Railway
- Security: gitleaks + semgrep + osv-scanner + pip-audit + pnpm audit +
  trivy, orchestrated by `scripts/audit-all.sh`; dependency operations
  gated by `scripts/safe-uv.sh` / `scripts/safe-pnpm.sh`

## Get started

```bash
./bootstrap.sh <project-name>
cp .env.example .env       # fill in values
just hooks-install         # wires pre-commit; prints missing audit tools

# Resolve digest placeholders before the first build:
docker pull python:3.14-slim
docker inspect --format='{{index .RepoDigests 0}}' python:3.14-slim
# ...and repeat for node:24-alpine, nginx:alpine, caddy:2-alpine,
# postgres:16-alpine, ghcr.io/astral-sh/uv:0.11.8.
# Substitute each PIN_ME_AT_BOOTSTRAP literal in:
#   - backend/Dockerfile
#   - frontend/Dockerfile
#   - proxy/Dockerfile
#   - docker-compose.yml
#   - scripts/audit-all.sh   (RUNTIME_IMAGES + UV_IMAGE)
# All locations must agree.

just docker-up
open http://localhost:5173
```

## Daily workflow

| Action | Command |
|---|---|
| Start dev | `just dev-backend` and `just dev-frontend` |
| Test | `just test` |
| Lint | `just lint` |
| Format | `just fmt` |
| Local stack | `just docker-up` / `just docker-down` |
| Local stack + Caddy proxy | `just docker-up-proxy` |
| Audit (lockfile + source) | `just audit` |
| Audit incl. Trivy on images | `just audit-images` |
| Add a backend dep (audited) | `just safe-uv add <pkg>` |
| Add a frontend dep (audited) | `just safe-pnpm add <pkg>` |
| Deploy | `just deploy` |
| Smoke prod | `just smoke` |
| Tail prod logs | `just logs` |
| New migration | `just db-revision "describe change"` |

## Pre-commit bypass envs (emergency only)

| Env | Effect |
|---|---|
| `SKIP_STATIC_SCAN=1` | Skip gitleaks + semgrep |
| `SKIP_GITLEAKS=1` | Skip gitleaks only |
| `SKIP_SEMGREP=1` | Skip semgrep only |
| `SKIP_AUDIT=1` | Skip `scripts/audit-all.sh` block only |

If a bypass becomes routine, fix the allowlist (`.gitleaks.toml`,
`.semgrepignore`, `.trivyignore`) — don't accumulate bypass habits.

## Workflow

This project follows the 15-step cycle documented in
`.cursor/rules/00-workflow.mdc`. Phase prompts live in `.cursor/prompts/`.
The current phase is tracked in `AGENTS.md`.

## Layout

```
backend/         FastAPI app, uv-managed
  src/app/       application code
  tests/         pytest + hypothesis
  Dockerfile     multi-stage, digest-pinned python:3.14-slim
frontend/        Vue 3 SPA, pnpm-managed
  src/           components, api/, types
  tests/unit/    vitest
  tests/e2e/     playwright (one smoke)
  Dockerfile     multi-stage; nginx:alpine serves the build
proxy/           Optional Caddy reverse proxy (compose profile: proxy)
scripts/         _lib.sh, _static_scan.sh, audit-all.sh, safe-uv.sh,
                 safe-pnpm.sh, install-hooks.sh, git-hooks/pre-commit
.gitleaks.toml   secret-scan allowlist
.semgrepignore   semgrep traversal exclusions
.trivyignore     accepted CVEs (each with reason + re-check date)
deploy/          fly.toml.example escape hatch
.cursor/         rules + prompts (synced from cursor-harness)
docs/            Security.md, Deployment.md, adr/
.github/         CI
```

## Supply chain

- Digest-pinned mainstream public bases (no Chainguard, no cosign)
- Lockfiles authoritative (`uv.lock`, `pnpm-lock.yaml`)
- Every dep op goes through `scripts/safe-uv.sh` / `scripts/safe-pnpm.sh`
  — adds/removes that introduce a new advisory of any severity are
  rejected and the lockfile is restored
- gitleaks blocks commits with secrets; semgrep runs SAST on staged
  files
- Trivy gates HIGH/CRITICAL CVEs in pinned base OS packages
  (`.trivyignore` for accepted ones, with documented reason + re-check
  date)
- Renovate proposes dep + digest updates weekly
