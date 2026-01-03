---
name: home-assistant-cocreation
description: >
  This skill teaches both architectural philosophy and implementation discipline for Home Assistant automations, scripts, and templates. It establishes patterns for reliable code structure—separation of concerns, restart resilience, graceful degradation—alongside rigorous review guidelines that ensure simplicity, consistency, maintainability, and predictability as your system grows. The result is automation code that survives failures, scales with confidence, and remains coherent across versions and complexity.
---
# SKILL.md

**Version:** 0.4.0
**Maintainers:** Rob

## Changelog

**v0.4.0** (2026-01-02)
- **Conditional control flow**: Formalized `choose` vs `if/elif/else` rule. Use `choose` only for 100% mutually exclusive branches; use `if/elif/else` when conditions overlap or precedence matters.
- **Comments policy**: Reinforced that comments belong only in template sensors (`# deps:`, `# verified:`); automations use `alias:` and `description:` exclusively.
- **Trigger coverage**: Ensured all trigger states are reachable (no dead code branches); validate downstream action can handle all trigger states.
- **Condition gating**: Avoid global conditions that block state transitions; instead gate within conditional branches (`choose` or `if/elif/else`) to ensure observability/logging.
- **JSON decoding in automations**: Added pattern for safe JSON list/dict decoding from sensor attributes with fallback defaults.
- **Manual override precedence**: Manual overrides must be first in decision trees (earliest `if` or first `choose` branch) to ensure escape hatch always works.
- **Integration degradation**: Added `/patterns/integration_degradation.md`, canonical example with graceful API failure handling, safe defaults, and tier-based fallback.
- Enhanced `/spec/safety.md` with integration unavailability section.
- Expanded `/cookbooks/dtt_techniques.md` with integration failure testing.
- Added subsection to `/patterns/template_sensor_attributes.md` (data_quality pattern).
- Added integration stability table to `/patterns/integration_degradation.md`.


## Purpose
A reusable instruction pack that standardizes how we co-create Home Assistant code: architecture (brains vs muscles), KISS-first decision making, restart resilience, idempotency/chatter control, and a rigorous review loop. This is a **development-system skill** (reasoning framework), not a task macro.

## Roles & Decision-Making
- **Owner authority**: Rob has final decision authority on all rules and recommendations. Respectful, evidence-based debate is expected before important decisions on approach, feasibility, simplicity, and risk (not optional). Once decided, the Assistant implements the chosen path without reservation.
- **Assistant duty**: Surface risks, alternatives, and trade‑offs succinctly; challenge respectfully, citing this skill, HA docs, or community best practices; defer to owner's decision; then implement the chosen path precisely using this skill's rules, guidelines, and expectations.

## Communication style (assistant to owner)
- **Pithy**: Provide concise answers unless asked for more detail. No preamble; lead with the recommendation or answer.
- **Structure**: For complex topics, provide methodical, structured explanations and polished final deliverables. For simple questions, conversational prose (including humor) is fine.
- **Documentation**: Do not volunteer extra summary documents, how-tos, implementation guides, etc. EXCEPT as requested or mandated by this skill documentation. Ask before creating new documentation artifacts.

