# <PROJECT_NAME>

> Generated from `template-py-web`. See `cursor-harness` for the workflow
> that drives this template.

## Stack

- Backend: Python 3.14, FastAPI, SQLAlchemy async, Alembic, Postgres
- Frontend: Vue 3, Vite, TypeScript, biome, vitest
- Container: Chainguard images
- Deploy: Railway

## Get started

```bash
./bootstrap.sh <project-name>
cp .env.example .env       # fill in values
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
| Deploy | `just deploy` |
| Smoke prod | `just smoke` |
| Tail prod logs | `just logs` |
| New migration | `just db-revision "describe change"` |

## Workflow

This project follows the 15-step cycle documented in
`.cursor/rules/00-workflow.mdc`. Phase prompts live in `.cursor/prompts/`.
The current phase is tracked in `AGENTS.md`.

## Layout

```
backend/         FastAPI app, uv-managed
  src/app/       application code
  tests/         pytest + hypothesis
  Dockerfile     multi-stage Chainguard build
frontend/        Vue 3 SPA, pnpm-managed
  src/           components, api/, types
  tests/unit/    vitest
  tests/e2e/     playwright (one smoke)
  Dockerfile     Chainguard nginx serving the build
deploy/          fly.toml.example escape hatch
.cursor/         rules + prompts (synced from cursor-harness)
docs/adr/        architecture decision records
.github/         CI
```

## Supply chain

- Chainguard base images (`cgr.dev/chainguard/*`)
- Lockfiles authoritative (`uv.lock`, `pnpm-lock.yaml`)
- gitleaks blocks commits with secrets
- cosign verifies images in CI
- syft generates SBOM in CI
- Renovate proposes dep updates weekly
