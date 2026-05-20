# Phase 13 — Smoke

Production smoke is the gate before COMMIT. If smoke fails, you
**do not commit**. You investigate, fix, redeploy, re-smoke.

## Steps

1. Set `SMOKE_URL` to the Railway public URL (typically already in
   `.env` as `RAILWAY_PUBLIC_URL` after deploy).
2. Run `just smoke`. Under the hood this calls `./smoke.sh`.
3. Smoke must:
   - Hit `/health` and confirm 200 + expected JSON
   - Hit 2–3 critical-path endpoints with realistic payloads
   - Confirm no new error types in Sentry within the last 60 seconds
4. Run `just audit` against the deployed lockfile/digests one more
   time (cheap; catches anything that drifted between local commit
   and the actually-deployed image).
5. If any check fails, **stop**. Do not commit.

## On failure

1. Capture: the failed check, the response, and the relevant Railway
   logs (`railway logs --since 5m --json`).
2. Decide:
   - **Fixable in <30 minutes**: fix locally, redeploy, re-smoke.
   - **Not fixable now**: `railway redeploy --previous` to roll back,
     then debug locally with the same data.
3. After rollback, the working tree is now ahead of prod. Don't commit
   the half-finished state. Either complete-and-redeploy or `git stash`
   and revisit.

## On success

1. Update `AGENTS.md`:
   - `## Last Action` → "Prod smoke passed; audit clean"
   - `## Next Action` → "Commit and push"
2. Proceed to COMMIT phase (`prompts/14-commit.md`).
