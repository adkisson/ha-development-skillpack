# Review & Checklist — How‑To + Rubric (Single Source of Truth)

This is the completion-gate checklist for `workflows/development.md` and
`workflows/refactor.md` — not a standalone review task. Structure decisions
belong to `workflows/architecture.md`; root-cause work belongs to
`workflows/debug.md`. DTT validation is mandatory before deployment
approval, but design or patch reviews may occur before DTT when the
artifact is not yet ready to run.

## Review Process Summary

**Before starting**: surgical edits over rewrites — minimum diff footprint; rewrites require explicit approval.

| Step | Gate | Hard gate? |
|------|------|------------|
| 0 | **Security** — scan for secrets/identifying material | ✅ Yes |
| — | **Pre-deployment validation triage** — scan for risk triggers requiring specific validation before deployment approval | |
| 1 | **Impact classification** — Class A–D; determines rigor for all steps below | ✅ Yes for A/B without risk assessment |
| 2 | **KISS** — simplest viable solution; alternatives considered only where there's genuine ambiguity or a meaningful tradeoff | |
| 3 | **Syntax & structure** — GUI-friendly YAML, plural keys, alias/note/description placement, comments policy | |
| 4 | **DTT validation** — all Jinja and entity references proven before **deployment approval** | ✅ Yes for deployment |
| 5 | **Traces** — orchestration/timing verified via Automation Traces where needed | |
| 6 | **Live test** — happy-path trigger exercised | |
| 7 | **Intent alignment** — implementation matches stated intent; conditions ordered correctly; network traffic minimized | |
| 8 | **Wait/timeout** — `wait_template` preferred; exclusion lists guard empty string | |
| 9 | **Restart & recovery** — correct `for:` windows; no action delays for staggering | |
| 10 | **Idempotency & chatter** — device call guards; batching; rate-limiting | |
| 11 | **Overrides & safety** — applicable manual/guest/safety precedence confirmed | |
| 12 | **Backward-Incompatible review** — last 12 months of breaking changes reviewed; confirm `BC review: done` or `BC review: N/A` | ✅ Yes if applicable and unconfirmed |
| 13 | **Changelog** — entry added in correct format and location | |
| 14 | **Exceptions** — any deviations documented inline | |
| 15 | **Blueprint validation** — if applicable | |
| 16 | **HAF/UX** — reviewed wherever behavior is perceptible to, relied upon by, or controlled by a person; annoyance risk mitigated | ✅ Yes if unmitigated/undocumented |
| 17 | **Self-critique & score** — weighted score + hard gates determine production-readiness; verdict assigned | |

**Production-ready threshold**: all applicable hard gates pass, **and** weighted score is **≥90%** (see Production Readiness below). Anything below requires fixes or explicit deferral with documented rationale.

Use section **A)** for the full flow, **A1)** for hard gates, **C)** for copy-paste checklists.

## Blocking Gate — Secret & Identifying Material
- Compliant with `spec/security.md` (no secret or identifying material present).

If detected:
- Mark as ❌
- Stop review
- Do not continue architectural analysis

## Pre-Deployment Validation Triage

Before deployment approval, scan for risk triggers that require specific validation:

- **Touches physical devices?** Confirm idempotency, chatter control, and manual override behavior.
- **Runs on startup or HA restart?** Confirm startup gate, restart staggering, and unavailable-entity behavior.
- **Uses high-frequency triggers or noisy sensors?** Confirm debounce, rate limit, and oscillation control.
- **Uses Jinja?** Confirm DTT validation and safe unavailable-state handling.
- **Uses time/deadline logic?** Confirm timezone handling, restart resilience, and timer vs `input_datetime` selection.
- **Calls cloud/API/integration services?** Confirm availability handling, bounded retry, cooldowns, and no reload/command storms.
- **Is any part of the behavior perceptible to, relied upon by, or controlled by a person?** Confirm HAF/UX review — this is not limited to shared spaces or schedules; a private-room automation, a personal notification, a lock, or a manual-switch interaction all qualify.
- **Refactors existing behavior?** Confirm surgical diff, preserved intent, and rollback path.

