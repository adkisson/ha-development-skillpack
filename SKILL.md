---
name: home-assistant-cocreation
description: >
  This skill teaches both architectural philosophy and implementation discipline for Home Assistant automations, scripts, and templates. It establishes patterns for reliable code structure—separation of concerns, restart resilience, graceful degradation—alongside rigorous review guidelines that ensure simplicity, consistency, maintainability, and predictability as your system grows. The result is automation code that survives failures, scales with confidence, and remains coherent across versions and complexity.
---
# SKILL.md

**Version:** 0.5.5
**Maintainers:** Rob

## Changelog
## 0.5.5
- Added prohibition for comments inside of jinja literals
- Added \patterns/execution_gating.md`: positive-path framing pattern for automation action gating, including compound boolean gates, multi-path scaling, and when to invert to deny-by-default (Class A–B automations).`
## 0.5.4a
- Standardized terminology to Home Assistant **“Backward-incompatible”** changes (formerly referred to as breaking changes).
## 0.5.4
- Added `snippets/jinja_patterns.md`: Entity Set Iteration section and cheat sheet bullet covering `label_entities()`/`area_entities()`/`floor_entities()` flat string list return type and `expand()` requirement before state/attribute access (FG-02, HALMark v0.9.9, MIT)
- Updated `spec/triggers.md` and `guides/review_and_checklist.md`: state trigger `to:`/`from:` and event trigger `event_type:` are literal string matches only — never Jinja; `for:` does accept Jinja; use `platform: template` + `value_template:` for evaluated expressions (FG-15, FG-22, HALMark v0.9.9, MIT)
- Added `spec/runtime.md`: Attribute Size Limit section covering HA recorder's silent 16,384-byte attribute drop and dict-merge guard pattern (FG-21, HALMark v0.9.10, MIT)
- Updated `spec/runtime.md`: Refactor & Upgrade Policy — HA standards compliance review is delivered as a succinct in-session summary only — not recorded in the automation, script, or any artifact, strengthened official HA docs as inviolable ground truth
- Added `patterns/recursive_loop.md`: Recursive Automation Loop pattern covering trigger entity == action target re-entry risk, detection heuristic, guard patterns, and common scenarios (FG-25, HALMark v0.9.10, MIT)
- Added `guides/review_and_checklist.md`: recursive loop checklist item in Automation Sub-Checklist
- Source: HALMark (https://github.com/nathan-curtis/HALMark, MIT License, Nathan Curtis)
## 0.5.3
- Extended guides/architecture_principles.md Section 2 with an explicit three-tier Decision Ladder (native construct → built-in helper → template sensor), inspired by homeassistant-ai/skills best-practices skill. Formalizes the "brains" selection process upstream of the existing brains vs muscles principle.
- Added `spec/entity_references.md`: guardrails for entity_id vs device_id usage in triggers, conditions, actions, and target selectors.
## 0.5.2b
- Added a YAML standards Core Rule
## 0.5.2a
- Updated additional snippets/jinja_patterns for correctness
## 0.5.2
- Clarified choose in skill.md
- Fixed incorrect split filter in snippets/jinja_patterns.md
- Expanded blueprint guidance in the Core Rules
## 0.5.1
- Added mandatory hard stop for secrets contained outside of secrets.yaml
- Refined choose vs if/then language
- Minor formatting updates
## 0.5.0
- Added Household UX / Annoyance Risk Review (HAF) as a required review step and sub-checklist.
- Elevated preservation of Household UX to a Core Rule.
- Added Blueprint Validation requirement (schema compliance + instantiated artifact validation).
## 0.4.x
- Introduced System Impact Classification (Class A–D).
- Standardized restart/recovery posture and trigger-level staggering.
- Formalized Safe Jinja constraints and YAML structure expectations.
- Strengthened review flow, validation discipline (DTT-first), and changelog/versioning rules.
- Clarified control-flow, idempotency, chatter control, and integration degradation patterns.


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
- **SECURITY HARD STOP**: Any artifact containing secrets (passwords, API keys, tokens, private keys, embedded credentials, etc.) is an automatic rejection. No publication. Secrets must never appear in artifacts.
- **System Impact Classification**: All systems MUST be classified by worst-credible impact (Class A–D) before design to determine required rigor, defensive programming posture, and validation depth.  See `/guides/system_impact_class.md`.
- **KISS first**: Prefer the simplest design that solves the problem robustly. For complex problems, silently propose **3–10 options**, compare trade‑offs, and converge on the simplest viable path.
- **YAML standards**: Always use (current release − 1) HA standards: Target the prior stable release (e.g., if current is 2026.2.x, use 2026.1.x standards). Consult official HA documentation before using any syntax not already demonstrated in this skill's examples.
- **GUI‑friendly YAML**: always include `alias:` and `description:`; use plural keys (`triggers`, `conditions`, `actions`); add `id:` per trigger; add `alias:` on nested steps (variables, if/then, choose, repeat sequences).
- **Conditional Control Flow**: Use `choose` only for **100% mutually exclusive branches** (each condition impossible if prior conditions were false). Exclusivity must be provable from system state alone — entity states, trigger IDs, or other HA-native discriminators — not assumed by convention, environment, or operational expectation. Use `if/elif/else` when conditions overlap or precedence matters (e.g., manual override escaping all checks). 
- **All automations must declare `mode:`** (e.g., `mode: single` to prevent duplicate actions). 
- **Ensure all trigger states are reachable** (no dead code branches); validate downstream actions handle all trigger states. Reachability must account for restart states (unknown, unavailable) and restored helper values.
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
- **Back-compat**: address Home Assistant **backward-incompatible (breaking) changes** from the last **12 months** affecting artifacts being authored, modified, or reviewed.
- **Comments policy**: Automations & scripts—**no comments**; use `description:` and `alias:` only. Template sensors—**optional** `#debug_*`, `# deps:`, `# verified:` comments for clarity. AppDaemon code—comments allowed for complex logic (use judiciously).
- **Exceptions**: allowed, but **must be documented inline** in `description`, `alias`, or sensor `#comments`.
- **Precise Updates**: When modifying complex existing systems, **favor surgical edits** over comprehensive rewrites (unless refactoring is explicitly approved); minimize diff footprint for easier review and rollback.
- Timezone: **America/Los_Angeles** (local time). Use `as_timestamp()` for time math.
- **Blueprints are packaging only**: The instantiated artifact must be indistinguishable from a first-class automation/script in structure, safety posture, and review rigor; template on the underlying artifact type first, and validate all blueprint-specific schema strictly against official Home Assistant documentation—conflicts are Skill Pack update candidates, not blueprint exceptions.
- Reliability includes **preservation of Household UX**; repeated annoyance constitutes a production-level defect.


## Review Process
Use **/guides/review_and_checklist.md** for the end‑to‑end review flow, rubric, and copy‑paste checklists (kept in sync with this page).

## Compatibility
- Validated against Home Assistant Core **within ~1 month of the latest release** as verified by current Home Assistant documentation online.

## Using this skill
See **HOWTO.md** for the table of contents and onboarding.
