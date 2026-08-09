# YAML Authoring Standards

This file merges formatting, trigger, and header standards into a single authoring reference. Apply in full for any new or modified YAML artifact.

---

## Units, Rounding & Timezone

- **Units**: Temperature °F, Power W, Energy kWh by default. Convert at edges if upstream differs.
- **Rounding**: 1 decimal for temperature; `int(0)` for brightness; 0 decimals for percentages unless user-facing text needs one.
- **Timezone**: America/Los_Angeles. Use `as_timestamp()` for calculations; format times for user messages with local time (AM/PM or 24-hour per context).
- **Strings**: normalize via `| lower | trim`; avoid Python string methods.

---

## YAML Structure & GUI Compatibility

- Use **current release −1** as the minimum YAML/Jinja standard floor; reject deprecated or "also works" syntax.
  - Use plural keys: `triggers:`, `conditions:`, `actions:`. Singular forms are deprecated and produce GUI-unfriendly YAML — this is a correctness requirement, not a style preference.
- All automations must declare `mode:`.
- `alias:` is valid in automations and scripts at the top level and on schema-supported nested elements such as triggers, conditions, action steps, repeat/choose branches, and variable action steps. It is also valid at the top level of scenes. It is **not** valid inside arbitrary variable mappings, template sensors, input helpers, or other YAML-defined entities — do not extrapolate it there.
- Add `id:` per trigger in automations only. Multiple triggers may share an `id` only when they intentionally collapse to the same evaluation path. `id:` is not valid on template sensor triggers or other YAML-defined entity triggers.
- `description:` required at automation/script level; schema-supported naming used for YAML-defined entities.
- **No YAML comments in automations or scripts** — the GUI strips them silently.
  - Use `description:` for artifact-level purpose, dependencies, changelog, and broad operational context.
  - Use nested `alias:` for short trace/editor identity only.
  - Use nested `note:` for schema-supported trigger, condition, and action maintenance rationale when the reason is non-obvious.
  - Do not put long explanations in `alias:`.
  - Do not use `note:` to restate obvious YAML behavior.
  - `note:` is valid only where the installed Home Assistant schema supports it; do not extrapolate it to template sensors, helpers, or arbitrary mappings.
- YAML-defined entities that do not support Markdown-rendered `description:` use `# CHANGELOG:` comments near the top of the definition.

---

### Alias vs Note

Use `alias:` to identify the step in traces and the automation editor.

Use `note:` to explain why the step exists, especially for:
- restart/restore guards
- race-condition defenses
- cooldown/dedupe logic
- fail-open/fail-closed choices
- override behavior
- intentionally suppressed behavior
- non-obvious dependency ordering

For simple mechanical steps, omit `note:`.

Good:
```yaml
- condition: template
  alias: NWS gate — reject bad prior state; cooldown resend requires startup stable
  value_template: |-
    {{ ... }}
  note: >-
    Null/unknown prior state is rejected because startup restore echoes cannot
    be safely distinguished from genuine new alerts. Cooldown resend requires
    startup stabilization to avoid helper restore-order races.
```

Bad:
```yaml
- condition: template
  alias: >-
    Long multi-sentence explanation of every failure mode and why the condition
    exists...
  value_template: |-
    {{ ... }} 
```
---

## Conditional Control Flow

- Use `choose` only for **provably mutually exclusive branches** — exclusivity must be discriminated by trigger ID, entity state, or other HA-native discriminator, not assumed.
- Use `if/then/else` for prioritized execution where conditions may overlap.
- **`elif` is not valid in HA YAML** — use `choose` or nested `if/then/else` instead. (`elif` is valid in Jinja and AppDaemon Python; this rule is YAML-only.)

---

## Trigger Standards

**Order of preference**:
1. Event/state-driven (state, event, template) — first choice. This includes state triggers watching timer entities (e.g., `timer.ha_startup_delay → idle`) — these are event-driven, not time-based.
2. Time-based polling (`time_pattern`, `interval`) — only when necessary; minimum 60s cadence unless critical.

**Exception**: a time trigger scheduled from an `input_datetime` entity is the correct and preferred trigger for deferred-intent deadline patterns. This is not polling — it fires once at the scheduled time and is the intended mechanism for restart-resilient scheduling. See `/patterns/datetime_deadline.md`.

**Debounce & windows**:
- Use `for:` windows on triggers rather than delays in actions.
- For boolean entities, specify `to:`/`from:` when only one transition is intended. Omit them intentionally when both transitions must trigger recomputation (e.g. a template sensor that needs to react to a boolean helper turning either on or off) — document why inline when it isn't obvious from context.
- Restart staggering on `timer.ha_startup_delay → idle`: critical **<10s fixed**; non-critical **45–75s randomized**.
- Startup triggers only when post-restart actions are needed (state recovery, guard initialization). Avoid for passive/event-driven automations.

