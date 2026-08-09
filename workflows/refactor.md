# Refactor

## Objective

Improve structure or implementation while preserving established behavior —
or delivering an explicitly-approved behavior change. Never opportunistic
redesign riding along on an unrelated change.

## Invariants

- Surgical diff over rewrite: minimum footprint unless a rewrite is
  explicitly approved.
- State the behavior contract before editing — what must still be true
  after the change — so preservation can actually be checked, not assumed.
- No bundled unrelated cleanup. A refactor scoped to one thing stays scoped
  to that thing.
- The behavior contract includes the human interaction model, not just
  technical state transitions: a cleaner implementation that changes how
  the behavior feels to use is a behavior change, and needs the same
  explicit approval as any other.

## Completion

- Preserved behavior verified, or the approved behavior change is delivered
  and documented.
- Validated against whatever surface the change actually touched: DTT for
  affected template/state logic, Traces for orchestration, a live test for
  device actuation — not DTT by default for every change.
- Regression risk addressed in proportion to the artifact's System Impact
  Class (`guides/system_impact_class.md`) — Class A/B changes get the same
  rigor as new work, not a lighter pass because it's "just a refactor."

## Transitions

- → **Debug** if the refactor surfaces behavior that was already wrong —
  root-cause that first; don't fold a bug fix into the refactor's diff.
- → **Architecture** only when the refactor requires a *new, unresolved*
  architectural decision (e.g. the construct tier or the state/actuation
  boundary itself is now in question). Restructuring or cleaning up the
  existing design is what Refactor is for and doesn't by itself require
  leaving the workflow.

## Applicable References

- `guides/review_and_checklist.md` — confirming production-readiness.
- `guides/dtt_first_validation.md` — template/state logic was touched.
- `guides/system_impact_class.md` — establishing or confirming
  regression-risk proportionality.
- Relevant `patterns/*` — only the specific pattern implicated.
- `guides/artifact_authority.md` — samples or scaffolds inform the change.
