# Phase 06 — Scaffold

The plan is settled and external services are provisioned. Build the
project skeleton from this template.

## Preconditions

- `REQUIREMENTS.md` and `PLAN.md` exist and are up to date
- `AGENTS.md` lists open decisions, all marked resolved or deferred
- The user has run `gh repo create knrch/<project> --template knrch/template-py-web`
- `.env` exists locally with provisioned API keys

## Steps

1. Run `./bootstrap.sh <project-name>` to rewrite placeholders.
2. Verify `.tool-versions`, `pyproject.toml`, `package.json` match
   what `PLAN.md` calls for. Adjust if needed (with user approval per
   `01-tech-stack.mdc`).
3. Run `mise install` to set Python and Node versions.
4. Run `just install` (which calls `uv sync` and `pnpm install`).
5. Confirm `just test` runs (even if no tests exist yet — pytest and
   vitest both exit 0 on empty suites).
6. Confirm `just lint` runs clean.
7. Confirm `just docker-build` builds both images.
8. Initialize the data model: write Alembic revision 0001_initial
   from the entities in `PLAN.md`. Run `alembic upgrade head` against
   docker-compose's Postgres.
9. Wire up the simplest endpoint in the plan as a smoke target —
   typically `GET /api/v1/<entity>` returning an empty list.
10. Wire up the Vue route that calls it.

## Verify before declaring SCAFFOLD complete

- `just dev` runs, frontend loads at http://localhost:5173
- Frontend successfully calls backend `/health` and gets 200
- `just test` passes
- `just lint` passes
- `just docker-up` starts the full stack
- `curl http://localhost:8000/health` returns 200

## Update AGENTS.md

- `## Current Phase` → `TOOLING` (then immediately `FEATURE` once the
  user confirms tooling is happy)
- `## Last Action` → "Scaffolded project, basic /health and one entity
  endpoint working end-to-end"
- `## Next Action` → name the first feature from `PLAN.md` milestone 1
