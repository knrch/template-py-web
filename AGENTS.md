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

## Tech Stack (locked)

- Backend: Python 3.14, uv, ruff, pyright, FastAPI, SQLAlchemy 2.0 (async), Alembic, asyncpg
- Frontend: TypeScript, pnpm, vite, Vue 3, biome, vitest, playwright
- Container: cgr.dev/chainguard/{python,node,nginx}
- Deploy: Railway (production only)
- Observability: structlog, Sentry, BetterStack
- Pre-commit: lefthook + gitleaks (blocking)

## Conventions

- Branch policy: main only, no PRs
- Phase transitions tracked here
- ADRs in `docs/adr/`
- Secrets in Railway env (`railway variables --set ...`), never hardcoded
