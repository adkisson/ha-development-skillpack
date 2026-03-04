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
- **Automations and scripts ("muscles")** react deterministically and idempotently; all physical device control is centralized and auditable.
- Scope authority deliberately based on System Impact Class:
  - Prefer **read, display, notify, or suggest** behaviors over direct actuation.
  - Escalate to **direct control** only when **read, display, notify, or suggest** approaches cannot meet safety, reliability, or correctness requirements.
- **Decision ladder — apply in order, stop at the first tier that solves the problem:**
  - **Tier 1 — Native construct**: Can a built-in trigger, condition, or action cover this? Native constructs validate at load time and fail loudly; templates fail silently at runtime. Common substitutions: `{{ states('x') | float > 25 }}` → `numeric_state` condition with `above: 25`; `{{ is_state('x', 'on') and is_state('y', 'on') }}` → `condition: and` with state conditions; `{{ now().hour >= 9 }}` → `condition: time` with `after: "09:00:00"`.
  - **Tier 2 — Built-in helper**: Can a helper replace a template sensor? Helpers are declarative, handle unavailable states gracefully, and require no Jinja. Common substitutions: sum/average → `min_max`; binary any-on/all-on → `group`; rate of change → `derivative`; cross-threshold → `threshold` (includes built-in hysteresis); consumption tracking → `utility_meter`.
  - **Tier 3 — Template sensor ("brains")**: Only if tiers 1 and 2 cannot solve it. Computes directives, intent, and `reason`; treated as non-authoritative output.

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
- Refactors or enhancements MUST review Home Assistant release notes and proactively address **backward-incompatible changes** and **deprecations** from the last **12 months** affecting entities, services, attributes, templates, schemas, or any other Home Assistant artifact **modified by the change**.

## 9) Ownership & Collaboration
- Healthy debate welcome; **owner’s call is final** and the skill defers.
