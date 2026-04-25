# Phase 14 — Commit

Smoke passed. The change is live and verified. Commit and push.

## Preconditions

- `just smoke` exited 0 against the Railway URL
- `AGENTS.md` reflects the completed work
- No half-finished work in the tree

## Steps

1. `git status` — review what's about to be committed.
2. `git diff` — sanity check, especially for accidentally-staged
   secrets, large binaries, or `.env` files.
3. Construct a conventional commit message:
   - `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `build:`
   - Single-line subject under 72 chars
   - Body (optional) explaining why, not what
4. Pre-commit will run automatically. If it blocks:
   - Read the failure output
   - Fix the issue (do NOT bypass with `--no-verify`)
   - Re-stage and retry
5. `git commit` succeeds → `git push`.
6. Tag if this is a release: `git tag v0.X.Y && git push --tags`.

## After push

1. Update `AGENTS.md`:
   - `## Current Phase` → `ITERATE` (ready for next feature)
   - `## Last Action` → reference the commit subject + Railway deploy
2. Confirm CI passes on the push (`gh run watch`).

## If pre-commit blocks on something legitimate

If gitleaks flags a false positive, add a `.gitleaks.toml` allow rule
with a comment explaining why. Don't add the secret pattern to
`--allow-pattern` flags inline.

## Forbidden

- `git commit --no-verify`
- `git push --force` to main (history is sacred on the only branch)
- Committing without prod smoke passing
