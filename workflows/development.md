# Development

## Objective

Implement an agreed design to Skill-Pack standard and prove it works before
calling it done.

## Invariants

- Rigor is proportional to impact class and novelty. Routine, low-class,
  structurally trivial work gets lightweight handling — but the quality bar
  itself (correctness, applicable behavioral validation, entity references,
  safety/override behavior) never waives, regardless of how light the
  process is.
- For Jinja-bearing or template/state-evaluation logic specifically, DTT
  validation is non-negotiable wherever DTT can exercise that logic — see
  `guides/dtt_first_validation.md`. DTT proves templating and state
  evaluation; it doesn't prove orchestration or actuation, so it doesn't
  stand in for validating those.
- Existing incorrect behavior with an unknown cause routes to **Debug**, not
  here. A known, already-demonstrated defect (e.g. "this entity was
  renamed, update the reference") may proceed directly to the appropriate
  corrective workflow — Development for a straightforward fix, Refactor if
  the correction is structural — without a Debug detour it doesn't need.
- Clarify intent in observable HA-state terms before building: what state
  change defines success, what happens when key entities are unavailable,
  what happens at startup before helpers are restored, and who else is
  affected.
- Overrides/safety precedence from the Architecture decision is preserved,
  not reopened here.
- Fast-fail condition ordering: cheap checks and likely rejections before
  expensive Jinja.
- Restart/staggering windows — `patterns/restart_resilience.md`.
  Idempotency/chatter control — `patterns/action_hygiene.md`. YAML/Jinja
  standards — `spec/yaml_style.md`, `snippets/jinja_patterns.md`.
- Backward-Incompatible review is required where applicable per
  `spec/runtime.md` — confirm `BC review: done` or `BC review: N/A`.
- HAF/UX is a build-time question, not only a final check: does the
  implementation behave the way a person would naturally expect? Build to
  the HAF/UX assumptions established in Ideation/Architecture as the
  implementation takes shape, not only at the end.

## Completion

- DTT-first validation complete per `guides/dtt_first_validation.md` — no
  Jinja-bearing logic deployed without it.
- Entity references confirmed (usable-state or defined-entity checks, as
  appropriate).
- Production-readiness confirmed against `guides/review_and_checklist.md` —
  that file is the detailed checklist/grading reference; this workflow
  states the outcome, not the mechanism names.
- HAF/UX reviewed wherever behavior is perceptible to or controlled by a
  person — not narrowed to shared spaces or schedules. A bedroom
  automation, a personal notification, a lock, or a manual-switch
  interaction all qualify.

## Transitions

- → **Debug** if implementation reveals the design doesn't hold up against
  real state and the cause isn't yet known.
- → **Architecture** if structure turns out to still be unresolved
  mid-build.

## Applicable References

Load only what the specific task actually needs:

- `guides/construct_selection.md` — construct choice is still material.
- `spec/yaml_style.md` — authoring or modifying YAML.
- `snippets/jinja_patterns.md` — Jinja is involved.
- `guides/dtt_first_validation.md` — template/state logic needs validation
  before deployment.
- `guides/review_and_checklist.md` — confirming production-readiness.
- Relevant `patterns/*` — only the specific pattern implicated (restart,
  chatter, cloud actuation, etc.), not the whole directory.
- `cookbooks/dtt_techniques.md` — while running a DTT validation session.
- `guides/artifact_authority.md` — samples or scaffolds are being
  consulted.