## A) Review Flow (Detailed)

0) **Security**
   - Hard stop if secrets or identifying material are present. See `spec/security.md`.

1) **System Impact Classification**
   - Classify by worst-credible failure impact using `/guides/system_impact_class.md`.
   - Record class, worst-credible failure mode, and any Context Elevation reasoning. Class A/B without completed risk assessment is a hard gate.

2) **KISS Gate**
   - Choose the simplest robust path. Consider alternatives only when there's genuine design ambiguity or a meaningful tradeoff — present the alternatives that materially differ in behavior, complexity, resilience, maintainability, safety, or HAF/UX. Don't manufacture options to satisfy a quota: one clearly-dominant recommendation with brief rationale is sufficient for trivial or obvious cases.
   - Reject speculative complexity not required by the stated intent. See `/workflows/architecture.md`.

3) **Syntax & Structure**
   - Use current release -1 YAML/Jinja standards; reject deprecated or "also works" syntax.
   - GUI-friendly YAML, plural keys, alias/note/description placement, comments policy, trigger rules, and changelog rules per `spec/yaml_style.md`.

4) **DTT Probes — Mandatory Before Deployment Approval**
   - Validate Jinja logic and entity references before deployment approval. Entity references must be mechanically validated — not inferred, not handed back to the user for manual one-by-one checking. See `/guides/dtt_first_validation.md`.
   - If DTT passes but deployed behavior fails, switch to `/workflows/debug.md`.

5) **Traces vs DTT**
   - DTT proves template/state logic; it does not prove orchestration or actuation. Automation Traces verify orchestration/timing; live tests verify actuation. Use the surface that actually proves the behavior in question, not DTT by default.

6) **Live Test**
   - Exercise a happy-path trigger when feasible. Observe Logbook only for significant events.

7) **Best-in-Class Review (Intent Alignment)**
   - For all code, ask:
     1. **Primary intent?** (Lights ON = speed; Lights OFF = validation; Recovery = network efficiency; Notification = reliability)
     2. **Implementation matches intent?** (Minimize checks for ON; rich validation for OFF; sequential+guarded for recovery)
     3. **Conditions in right place?** (Cheap checks first in conditions block; expensive operations only on needed paths)
     4. **Network traffic minimized?** (Z-Wave/Zigbee sequential+delayed; HA helpers redundant-call-safe; light transitions batched)

8) **Wait Conditions & Timeouts**
   - Prefer `wait_template` with timeout and `continue_on_timeout: true` where feasible.
   - Guard exclusion lists for empty string `''` (e.g., `not in ['dead','unknown','unavailable','']`).

9) **Restart & Recovery**
   - Apply `/patterns/restart_resilience.md`. Restart staggering uses trigger-level `for:` only — no action delays.

10) **Idempotency & Chatter**
    - Guard device calls; batch by group/area; rate-limit noisy inputs; minimal bounded retry.

11) **Overrides & Safety**
    - Manual/guest/safety modes always win where applicable. See `/spec/safety.md`.

12) **Backward-Incompatible Changes**
    - Review last 12 months of HA breaking changes when applicable. Response must confirm `BC review: done` or `BC review: N/A`.

13) **Changelog & Versioning**
    - Add changelog entry per `spec/yaml_style.md`.

14) **Exceptions**
    - Deviations allowed only when documented inline in the artifact.

15) **Blueprint Validation (if used)**
    - Confirm compliance with the official Home Assistant blueprint schema and validate at least one instantiated artifact against all standard automation/script expectations before approval.

