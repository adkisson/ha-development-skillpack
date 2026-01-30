# Architecture Principles (Expanded)

## 0) System Impact Classification
See: `/guides/system_impact_class.md`

- Before any architectural decisions are made, classify the system by **worst-credible impact if it fails** (Class A–D).
- System Impact Classification determines required rigor, defensive programming posture, and acceptable tradeoffs for all subsequent design decisions.

## 1) Simplicity (KISS)
- For complex problems, present **3–10** plausible designs; choose the simplest robust path.
- Eliminate unnecessary triggers/helpers/branches; resist premature abstraction.

## 2) Separation of Concerns & Authority Scoping (Brains vs Muscles)
- Separate *decision-making* from *actuation* to limit control radius and manage risk.
- **Template sensors (“brains”)** compute directives, intent, and `reason`; treated as non-authoritative outputs.
- **Automations and scripts (“muscles”)** react deterministically and idempotently; all physical device control is centralized and auditable.
- Scope authority deliberately based on System Impact Class:
  - Prefer **read, display, notify, or suggest** behaviors over direct actuation.
  - Escalate to **direct control** only when **read, display, notify, or suggest** approaches cannot meet safety, reliability, or correctness requirements.

## 3) Intent-First Paths
- **Lighting ON-path**: speed priority; minimal gates; central script applies targets fast.
- **ADJUST-path**: overhead optimized; idempotent guards; batch & rate‑limit.
- **OFF-path**: validation priority; respect presence/overrides; graceful transitions.
- **Control flow safety**: Always wrap choose/default blocks with if/then when logic branches exist. Prevents default branch execution in auto-discovery or multi-trigger scenarios.

## 4) Restart Resilience
- Gate on `timer.ha_startup_delay → idle`. Use trigger‑level `for:`:
  - Critical: **<10s fixed**
  - Non‑critical: **45–75s randomized**
- Prefer timers over long `for:` to persist across reboots.

## 5) Determinism & Cost
- Cheap checks first; heavy Jinja last; precompute commonly used values.
- Avoid repeated `states()` calls; cache into vars.

## 6) Idempotency & Chatter
- Guard device calls versus current state; use groups/areas; `repeat: for_each:`.
- Minimal bounded retry; avoid chatty loops.

## 7) Observability
- Templates expose `state` and human `reason` (only when complex logic exists); keep `#debug_*` attrs commented for quick enabling.
- Production logging is rare and meaningful; otherwise silent.

## 8) Backward Compatibility
- Proactively address **breaking changes** or **deprecated** attributes, entities, etc. for the last **12 months** on refactors/enhancements.

## 9) Ownership & Collaboration
- Healthy debate welcome; **owner’s call is final** and the skill defers.
