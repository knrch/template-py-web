# ADR 0001: Tech stack

- **Status**: Accepted
- **Date**: 2026-04-25
- **Deciders**: Ken

## Context

Replicable single-developer workflow targeting backend + Vue frontend
deployments to Railway. Need locked tooling to reduce decision fatigue
across projects.

## Decision

- Backend: Python 3.14, uv, ruff, pyright, FastAPI, SQLAlchemy 2.0
  async, Alembic, asyncpg, structlog, pydantic-settings, sentry-sdk
- Frontend: Node 24, pnpm, vite, Vue 3 (composition API), biome,
  vitest, playwright, @sentry/vue
- Container: Chainguard images only
- Deploy: Railway production-only
- Pre-commit: lefthook + gitleaks (blocking)

Alternatives rejected:
- Poetry / mypy / black — superseded by uv / pyright / ruff
- React — Vue is smaller, less churn, single-dev-friendly
- npm / yarn — pnpm has stricter resolution and faster CI
- Docker Hub Python — Chainguard images cut CVE noise dramatically
- Multiple environments — single-dev workflow doesn't justify the cost

## Consequences

Positive:
- Cross-project muscle memory
- Faster scaffolding via template repos
- Stronger supply-chain posture out of the box

Negative:
- Locked-in choices may age; revisit ADR every 12 months
- Cursor agents need explicit instruction to not propose alternatives
  (handled by `.cursor/rules/01-tech-stack.mdc`)