16) **HAF/UX Review**
    - HAF/UX applies wherever behavior is perceptible to, relied upon by, or controlled by a person — lighting (including private rooms), HVAC, locks/access/security, manual switches, notifications, media, presence-driven behavior, appliances, and anything with override or recovery behavior. It is not limited to shared spaces or schedules.
    - This step is the **final verification**, not the first consideration — HAF/UX should already have shaped the design in Ideation, Architecture, and Development. Confirm the completed behavior still satisfies the HAF/UX assumptions that shaped it, and that no new human-impact failure mode was introduced. High-impact risks must be mitigated, documented as accepted tradeoffs, or the change must not ship.

17) **Self-Critique & Verdict**
    - Confirm no TODOs/placeholders, contradictions, scope expansion, unresolved ambiguity, or intent mismatch.
    - Score production readiness per **Production Readiness** below; document risks, alternatives, rollback, the score breakdown, and verdict.

### Optional Safety-Level Summary
When useful, summarize the highest safety level demonstrated:

- **L0 — Syntax Safe:** YAML/Jinja parses and schema shape is valid.
- **L1 — Type Safe:** HA state types, casts, fallbacks, and unavailable values are handled.
- **L2 — Behavior Safe:** DTT validation covers normal, unavailable, startup, and boundary states.
- **L3 — Steward Safe:** edits are surgical; entity IDs, aliases, comments, scope, and user intent are preserved.
- **L4 — Operator Safe:** live validation surfaces such as config check, traces, logs, or Developer Tools confirm behavior.

This summary does not replace the Skill Pack checklist, verdict, or score.

---

## A1) Hard Gates — Do Not Approve If Any Are True

Any one of these blocks production-ready status **regardless of weighted score**.

- [ ] **Security/safety defect** — secrets or identifying material present (`spec/security.md`); or a known safety defect (e.g. missing min-run/min-off on a critical actuator, missing override precedence) per `spec/safety.md`.
- [ ] **Unverified entity reference** — any entity reference not mechanically validated (defined-entity check where existence matters; `has_value()` where usable state matters) per `guides/dtt_first_validation.md` — not inferred, not handed back to the user for manual one-by-one checking.
- [ ] **Required behavioral validation incomplete or failed** — DTT not run where it can exercise the logic; orchestration/timing not confirmed via Traces or a live test where those are the relevant surface; restart and unavailable-entity behavior undefined.
- [ ] **Behavior materially differs from the agreed requirement** — implementation doesn't match the approved design, or success isn't expressible/confirmed in observable HA-state terms.
- [ ] **Applicable Backward-Incompatible review not completed** — `BC review: done` or `BC review: N/A` not confirmed per `spec/runtime.md`.
- [ ] **Unacceptable Class A/B failure behavior** — Class A/B artifact without a completed risk assessment, or manual override/safety-coordinator interaction not accounted for.
- [ ] **Material HAF/UX problem** — a human-perceptible or human-controlled behavior issue left unmitigated, undocumented, or unaccepted as a tradeoff.

---

## Production Readiness — Weighted Score + Hard Gates

Replaces the old letter-grade model. The score exists to force explicit
self-reflection and expose where points were lost — not to create false
precision.

**Production-ready requires both:**
- All applicable hard gates (A1, above) pass, **and**
- Weighted score is **≥90%**.

### Categories & Weights

| Category | Weight |
|---|---|
| Correctness & behavioral fidelity | 25% |
| Safety, authority & failure handling | 20% |
| Validation & evidence | 20% |
| HAF / UX | 15% |
| Simplicity & architecture | 10% |
| Maintainability & HA quality | 10% |

### Category Anchors — What a 5 Looks Like

One sentence per category so a `5` requires an actual threshold, not a
hand-wave:

