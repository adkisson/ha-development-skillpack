# Recursive Automation Loop (Patterns)

An automation that **triggers on an entity and writes back to that same
entity** with no re-entry guard creates a recursive loop. HA's built-in
re-run limit eventually stops it, but not before causing system churn.

**Detection**: trigger `entity_id` and action `target.entity_id` are
identical, with no condition preventing re-entry on the return write.

## ❌ Loop — no guard
```yaml
trigger:
  - platform: state
    entity_id: input_boolean.fan_override
action:
  - action: input_boolean.toggle
    target:
      entity_id: input_boolean.fan_override
```

## ✅ Guarded — fires only on the intended transition
```yaml
trigger:
  - platform: state
    entity_id: input_boolean.fan_override
    to: 'on'
condition:
  - condition: state
    entity_id: input_boolean.fan_override
    state: 'on'
action:
  - action: input_boolean.turn_off
    target:
      entity_id: input_boolean.fan_override
```

## Common scenarios

- **Signal flags**: `input_boolean` used as a trigger signal that the
  same automation then clears.
- **Manual override tracking**: automation detects a manual change and
  writes a tracking helper, which re-triggers the automation.
- **State sync**: two automations watching each other's output entity.

## Guards

- Use `to:` on the trigger to constrain the firing edge.
- Add a condition that confirms the expected state before acting.
- For two-automation sync patterns, use separate trigger and tracking
  entities so the write target never matches the trigger source.
