# Project: <PROJECT_NAME>

## Current Phase

REQUIREMENTS

## Last Action

Project created from template-py-web.

## Next Action

Fill out `REQUIREMENTS.md`, then run prompts/01-requirements-review.md.

## Open Decisions

- [ ] Auth strategy (typically roll-your-own; document in ADR)
- [ ] Domain name (for Railway custom domain)
- [ ] Sentry project created?
- [ ] BetterStack monitor configured?
- [ ] Caddy proxy in front (compose profile + Railway service), or
      direct backend + frontend exposure?
- [ ] Digest placeholders resolved (`PIN_ME_AT_BOOTSTRAP` in
      backend/Dockerfile, frontend/Dockerfile, proxy/Dockerfile,
      docker-compose.yml, scripts/audit-all.sh)?

## Tech Stack (locked)

- Backend: Python 3.14, uv, ruff, pyright, FastAPI, SQLAlchemy 2.0
  (async), Alembic, asyncpg
- Frontend: TypeScript, pnpm, vite, Vue 3, ESLint (eslint-plugin-vue + typescript-eslint), vitest, playwright
- Container: digest-pinned `python:3.14-slim`, `node:24-alpine`,
  `nginx:alpine`, optional `caddy:2-alpine` (no Chainguard, no cosign)
- Deploy: Railway (production only)
- Observability: structlog, Sentry, BetterStack
- Audit: gitleaks + semgrep + osv-scanner + pip-audit + pnpm audit +
  trivy via `scripts/audit-all.sh`; dep ops via `scripts/safe-uv.sh` /
  `scripts/safe-pnpm.sh`
- Pre-commit runner: lefthook (invokes `scripts/git-hooks/pre-commit`)

## Conventions

- Branch policy: main only, no PRs
- Phase transitions tracked here
- ADRs in `docs/adr/`
- Secrets in Railway env (`railway variables --set ...`), never hardcoded
- Pre-commit bypass envs (`SKIP_STATIC_SCAN`, `SKIP_GITLEAKS`,
  `SKIP_SEMGREP`, `SKIP_AUDIT`) are emergency only — fix the allowlist
  instead