**Template complexity in triggers**:
- Trigger `for:` blocks have reduced template context; keep them simple. Move complex calculations to template sensors or action variables.
- `to:`/`from:` in state triggers and `event_type:` in event triggers are **literal string matches** — Jinja placed there is never evaluated and the trigger silently never fires. `for:` does accept Jinja. Use `trigger: template` with `value_template:` for any expression requiring evaluation.

**Device-specific triggers**:
- Prefer state triggers on specific entities over generic event broadcasts (e.g., `zwave_js_value_notification`). Eliminates Z-Wave bus overhead and reduces latency.
- Caveat: some devices may not persist state; verify the entity updates on your hardware before relying on state triggers.

**Deviations**: trigger pattern deviations are allowed when justified inline in the artifact’s supported documentation channel: `description:` for artifact-level rationale, `alias:` for concise trace identity, or `note:` for schema-supported step-level rationale.

---

## YAML Header Standards

Every YAML artifact must include the schema-supported equivalent of:
- A human-readable name/title (`alias:` where valid; otherwise the artifact's native naming key).
- A purpose/decision note (`description:` where valid; otherwise nearby comments when the schema does not support descriptions).
- A concise **CHANGELOG** using the placement rules below.
- Dependencies documented when non-obvious and relevant: in `description:` for automations/scripts; in comments for YAML-defined entities.

---

## Changelog Format

**Entry format**: `- YYYYMMDD-HHMM: Single sentence summary.` (the leading `-` is the Markdown/YAML list item prefix)
**Order**: newest entry first.
**Timezone**: America/Los_Angeles (local time).
**Timestamp meaning**: local authoring/update time, not runtime event time.
**Content**: change-focused prose — what changed and the functional reason why. Keep it short. Do not explain the process ("per architect review"), attribute decisions to external parties, or repeat information already clear from the YAML. No entity IDs, no YAML snippets.

**`description:` content rules**:
- Outline major functionality and non-obvious design decisions — not a natural language rehash of the YAML.
- Omit anything self-evident from reading the automation/script.
- No explicit entity IDs or helper names. These become stale, make deprecations harder to find, and create maintenance debt. Describe function, not implementation (e.g., "garage door safety coordinator" not `input_boolean.garage_door_safety_override`).

**Changelog content rules**:
- Change-focused and brief — one sentence per entry describing what changed functionally.
- No attribution ("per architect recommendation", "as discussed"), no process narrative, no rationale beyond the functional reason.
- No explicit entity IDs or helper names. These become stale and pollute searches for deprecated or renamed entities. Describe what changed functionally, not which entity changed.

### a) Automations & Scripts

Changelog lives in the YAML `description:` field (Markdown-rendered). Never use `#` comments for changelogs in automations or scripts.

`description:` formatting rules:
- Each paragraph must be a single unbroken line — no internal line wrapping within a paragraph.
- Line breaks are only permitted between paragraphs and within the CHANGELOG block as specified below.
- Use the YAML block scalar `>` (folded) so the field reads cleanly in the editor.

Formatting requirements for the CHANGELOG block:
- Two blank lines before `**CHANGELOG:**`
- `**CHANGELOG:**` bold and all-caps
- One blank line after `**CHANGELOG:**` before first entry
- One blank line between each entry
- When using list items (`- ...`), the blank line after `**CHANGELOG:**` is mandatory or Markdown rendering breaks

### b) YAML-defined entities (template sensors, input helpers)

These do not support Markdown-rendered descriptions. Use `# CHANGELOG:` comments near the top of the definition instead.

---

## Example (Automation / Script)

```yaml
alias: Lighting – Porch Wave Pattern
description: >
  Subtle evening wave effect for porch lighting. Minimal chatter guard applied; idempotent by design. Depends on evening-mode coordination and porch lighting group behavior.


  **CHANGELOG:**

  - 20251022-1200: Tuned debounce and restart gate to reduce duplicate executions after restart.
```

---

## Blueprints

Blueprints are packaging only — not an exemption from Skill Pack standards. Design and validate against the underlying artifact type first. Blueprint-specific schema must comply with official HA documentation; the instantiated artifact is reviewed to the same standard as a hand-authored automation or script.

---

## Exceptions

Deviations from any standard in this file are allowed only when documented inline in the artifact's supported documentation channel (`description:`/`alias:`/`note:` for automations/scripts where schema-supported; comments for YAML-defined entities).
