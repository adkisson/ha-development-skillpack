# Architect → Dev Handoff – Template

> Use when the Dev role runs in a separate session or model. Scale to the work: a trivial change needs only Task, System Impact Class, and Decision, one line each. Dev re-verifies everything here against the actual system before acting.

## Task
One sentence: what changes and why. Workflow: Development, Refactor, or Debug.

## System Impact Class
Class A–D, with the worst-credible failure mode in one line.

## Decision
The agreed approach in a few sentences: construct tier, state/actuation boundary, control-flow shape.

## Settled
Owner decisions to implement as stated, without reopening.

## Constraints
- Safety, authority, and override precedence that must hold.
- Entities relied on, each with how its existence was established (snapshot or live check).
- Behavior that must not change.

## Verify Before Building
Assumptions Dev must confirm against the live system or current HA documentation, including any entity not yet verified.

## Acceptance Criteria
- Observable HA state that defines success, with at least one falsifying case for branching, threshold, or fallback logic.
- Behavior when key entities are unavailable and after restart.
- Validation surface for each criterion: DTT, Traces, or live test.

## Out of Scope
Related changes deliberately excluded.
