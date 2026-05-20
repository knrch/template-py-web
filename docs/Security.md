# Security policy — <PROJECT_NAME>

Single-developer threat model; the goal is to make the easy path also
the secure path.

## Trust model

- **Container bases**: digest-pinned mainstream public images
  (`python:3.14-slim@sha256:...`, `node:24-alpine@sha256:...`,
  `nginx:alpine@sha256:...`, optional `caddy:2-alpine@sha256:...`,
  `postgres:16-alpine@sha256:...`). Renovate keeps digests fresh.
  cosign / Sigstore is not used.
- **Dependencies**: `uv.lock` and `pnpm-lock.yaml` are the source of
  truth. Every install goes through `scripts/safe-uv.sh` /
  `scripts/safe-pnpm.sh`, which reject any new advisory (any severity)
  introduced by an operation.
- **Source secrets**: blocked at commit time by gitleaks; allowlist in
  `.gitleaks.toml`.
- **SAST**: semgrep `p/typescript` + `p/python` on staged files at
  pre-commit; full tree on scheduled CI.

## Audit layers

| Tool | What it covers | Where it runs |
|---|---|---|
| gitleaks | Secrets in staged / committed content | pre-commit (staged) + CI (full tree) |
| semgrep `p/typescript`, `p/python` | TS/Vue + Python SAST | pre-commit (staged) + CI (full tree) |
| osv-scanner | Cross-ecosystem CVE backstop on lockfiles | pre-commit on dep changes + scheduled CI |
| pip-audit | Python advisory DB on the exported requirements | pre-commit on dep changes + CI |
| pnpm audit | npm advisory DB on `pnpm-lock.yaml` | pre-commit on dep changes + CI |
| trivy | OS packages in pinned Docker bases | pre-commit on dep changes + scheduled CI |
| safe-uv.sh / safe-pnpm.sh | Gate every dependency add/remove/update | local, on demand |

`scripts/audit-all.sh` orchestrates all of these. Modes:

- bare: lockfile + source scans
- `--with-images`: also Trivy on pinned bases (gate)
- `--with-images-informational`: same, but image findings advisory
- `--supply-chain-only`: lockfile + Trivy (used by pre-commit)

## Bypass envs

These exist for emergencies — a hook failing wrongly in a way you
can't fix in the moment. They are not for routine commits.

| Env | Effect |
|---|---|
| `SKIP_STATIC_SCAN=1` | gitleaks + semgrep skipped |
| `SKIP_GITLEAKS=1` | gitleaks skipped only |
| `SKIP_SEMGREP=1` | semgrep skipped only |
| `SKIP_AUDIT=1` | `scripts/audit-all.sh` block skipped only |
| `git commit --no-verify` | nuclear |

If a bypass becomes routine, fix the allowlist file
(`.gitleaks.toml`, `.semgrepignore`, `.trivyignore`) — every entry
must include a reason and a re-check date.

## Image scan policy

- Trivy runs `--pkg-types os --severity HIGH,CRITICAL
  --ignore-unfixed` against each digest in `RUNTIME_IMAGES` /
  `UV_IMAGE` in `scripts/audit-all.sh`.
- Unfixed CVEs upstream → add to `.trivyignore` with the CVE id, the
  affected base, an upstream tracker link, and a monthly re-check
  date.
- The `--with-images` mode is the **gate**; `--with-images-
  informational` is for cadence visibility without blocking.

## Digest refresh cadence

- Renovate proposes new digests weekly (Monday before 6am
  Asia/Tokyo).
- After merging a digest bump, mirror the new digest into
  `scripts/audit-all.sh` (the `RUNTIME_IMAGES` array). All locations
  — Dockerfiles, docker-compose.yml, audit-all.sh — must agree.

## If a secret leaks

1. Rotate immediately — the old value is compromised whether or not
   anyone "actually saw" it.
2. Update Railway, `.env`, and your password manager / `SECRETS.md`.
3. If committed: rotate first, then `git filter-repo` to scrub
   history, then force-push. Assume the old value is public anyway.
4. Run `git log --all -S<secret>` to confirm scrub.

## Frontend env-var hygiene

Vite exposes only env vars prefixed with `VITE_` to client code. Never
put backend secrets in `VITE_` vars — they ship to every browser. If
the frontend needs a secret-bearing operation, route it through the
backend.
