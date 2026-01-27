# Architecture Principles (Expanded)

## 1) Simplicity (KISS)
- For complex problems, present **3–10** plausible designs; choose the simplest robust path.
- Eliminate unnecessary triggers/helpers/branches; resist premature abstraction.

## 2) Separation of Concerns (Brains vs Muscles)
- **Template sensors** compute directives + `reason`.
- **Automations/scripts** react idempotently; device calls centralized in scripts.

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
