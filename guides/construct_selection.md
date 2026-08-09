# Construct Selection

The canonical decision ladder for choosing how a piece of HA logic gets
built. Referenced by `workflows/architecture.md` (choosing the tier) and
`workflows/development.md` (documenting/implementing the choice) — defined
once here rather than restated in both.

Apply in order. Stop at the first tier that fully solves the problem.
Justification is only needed where the choice isn't self-evident — don't
narrate ruling out every higher tier when the answer is obvious.

## Tier 1 — Native construct

Native triggers, conditions, and actions validate at load time and fail
loudly; templates fail silently at runtime. Trigger selection and condition
selection are different decisions — don't reach for the same tool for both.

**Within the native tier, prefer in this order, stopping at the first that
expresses the requirement clearly and correctly:**

1. **HA purpose-specific trigger/condition** — the domain/entity semantic
   triggers and conditions HA ships per-domain (e.g. `battery.became_low`,
   `climate.is_target_temperature`, `schedule.block_started`,
   `timer.remaining_time_reached`, `update.became_available`,
   `vacuum.returned_to_dock`). Introduced experimentally in HA 2025.12,
   default since 2026.7. Not the same thing as `sun`/`zone`/`device` below
   — this is a specific, still-growing, per-domain/integration system.
   Check `home-assistant.io/triggers/<domain>.<event>/` (and the
   `/conditions/` equivalent) for whether one exists for the domain in
   question before assuming there is or isn't one — don't invent a name by
   analogy. When one exists, prefer it: it targets `entity_id` / `area_id`
   / `device_id` / `floor_id` / `label_id` natively, handles `unknown`/
   `unavailable` source states correctly without a manual guard, and often
   removes a `for:`/debounce condition you'd otherwise hand-write (see
   `options: behavior:` and `options: for:` below).
2. **Other semantically specific native construct** — a construct designed
   for exactly this kind of check that predates the purpose-specific system
   (sun position, zone presence, a device's own defined capability/event).
   Prefer it over the generic rung below when it directly represents the
   intended behavior — it's the most legible to the next reader and often
   has domain behavior (sunrise/sunset math, zone geometry) built in
   correctly.
3. **Generic native construct** — `state`, `numeric_state`, `time`,
   `time_pattern`, `event`, composed with `and`/`or` as needed. Use when
   neither of the above fits.
4. **Template-based construct** (`condition: template`,
   `trigger: template`) — only when no native construct at any of the
   above rungs fits.

This is about semantic fit, not novelty for its own sake. Don't mechanically
convert a working generic construct to a purpose-specific one just because
one exists — use whichever rung actually represents the behavior most
clearly and correctly for this case, and don't assume a purpose-specific
trigger/condition exists for a domain without checking current docs.

**Trigger selection** — what event or state change should start evaluation:
- Domain-native semantic event with a shipped purpose-specific trigger
  (check current docs) → e.g.:
  ```yaml
  trigger: battery.became_low
  target:
    entity_id: binary_sensor.front_door_lock_battery
  ```
  Multi-target firing behavior (`each` / `first` / `all`) and a `for:`
  duration are configured under `options:`, not hand-rolled with a
  separate debounce condition.
- Sun-relative or device-native event, no purpose-specific trigger exists →
  other semantically specific: `trigger: sun` for sunrise/sunset-relative
  firing; `trigger: device` for a device's own defined event (e.g. Z-Wave
  Central Scene — see `spec/zwave_js.md`).
- Entity state change (generic) → `trigger: state` (with `to:`/`from:` as
  literal matches, `for:` for debounce).
- Value crosses a threshold (generic) → `trigger: numeric_state`
  (`above:`/`below:`), not a state trigger paired with a template
  condition.
- Scheduled time (generic) → `trigger: time` (fixed) or a `time` trigger
  sourced from an `input_datetime` for deferred-intent deadlines (not
  polling — see `patterns/datetime_deadline.md`).
