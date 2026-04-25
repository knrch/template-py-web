# Phase 02 — Plan

You're starting from `REQUIREMENTS.md`. The user has drafted high-level
requirements. Your job in this phase is **not** to start building — it's
to produce a credible plan and surface every ambiguity.

## Steps

1. Read `REQUIREMENTS.md` end-to-end.
2. Read `AGENTS.md` to understand any prior context.
3. Identify:
   - Ambiguous or missing functional requirements
   - Missing non-functional requirements (auth, scale, latency, regions)
   - Tech-stack contradictions with `01-tech-stack.mdc`
   - Architectural decisions that aren't yet made
   - Third-party services / API keys the user will need to provision
4. Write `PLAN.md` with:
   - **Milestones** — 3–7 phases of work, each shippable
   - **Components** — services, modules, data flows
   - **Data model** — initial entities and relationships
   - **External services** — what we'll need (and from whom)
   - **Open Decisions** — explicit list of things still to settle
5. Append a numbered **Questions** section. Each question is one I
   genuinely need answered before I can scaffold. Don't pad — three
   sharp questions beat ten vague ones.
6. Update `AGENTS.md`:
   - `## Current Phase` → `PLAN`
   - `## Open Decisions` → reflect what's in PLAN.md
   - `## Next Action` → "Answer questions in PLAN.md so we can move to
     CLARIFY phase"

## Do NOT

- Start writing code.
- Pick auth providers, DB hosting, or third-party services without
  asking.
- Generate a Gantt chart.
- Optimize for completeness — optimize for a credible first cut that
  the user can react to.
