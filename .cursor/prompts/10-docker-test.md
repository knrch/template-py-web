# Phase 10 — Docker Test

Local non-Docker testing passed. Now exercise the docker-compose stack.

## Steps

1. `just docker-down` (clean slate).
2. `just docker-build` — rebuild images. Watch for:
   - All `FROM` lines use a digest-pinned mainstream base
     (`python:3.14-slim@sha256:...`, `node:24-alpine@sha256:...`,
     `nginx:alpine@sha256:...`, etc.)
   - `uv.lock` / `pnpm-lock.yaml` honored (frozen install)
   - Runtime stage runs as a non-root user
3. `just docker-up` — bring up the stack.
4. Watch the logs (`just logs-local`) for:
   - Backend reaches "Application startup complete"
   - Postgres healthcheck passes
   - No tracebacks
5. Curl the same endpoints that `smoke.sh` will hit in prod:
   - `GET /health` → 200, expected JSON shape
   - 2–3 critical-path endpoints
6. Run `just audit-images-informational` (Trivy against the
   digest-pinned bases) — surface findings, don't gate on them yet.
   Update `.trivyignore` for any HIGH/CRITICAL that's accepted with
   a documented reason and a re-check date.
7. If any of 4–5 fail, report logs + curl output. Do not advance to
   the RAILWAY phase.
8. `just docker-down` to clean up before deploying.

## Common issues

- **Backend can't reach Postgres**: usually `DATABASE_URL` host needs
  to be the service name (`postgres`), not `localhost`. Check the
  compose file and `.env`.
- **Frontend can't reach backend**: in compose, frontend should call
  the backend service name. In dev (Vite), proxy handles this.
- **Image is huge**: the runtime stage probably copied too much.
  Multi-stage should produce a lean final image.
- **Trivy flags an unfixable HIGH**: add it to `.trivyignore` with a
  comment naming the CVE, the affected base, and a monthly re-check
  date. Don't silently suppress.

## Update AGENTS.md

- `## Last Action` → "Docker stack runs cleanly, all smoke endpoints
  return expected responses, Trivy image scan reviewed"
- `## Next Action` → "Deploy to Railway"
