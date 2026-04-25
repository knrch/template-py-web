# Phase 11 — Railway Deploy

Docker phase passed. Push to Railway.

## Preconditions

- All env vars set on Railway (`railway variables` confirms)
- `railway.toml` healthcheck path matches a real endpoint
- Migrations exist for any schema changes since last deploy

## Steps

1. `railway status` — confirm correct project and service linked.
2. `git status` — confirm a clean working tree against the LAST commit
   (not yet committed for THIS feature, that comes after smoke).
3. `just deploy`:
   - Runs `railway up`
   - Streams build logs
   - Waits for healthcheck pass
   - Prints public URL
4. Wait until Railway reports the deployment as Active.
5. Note: migrations run automatically as `preDeployCommand`. If they
   fail, the deploy aborts and the previous version stays live. That's
   working as intended.

## If deploy fails

- Build error → fix locally, rebuild Docker, retry from Phase 10
- Healthcheck timeout → check Railway logs (`railway logs`), most
  likely DB connection or missing env var
- Migration error → check `alembic` revision, may need to roll forward
  with a fix-up revision rather than rolling back

## Do NOT

- Commit before smoke passes
- Promote to a separate environment (there is none)
- Manually run migrations on production

## Update AGENTS.md

- `## Current Phase` → `SMOKE`
- `## Last Action` → "Deployed to Railway, awaiting smoke verification"
- `## Next Action` → "Run smoke.sh against $RAILWAY_PUBLIC_URL"