- **Correctness & behavioral fidelity** — all stated behavior demonstrated; no unresolved mismatch between the agreed requirement and the implementation.
- **Safety, authority & failure handling** — override/safety precedence correct and verified; restart, unavailable, and degraded-state behavior handled with no unacceptable Class A/B exposure.
- **Validation & evidence** — all entity references mechanically verified; every relevant behavior surface (DTT, Traces, live test) tested against the surface it actually proves, including a falsifying case where branching/threshold/fallback logic is present.
- **HAF / UX** — no material human-impact concern remains unmitigated or unaccepted; completed behavior matches what a person would naturally expect.
- **Simplicity & architecture** — the simplest construct tier and structure that fully solves the problem; no complexity beyond what the requirement justifies.
- **Maintainability & HA quality** — YAML/Jinja standards, naming, comments policy, and changelog all compliant; a future session can maintain this without archaeology.

A score below 5 in a category should be traceable to which part of its
anchor wasn't met — that's what "residual weaknesses" in the Review Output
should name.

### Scoring Scale (0–5 per category)

- **5** — fully satisfied, evidence-backed
- **4** — minor non-material weakness
- **3** — meaningful compromise or weakness
- **2** — material deficiency
- **1** — seriously deficient
- **0** — absent, failed, or contradicted

**Weighted % = Σ (score ÷ 5 × category weight).** If a category is
genuinely not applicable to this artifact (e.g. no HA-perceptible behavior
exists to review for HAF/UX), remove it from both the numerator and the
denominator and re-normalize the remaining weights to sum to 100% — do not
award it free credit by leaving its weight in the total unscored.

### Review Output

State explicitly:
- The category breakdown — score and one-line rationale per category.
- The total weighted score.
- Hard-gate status — pass, or name every gate that failed.
- Residual weaknesses — what specifically cost points, even at a passing
  score.

## B) Verdicts

Verdict follows from hard-gate status and weighted score — not a separate
holistic call:

- **Production-ready** — all hard gates pass and score ≥90%.
- **Low-risk w/ notes** — all hard gates pass, score 75–89%, residual
  weaknesses documented.
- **Needs revision** — all hard gates pass but score <75%, or a hard gate
  fails on something fixable in this session.
- **Do not ship** — a hard gate fails on something not fixable in this
  session, or the score reflects a fundamental issue.

## C) Copy‑Paste Checklists
### Master
- [ ] KISS & scope confirmed; alternatives considered only where genuine ambiguity or a meaningful tradeoff existed (not manufactured to hit a quota); no complexity added beyond current requirements
- [ ] GUI-friendly automation/script YAML; `alias:` confirmed at schema-supported levels within automations/scripts; `description:` confirmed for automations/scripts; schema-supported naming/documentation confirmed for YAML-defined entities; `id:` per automation trigger; `alias:` confirmed absent from template sensors, input helpers, arbitrary variable mappings, and other YAML-defined entities.
- [ ] `max_exceeded: silent` evaluated for automations that fire frequently or have significant risk of exceeding `max`
- [ ] **Comments policy**: automations/scripts confirmed comment-free — GUI strips comments silently; artifact-level context in `description:`; concise trace identity in nested `alias:`; non-obvious step-level rationale in nested `note:` where schema-supported. Template sensors confirmed with `# CHANGELOG:` and commented `#debug_*` attributes. AppDaemon comments for complex logic only.
- [ ] **Startup triggers** confirmed only where post-restart actions needed (state recovery, initialization); not present for passive automations
- [ ] Any required state/actuation boundary is clear and appropriate to the design — no template-sensor "brain" forced onto work a simple native automation already expresses clearly and safely; scripts used for fan‑outs; concurrency verified sane
- [ ] **Construct selection confirmed:** purpose-specific native construct preferred where it directly expresses intent and preserves the correct targeting/authority semantics, falling back to a generic native construct, then a template-based one, only as each preceding option fails to fit — see `guides/construct_selection.md`; `choose` used only for provably mutually exclusive branches (discriminated by trigger ID, entity state, or other HA-native discriminator); if/then/else used for prioritized execution where conditions may overlap; no elif in YAML
- [ ] **Execution gating confirmed:** automations gate on positive evidence — no action executes unless all required conditions are provably met; default to no action on uncertainty
- [ ] Restart gates confirmed on triggers (`timer.ha_startup_delay` w/ appropriate `for:`); no action delays present
- [ ] State trigger `to:`/`from:` and event trigger `event_type:` confirmed as **literal string matches only** — never Jinja; `for:` confirmed accepts Jinja where used; `trigger: template` + `value_template:` used for evaluated expressions
- [ ] Jinja safety confirmed: safe defaults present (`| float(0)`, `| int(0)`)
- [ ] Python method use reviewed: no methods on HA-returned or JSON-derived objects; `.get()` / `.items()` allowed only on known literal dicts per `snippets/jinja_patterns.md`; `.total_seconds()` avoided except for guarded `.last_changed` / `.last_updated` staleness/age semantics
- [ ] No direct state-object access confirmed except `.last_updated` / `.last_changed` for staleness/age; guarded and used only for time semantics
- [ ] String normalization confirmed: `| lower | trim`
- [ ] Time math confirmed: `as_timestamp()` preferred for timestamp math; `.total_seconds()` used only for guarded `.last_changed` / `.last_updated` staleness/age semantics where explicitly allowed
- [ ] Deferred-intent datetime helpers confirmed canonical pattern (full datetime, sentinel `2999-01-01 00:00:00`, no null/blank, literal sentinel comparison)
  - Does NOT apply to non-deferred timestamps (e.g., chatter-control like "last applied", "last run")
