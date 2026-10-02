# Restart Resilience (Patterns)

| Type | Trigger `for:` window | Purpose |
|------|----------------------|----------|
| **Critical** | `<10s` fixed | Safety/security/HVAC |
| **Non-critical** | `45–75s` randomized | Reconciliation tasks |
| **Diagnostic** | `>90s` fixed or skipped | Optional, no actuation |

## Guidelines

- Use **trigger-level `for:`** on `timer.ha_startup_delay` `from: active` `to: idle` to stagger; **do not** use action delays.
- Reconcile directives once; avoid actuation storms.
- Use `input_datetime` for persisted deferred intent (deadline-style); use `timer` only for countdown semantics (see: `/patterns/datetime_deadline.md`).
- Idempotency after restart: guard re-sends.

---

## Deadline-Based Recovery

For systems using deferred intent:

- Store the intended execution time in an `input_datetime`
- On startup, evaluate:
  - whether the deadline is active (not sentinel)
  - whether it is now due (`now() >= deadline`)
- Apply the declared overdue policy

This ensures that work missed during downtime is handled deterministically.

See: `/patterns/datetime_deadline.md` for canonical deadline semantics and implementation.

---

## Offline Sensor Detection at Boot (Edge Case Recovery)

This uses a **timer as a cancelable grace window**, which is a legitimate timer use case under the datetime-first doctrine.

### Scenario

Sensor is already unavailable when HA starts, state restores as unavailable without a state-change event, offline timer is idle, and no trigger fires to start the grace window.

### Solution

Add a startup recovery trigger after `timer.ha_startup_delay` reaches idle:

```yaml
triggers:
  - id: startup_sensor_unavailable
    alias: HA startup with sensor already unavailable
    trigger: state
    entity_id: timer.ha_startup_delay
    from: active
    to: idle
    for:
      seconds: "{{ range(45, 76) | random }}"  # Non-critical automation delay
```

Then check sensor state and start offline grace window:

```yaml
actions:
  - alias: Start offline timer if sensor unavailable at startup
    if:
      - condition: trigger
        id: startup_sensor_unavailable
      - condition: state
        entity_id: sensor.monitored_sensor
        state:
          - unavailable
          - unknown
      - condition: state
        entity_id: timer.offline_grace_window
        state: idle
    then:
      - action: timer.start
        target:
          entity_id: timer.offline_grace_window
        data:
          duration: "00:05:00"
```

This ensures offline detection doesn't miss sensors that were disconnected before HA booted.

---

## Threshold Triggers Across Outages

Restarts and brief `unavailable` dropouts distort threshold triggers. Where
a threshold automation switches a consequential load (water heater, pump,
EV charger, compressor), build it in two parts.

**1. Threshold trigger**

a) **Purpose-specific** — `<domain>.crossed_threshold` (power, temperature,
humidity, battery, illuminance, moisture, air quality, and others) when the
sensor carries the matching device class. It ignores any change that starts
from `unavailable` or `unknown`, so a restart or dropout never produces a
false crossing.

b) **`numeric_state`** — when no purpose-specific trigger fits. It treats
`unavailable`/`unknown` as outside the threshold, so the first reading after
a restart or dropout fires even when the value never changed; `for:` only
delays that fire. Where a false fire costs more than a missed one, add this
guard condition:

```yaml
conditions:
  - condition: template
    alias: Ignore threshold fires that arrive straight from an outage
    value_template: "{{ trigger.platform != 'numeric_state' or is_number(trigger.from_state.state) }}"
```

Both a) and b) miss a genuine crossing that happens while the sensor is
offline (1400 W → `unavailable` → 2500 W).

**2. Recovery and startup**

Recover missed crossings by re-evaluating the current state instead of
reacting only to the crossing:

- Add a `state` trigger on the sensor `from: [unavailable, unknown]`,
  `not_to: [unavailable, unknown]`, with a short `for:`.
- Add the startup trigger on `timer.ha_startup_delay` `from: active`
  `to: idle`.
- Condition every path on: startup timer `idle`; value currently past the
  threshold (`<domain>.is_value` or `numeric_state`); load not already in the
  target state.

The "not already in the target state" condition makes duplicate runs
harmless. Where a person can switch the load off deliberately, apply the
override precedence in `spec/safety.md` so recovery does not re-assert it.

```yaml
triggers:
  - trigger: power.crossed_threshold
    id: crossed
    target:
      entity_id: sensor.example_export_power
    options:
      threshold:
        type: above
        value:
          number: 2000
          unit_of_measurement: W
  - trigger: state
    id: recovered
    entity_id: sensor.example_export_power
    from:
      - unavailable
      - unknown
    not_to:
      - unavailable
      - unknown
    for:
      seconds: 30
  - trigger: state
    id: startup
    entity_id: timer.ha_startup_delay
    from: active
    to: idle
    for:
      seconds: "{{ range(45, 76) | random }}"
conditions:
  - condition: state
    alias: Startup window has finished
    entity_id: timer.ha_startup_delay
    state: idle
  - condition: power.is_value
    alias: Export is above the threshold now
    target:
      entity_id: sensor.example_export_power
    options:
      threshold:
        type: above
        value:
          number: 2000
          unit_of_measurement: W
  - condition: state
    alias: Water heater is not already on
    entity_id: switch.example_water_heater
    state: "off"
actions:
  - action: switch.turn_on
    target:
      entity_id: switch.example_water_heater
```

---

## `for:` Durations Across Restarts

A `for:` duration (on triggers and `state` conditions) measures continuous
time in the matching state. A restart discards a pending countdown, and an
`unavailable` dropout restarts it from zero; `now() - last_changed` math
resets the same way. Keep `for:` to debounce and stagger windows. For long
backstops (hours), stamp an `input_datetime` on the genuine transition and
gate on elapsed time since the stamp — see `/patterns/datetime_deadline.md`.

---

## Helper `initial:` Values

An `initial:` value on `input_boolean`, `input_number`, `input_select`,
`input_text`, or `input_datetime` replaces the restored state on every
restart, even when it is `false` or `0`. Omit `initial:` on helpers whose
state must survive restarts; set it only where the helper must start at a
fixed value every time.
