# Deployment — <PROJECT_NAME>

Railway is the only target. Production-only, no staging.

## Initial setup

```bash
railway login
railway init      # creates the project
railway link      # links this directory to it
```

Inside the Railway project, create the following services:

- `postgres` — Railway's managed Postgres
- `backend` — built from `backend/Dockerfile`
- `frontend` — built from `frontend/Dockerfile`
- `proxy` (optional) — built from `proxy/Dockerfile`; routes
  `/api/*` → backend, `/*` → frontend. Use this if you want a single
  public URL with TLS terminated at Caddy.

Configure each service's "Build" to point at the right Dockerfile path
and the "Root Directory" to `backend` / `frontend` / `proxy` as
appropriate.

## Env vars (CLI for audit trail)

```bash
railway variables --set DATABASE_URL=...
railway variables --set SENTRY_DSN=...
railway variables --set LOG_LEVEL=INFO
```

Never set via the dashboard — there's no diff history.

For per-service vars, switch service first: `railway service <name>`.

## Deploy

```bash
just deploy   # runs tests, then `railway up`
```

The deploy targets the currently-linked service. Repeat for each
service (backend, frontend, proxy), or use Railway's "Deploy all"
button in the dashboard once services are configured.

## Healthcheck

Backend exposes `/health`. Configure in Railway (per-service):

```toml
[deploy]
healthcheckPath = "/health"
healthcheckTimeout = 30
```

Railway will not route traffic to a deployment that fails the
healthcheck.

## Migrations

Run as a backend pre-deploy step:

```toml
[deploy]
preDeployCommand = "alembic upgrade head"
```

Deploy aborts if migrations fail.

## Custom domain

In Railway: add the custom domain to the `proxy` service (if used)
or `frontend`. Caddy will auto-provision TLS for any domain it
receives requests on; for the nginx-only path, Railway handles TLS.

## Rollback

```bash
railway redeploy --previous
```

Rolls to the prior deployment within seconds.

## Logs

- `railway logs --tail` for live tail
- `railway logs --json` for structured (structlog emits JSON, so this
  is what you want)
- `railway logs --json | jq 'select(.level=="ERROR")'` for error
  filter

`just logs` wraps the Railway tail.

## Smoke

After each deploy:

```bash
just smoke    # runs ./smoke.sh against $SMOKE_URL
```

The smoke script hits `/health` and 2–3 critical-path endpoints. A
non-zero exit blocks the COMMIT phase — investigate, fix, redeploy,
re-smoke.