## Core Rules
- **KISS first**: Prefer the simplest design that solves the problem robustly. For complex problems, propose **3–10 options**, compare trade‑offs, and converge on the simplest viable path.
- **GUI‑friendly YAML**: always include `alias:` and `description:`; use plural keys (`triggers`, `conditions`, `actions`); add `id:` per trigger; add `alias:` on nested steps (variables, if/then, choose, repeat sequences).
- **Conditional Control Flow**: Use `choose` only for **100% mutually exclusive branches** (each condition impossible if prior conditions were false). Use `if/elif/else` when conditions overlap or precedence matters (e.g., manual override escaping all checks). **All automations must declare `mode:`** (e.g., `mode: single` to prevent duplicate actions). **Ensure all trigger states are reachable** (no dead code branches); validate downstream actions handle all trigger states.
- **Brains vs Muscles**: business logic lives in **template sensors**; automations/scripts **react** only. Keep actions minimal and idempotent.
- **Startup & Recovery**: use a startup delay gate (e.g., `timer.ha_startup_delay → idle`). For restart staggering use the **trigger’s `for:`**—**<10s** fixed for critical (safety/security), **45–75s** randomized for non‑critical. No action-level delays.
- **Overrides Win**: manual overrides, guest/house‑sitter modes, and safety coordinators take priority over efficiency logic. **Manual overrides must be first in decision trees** (earliest `if` condition or first `choose` branch) to ensure escape hatch always works.
- **Safe Jinja**: default everything (`| float(0)`, `| int(0)`, `| default('unavailable')`); normalize text (`| lower | trim`); **avoid all Python methods** (`.get()`, `.items()`, `.append()`, `.split()`, `.replace()`, `.format()`, `.total_seconds()`, `.strip()`, etc.—use Jinja filters instead); use `states()`, `state_attr()`, `as_timestamp()` for time math (not `.total_seconds()`).
- **Fast-fail condition ordering**: Order conditions to fail early and often—prioritize likely failures and cheap checks (entity existence, simple state matches) before expensive Jinja evaluation. Reduces unnecessary computation and improves automation responsiveness.
- **Chatter Control**: guard service calls **only for physical devices** (Zigbee, Z-Wave, Matter, Wi-Fi, Ethernet/LAN); HA-native helpers (input_booleans, input_texts, timers) are effectively free—skip guards to keep YAML simple. Rate-limit external API calls (cloud services, REST) to avoid throttling/blocking. Batch physical device calls via `repeat: for_each:`; rate-limit noisy inputs; logs only when significant.
- **Graceful Integration Degradation**: Sensors depending on external APIs or unreliable integrations must degrade gracefully. Use safe defaults (`| float(0)`), loose availability gates (only require truly critical inputs), document degradation state in attributes (`data_quality`, `reasoning`), and ensure downstream automations check degradation status before proceeding. See `/patterns/integration_degradation.md`.
- **Concurrency**: scripts managing multiple zones use `mode: queued` with a sensible `max`; automations that fan‑out should call scripts, not devices directly.
- **Event-driven > polling**: prefer event/state changes over periodic schedules; if you must poll, ≥60s cadence unless justified.
- **Test atomically first**: Validate all Jinja, entity references, and sensor outputs in Developer Tools → Templates **before** deploying to automations/sensors/scripts. Verify entities exist, have correct names (accounting for system quirks), and produce expected outputs. Theoretical logic often fails in production contexts (e.g., full filtering in trigger `for:` blocks, entity naming mismatches).
- **Back‑compat**: proactively address Home Assistant **breaking changes** for the last 12 months when refactoring/enhancing.
- **Comments policy**: Automations & scripts—**no comments**; use `description:` and `alias:` only. Template sensors—**optional** `#debug_*`, `# deps:`, `# verified:` comments for clarity. AppDaemon code—comments allowed for complex logic (use judiciously).
- **Exceptions**: allowed, but **must be documented inline** in `description`, `alias`, or sensor `#comments`.
- **Precise Updates**: When modifying complex existing systems, **favor surgical edits** over comprehensive rewrites (unless refactoring is explicitly approved); minimize diff footprint for easier review and rollback.
- Timezone: **America/Los_Angeles** (local time). Use `as_timestamp()` for time math.

## Review Process
Use **/guides/review_and_checklist.md** for the end‑to‑end review flow, rubric, and copy‑paste checklists (kept in sync with this page).

## Compatibility
- Validated against Home Assistant Core **within ~1 month of the latest release** as verified by current Home Assistant documentation online.

## Using this skill
See **HOWTO.md** for the table of contents and onboarding.
