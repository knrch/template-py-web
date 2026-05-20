# ADR 0001: Tech stack

- **Status**: Accepted
- **Date**: 2026-04-25 (initial); 2026-05-20 (revised — removed
  Chainguard, added audit toolchain)
- **Deciders**: Ken

## Context

Replicable single-developer workflow targeting backend + Vue frontend
deployments to Railway. Need locked tooling to reduce decision fatigue
across projects.

## Decision

- Backend: Python 3.14, uv, ruff, pyright, FastAPI, SQLAlchemy 2.0
  async, Alembic, asyncpg, structlog, pydantic-settings, sentry-sdk
- Frontend: Node 24, pnpm, vite, Vue 3 (composition API),
  ESLint 9 flat config (eslint-plugin-vue + typescript-eslint), vitest,
  playwright, @sentry/vue
- Container: digest-pinned mainstream public images
  (`python:3.14-slim`, `node:24-alpine`, `nginx:alpine`, optional
  `caddy:2-alpine`, `postgres:16-alpine`). No Chainguard, no cosign.
- Deploy: Railway production-only
- Audit: gitleaks + semgrep + osv-scanner + pip-audit + pnpm audit +
  trivy via `scripts/audit-all.sh`; dependency adds gated by
  `scripts/safe-uv.sh` / `scripts/safe-pnpm.sh`
- Pre-commit: lefthook invokes `scripts/git-hooks/pre-commit`
  (three-stage: gitleaks staged → semgrep staged → conditional audit-all)

Alternatives rejected:
- Poetry / mypy / black — superseded by uv / pyright / ruff
- React — Vue is smaller, less churn, single-dev-friendly
- npm / yarn — pnpm has stricter resolution and faster CI
- Multiple environments — single-dev workflow doesn't justify the cost
- Chainguard + cosign verification — added a paid vendor dependency
  without a clear marginal benefit at this scale; digest-pinned
  mainstream bases + trivy + Renovate cover the same threat model
- Biome — faster and zero-config but does not lint `.vue` template
  blocks or run vue-specific rules. ESLint 9 with `eslint-plugin-vue`
  and `typescript-eslint` covers both `<script setup>` and `<template>`,
  matches skincare's lived practice, and reuses the same flat-config
  layering for any future plugin (e.g. `eslint-plugin-better-tailwindcss`
  when Tailwind lands in PLAN)
- Prettier — ESLint + plugin formatting + biome-style printer rules
  cover the same ground without the dual-toolchain overhead

## Consequences

Positive:
- Cross-project muscle memory
- Faster scaffolding via template repos
- Stronger supply-chain posture out of the box, with no vendor lock-in
- Renovate auto-pins digests; cadence is automated

Negative:
- Locked-in choices may age; revisit ADR every 12 months
- Cursor agents need explicit instruction to not propose alternatives
  (handled by `.cursor/rules/01-tech-stack.mdc`)
- Day-one bootstrap requires resolving `PIN_ME_AT_BOOTSTRAP` digest
  placeholders (printed by `bootstrap.sh`); after that, Renovate keeps
  them current
