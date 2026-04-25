# Phase 10 — Docker Test

Local non-Docker testing passed. Now exercise the docker-compose stack.

## Steps

1. `just docker-down` (clean slate).
2. `just docker-build` — rebuild images. Watch for:
   - Chainguard base image working
   - `uv.lock` / `pnpm-lock.yaml` honored (frozen install)
   - Final image is the minimal `:latest` variant, not `-dev`
3. `just docker-up` — bring up the stack.
4. Watch the logs (`just logs-local`) for:
   - Backend reaches "Application startup complete"
   - Postgres healthcheck passes
   - No tracebacks
5. Curl the same endpoints that `smoke.sh` will hit in prod:
   - `GET /health` → 200, expected JSON shape
   - 2–3 critical-path endpoints
6. If any fail, report logs + curl output. Do not advance to RAILWAY
   phase.
7. `just docker-down` to clean up before deploying.

## Common issues

- **Backend can't reach Postgres**: usually `DATABASE_URL` host needs
  to be the service name (`postgres`), not `localhost`. Check the
  compose file and `.env`.
- **Frontend can't reach backend**: in compose, frontend should call
  the backend service name. In dev (Vite), proxy handles this.
- **Image is huge**: the runtime stage probably copied too much.
  Multi-stage should produce a lean final image.

## Update AGENTS.md

- `## Last Action` → "Docker stack runs cleanly, all smoke endpoints
  return expected responses"
- `## Next Action` → "Deploy to Railway"
