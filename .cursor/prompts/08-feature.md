# Phase 08 — Feature

Implement the next feature from `PLAN.md`. One feature, one cycle.

## Steps

1. Read `AGENTS.md` for the current target. If unclear, ask.
2. Confirm with the user which milestone/feature you're implementing.
   Don't guess.
3. Sketch the implementation in 3–5 bullets:
   - Endpoints / components to add
   - Data model changes (and Alembic revision needed)
   - Tests you'll write
   - Any new dependency you need (propose per `01-tech-stack.mdc`)
4. Wait for user approval of the sketch.
5. Implement, **with tests written alongside**, not after:
   - Backend: pytest tests for service layer, hypothesis where input
     space is non-trivial
   - Frontend: vitest for component logic
6. Run `just lint test` — must pass.
7. Update `AGENTS.md`:
   - `## Last Action` → one-line summary of the feature
   - `## Next Action` → "Run LOCAL phase, then DOCKER"

## Definition of done (FEATURE phase)

- New code is typed and passes pyright / tsc strict
- New code has tests
- `just lint` clean
- `just test` green
- No new dependency added without prior approval
- No new ADR needed, OR ADR was written
- `AGENTS.md` updated

If any of these fail, the phase is not done.