- [ ] Type safety confirmed: raw/typed variables separated; comparisons use typed with tolerance
- [ ] Availability/existence confirmed: defined-entity validation used where existence matters; `has_value()` used where usable state matters; blank-string guard added for sources known to emit blanks (1)
- [ ] Event-driven confirmed preferred; polling ≥60s and justified where used
- [ ] Fast-fail condition ordering confirmed: cheap checks first; likely failures early; expensive Jinja last
- [ ] Chatter confirmed minimized; idempotent guards present; groups/areas used; rate‑limit applied as needed
- [ ] Observability confirmed: `reason` attr present where external or ambiguous inputs exist; production logs only for significant events
- [ ] DTT validation completed per `/guides/dtt_first_validation.md`; entity pre-flight confirmed; traces referenced if orchestration validated
- [ ] Best-in-class review completed: intent clarity, implementation alignment, condition placement, network efficiency confirmed
- [ ] Wait strategies confirmed: `wait_template` used where applicable; exclusion lists guard empty string; `continue_on_timeout: true` present
- [ ] Backward-incompatible changes (12 months) reviewed and confirmed
- [ ] Exceptions documented inline using the artifact's supported documentation channel (`description:`/`alias:`/`note:` for automations/scripts where schema-supported; comments for YAML-defined entities)
- [ ] Risks/alternatives/rollback documented; weighted score breakdown and hard-gate status recorded; verdict chosen
- [ ] HAF/UX reviewed for any behavior perceptible to, relied upon by, or controlled by a person (see sub-checklist) — confirmed as final verification of assumptions already made earlier in the workflow, not first consideration

### Automation Sub‑Checklist
- [ ] Minimal, precise triggers; unique `id` and `alias`
  - Note: trigger id uniqueness is required when triggers route to different evaluation paths. Multiple triggers may share an id when they intentionally collapse to a single identical evaluation sequence.
- [ ] Randomized vs fixed `for:` per criticality on HA restart
- [ ] Variables computed once at the narrowest appropriate scope; branches small & ordered cheap→expensive
- [ ] Deferred-intent datetime helpers (deadline-style `input_datetime`) declare owner and overdue policy in `description:` and implement explicit consume behavior (clear or re-arm)
- [ ] No device calls inside loops without guards
- [ ] No recursive loop: if trigger entity == action target entity, a `to:` constraint and re-entry condition are mandatory
- [ ] Logging absent unless documenting significant failure or diagnostic paths; description/alias carry normal intent
- [ ] Trigger coverage: each trigger ID or intentionally collapsed trigger group is handled by exactly one evaluation path; catch-all branches log `trigger.id` only for significant diagnostic validation
- [ ] Empty `metadata: {}`/`data: {}` blocks: acceptable if GUI-edited (editor auto-adds); remove only in pure-YAML workflows
- [ ] Automation/script CHANGELOG formatting correct:
  - newest entry first
  - two blank lines before **CHANGELOG:**
  - `**CHANGELOG:**` (bold + caps)
  - one blank line after header
  - one blank line between each entry
