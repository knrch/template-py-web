# Requirements

> **How to use this file**: write the high-level requirements here in
> your own words. Bullets are fine. Don't worry about polish — the
> agent will surface gaps and ask clarifying questions in the next
> phase. Replace this section.

## Goal

What problem does this solve? Who is it for?

## Functional

- ...

## Non-functional

- Auth: <strategy>
- Scale: <expected load>
- Latency: <target>
- Availability: <target>
- Compliance: <none / GDPR / etc>

## Out of scope

- ...

## Tech stack

(Defaults from template; override only with reason.)
- Backend: FastAPI + Postgres
- Frontend: Vue 3
- Deploy: Railway

## Third-party services anticipated

- Sentry (errors)
- BetterStack (uptime)
- Object storage: <R2 / B2 / S3 / Backblaze>
- Auth: <Clerk / Better-Auth / roll-your-own>
