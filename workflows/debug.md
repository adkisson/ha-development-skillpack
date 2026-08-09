# Debug

## Objective

Find and demonstrate root cause — not implement the correction. Prefer the
simplest explanation that fully accounts for the evidence, and escalate
only when the evidence requires it.

## Invariants

- No causal claim without a demonstrated root cause. A plausible story is
  not a root cause.
- Validate against the surface the failure actually lives on — don't force
  one validation method onto a failure it can't speak to:
  - **Template/state logic** — prove it in Developer Tools → Templates
    (DTT). See `guides/dtt_first_validation.md`.
  - **Orchestration and timing** — prove it with Automation Traces and
    runtime evidence (Logbook, integration logs, restart timing).
  - A clean trace does not prove the logic behind it is correct, and a
    correct-looking template does not prove the orchestration around it is
    correct. Validate the surface the symptom is actually on.
- Known HA failure modes — restart-state timing, race conditions, recursive
  loops (`patterns/recursive_loop.md`), sensor chatter, `mode: single`
  silently dropping a run, integration degradation
  (`patterns/integration_degradation.md`), override suppression — are
  hypotheses worth considering, not a mandatory checklist to clear before
  any theory is allowed.
- One hypothesis test at a time during diagnosis (e.g. a minimal DTT probe),
  so the result is attributable to a specific cause.
- A technically correct correction can still be a bad one: once the evidence
  points to what needs to change, note whether that correction is likely to
  create new surprise or friction for the people living with the system —
  that's part of a complete diagnosis, not something to leave for whoever
  implements it to discover.

## Completion

Root cause demonstrated by evidence, not asserted — the causal mechanism is
identified and traceable to the evidence, with a stated correction. That's
Debug's exit condition per the Task Router; Debug does not stay open
through implementing and revalidating the fix — that belongs to whichever
workflow receives the handoff below.

## Transitions

State the transition explicitly before the receiving workflow's reasoning
begins — one reasoning state stays primary, so a workflow file is loaded
*after* its transition is made, not as supporting material while still
diagnosing.

- → **Development** once root cause is demonstrated and the correction is a
  straightforward implementation.
- → **Refactor** once root cause is demonstrated and the correction is
  structural but preserves existing behavior.
- → **Architecture** when the evidence itself demonstrates the defect is
  structural or design-level and genuinely unresolved — e.g. the
  state/actuation boundary has broken down, or multiple artifacts are
  producing conflicting state. This is a judgment made from evidence, not
  triggered by a fix-attempt count.

## Applicable References

- `guides/dtt_first_validation.md` / `cookbooks/dtt_techniques.md` — the
  failure surface is template/state logic.
- `cookbooks/debugging.md` — quick lookup of a specific Developer
  Tools/Trace technique.
- `patterns/recursive_loop.md` — the symptom matches a self-triggering
  loop.
- `patterns/integration_degradation.md` — the symptom matches upstream
  integration staleness or unavailability.