- Recurring interval (generic, fallback) → `trigger: time_pattern`, only
  when no event-driven option exists (see `spec/performance.md` for the
  polling floor).
- Event bus signal with no closer fit at any rung above (generic) →
  `trigger: event`.

**Condition selection** — what must hold true to proceed:
- Domain-native semantic check with a shipped purpose-specific condition
  (check current docs) → e.g.:
  ```yaml
  condition: battery.is_low
  target:
    entity_id: binary_sensor.front_door_sensor_battery_low
  ```
- Sun-relative gate, no purpose-specific condition exists → other
  semantically specific: `condition: sun` (with `before:`/`after:`
  offsets), not manual sunrise/sunset arithmetic and not a generic
  `numeric_state` on a sun sensor.
- Presence-in-area gate, no purpose-specific condition exists → other
  semantically specific: `condition: zone`, not manual lat/long or
  `area_id` comparison logic.
- Numeric comparison (generic, no closer fit above) → `condition:
  numeric_state` (`above:`/`below:`), not
  `{{ states('sensor.x') | float > 25 }}`.
- Boolean/state match, single or combined (generic) → `condition: state`
  composed with `condition: and` / `condition: or`, not
  `{{ is_state(...) and is_state(...) }}`.
- Time-of-day or weekday gate (generic) → `condition: time`
  (`after:`/`before:`/`weekday:`), not `{{ now().hour >= 9 }}`.

### Preserve intentional entity targeting

**Do not replace explicit entity targeting with broader purpose-, area-,
device-, or domain-level targeting when the exact entity set defines an
intentional scope, control, or authority boundary.**

Purpose-specific constructs are about semantic fit, not about replacing
deliberate scope. Cases where the entity set *is* the boundary: a specific
known set of motion sensors meant to be authoritative, a light group whose
membership defines automation scope, particular thermostats intentionally
controlled while others in the same area are not, manual-override or safety
entities whose identity matters, or an installation where area/device
groupings are broader or more dynamic than what this automation is meant to
control.

The distinction: if explicit entities are present only because older syntax
required them, replacing them with a cleaner construct is a real
improvement. If the exact entity set *is* the control or authority
contract, preserve it — a "cleaner" area- or purpose-level construct that
silently changes who or what the automation affects is not an improvement.

This applies directly to purpose-specific triggers/conditions: their
`target:` accepts `entity_id`, `area_id`, `device_id`, `floor_id`, or
`label_id`. Use `entity_id` when the exact entity set is the boundary; use
a broader target only when the automation is genuinely meant to react to
everything in that area/floor/label, now and as it changes.

**Overall principle**: prefer the most semantically expressive native
construct that preserves the intended authority boundary.

## Tier 2 — Built-in helper

Can a helper replace a template sensor? Helpers are declarative, handle
unavailable states gracefully, and require no Jinja.

- Sum/average across entities → `min_max` helper.
- Any-on / all-on across a group → `group` helper.
- Rate of change → `derivative` helper.
- Cross-threshold with built-in hysteresis → `threshold` helper.
- Consumption tracking (resets on a schedule) → `utility_meter` helper.
- Rolling statistics (mean, stdev, count over a window) → `statistics`
  helper.
- Scheduled on/off window (not deferred-intent, a recurring window) →
  `schedule` helper or a `tod` (times of day) binary sensor.

## Tier 3 — Template sensor

Only if Tiers 1 and 2 cannot solve it. Computes directive/state and, for
non-trivial logic, a human-readable `reason`; treated as non-authoritative
output — see `workflows/architecture.md` for whether a separate
state/actuation boundary is even warranted here.

## Tier 4 — AppDaemon

Preferred when YAML is insufficient: long-lived state, multi-step
workflows, complex orchestration, or external system coordination. Also
worth considering when a YAML solution becomes difficult to reason about,
test, or maintain — not only when YAML is strictly impossible. Skill Pack
constraints still apply for all HA-facing behavior (state handling, restart
resilience, overrides).