- [ ] `description:` prose paragraphs are single unbroken lines — no internal wrapping; line breaks only between paragraphs and within CHANGELOG block

### Script Sub‑Checklist
- [ ] `mode` and `max` reflect expected concurrency
- [ ] Centralizes device calls; idempotent guard; optional bounded retry
- [ ] No logging except significant failure paths
- [ ] No comments; description/alias carry context

### Template Sensor Sub‑Checklist
- [ ] Minimal trigger set + HA startup gate
- [ ] Clear directive state + `reason` attribute — where the sensor is used as a directive/decision surface for downstream automations; not required for a plain display/utility sensor with no downstream decision logic
- [ ] Safe reads; expected commented `#debug_*` attributes present
- [ ] Accumulating dict-merge sensors: byte-length pre-check before commit (`proposed | tojson | length > 16384`)

### Time Math & Timezone Safety Sub-Checklist
- [ ] Conversions explicit and consistent (`as_timestamp()` for math; `as_datetime()` only for parsing/display)
- [ ] Local vs UTC intentional (`now()` vs `utcnow()`); no mixing within a calculation
- [ ] Staleness/age math safe for `none`/invalid datetimes (guard + safe default like `999999`)
- [ ] Time-of-day logic uses numeric comparisons (hour/minutes), not `"HH:MM"` string comparisons
- [ ] Randomized delays/schedules correct and deterministic for intent (inclusive ranges; `range(45, 76)` for "45–75")
- [ ] Once-per-day schedules account for DST (anchored `at:` vs elapsed-time logic)
- [ ] Datetime comparisons avoid Python methods; use timestamp filters for day-level logic (e.g., no `.date()`)
- [ ] Datetime parsing uses safe fallback (`as_datetime(value, default)`)

### Datetime vs Timer Selection
- [ ] `input_datetime` used for persisted deferred intent (restart-safe deadlines, gating)
- [ ] `timer` used only for:
  - countdown UX
  - cancelable grace windows
  - protective cooldowns (e.g., compressor or API lockout)
- [ ] Timer usage includes explicit justification if not obvious

### Deterministic Execution
- [ ] No templated randomization in critical paths (or documented as accepted tradeoff)
- [ ] Post-restart gates use <10s fixed for: for critical paths (safety/security); 45–75s random for: for non-critical (prevents thundering herd)

### HAF/UX Sub‑Checklist *(Household Acceptance Factor)*
**This sub-checklist is the final verification that completed behavior still
matches the HAF/UX assumptions established earlier in the workflow
(Ideation, Architecture, Development) — not the first time HAF is
considered.** Applies to any behavior perceptible to, relied upon by, or
controlled by a person — not only shared spaces or schedules.

- [ ] False-trigger probability evaluated
- [ ] Oscillation / repeated toggle risk evaluated
- [ ] Notification fatigue risk evaluated
- [ ] Sleep disruption risk evaluated (late night / early morning behavior)
- [ ] Manual override conflict evaluated ("automation fighting humans")
- [ ] Restart recovery annoyance evaluated
- [ ] Sensor chatter / flapping risk evaluated
- [ ] Guest-mode behavior considered
- [ ] Silent failure modes identified
- [ ] Trust erosion vectors identified (conditions that would cause someone to disable the automation)
- [ ] High-impact annoyance risks mitigated, documented, or explicitly accepted as tradeoffs

-----
(1) If the source is known to emit blank strings, add and (states(...)|trim) != ''.
