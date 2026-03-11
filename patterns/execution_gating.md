# Execution Gating (Pattern)

Structure automations so the **primary action path is the positive case**.
Frame every decision point as "what must be true to proceed" rather than
"what would stop me."

## Guideline

All blocking facts — overrides, faults, inhibit flags, quiet hours, safety
states — are inputs to the execution decision, not independent negative
branches scattered through the action sequence. Frame the action path
positively: what must be true to proceed.

This applies at every level and scales from a single native condition to a
resolved boolean variable for complex multi-factor gates.

## Principles

- **Positive framing at every level**: a single `condition: state` that must
  be true, a `numeric_state` threshold that must be met, or a computed
  `allow_*` / `run_*` / `should_*` variable — all are valid execution gates.
  Choose the simplest form that makes the positive case readable.
- **Single resolution point**: evaluate each gate once, after inputs are
  normalized. Never re-evaluate the same blocking fact in multiple places.
- **Actions follow the positive path**: timestamps, sent flags, device
  commands, and notifications live inside the positive branch — never before
  the gate or in a negative branch.
- **Explicit negative case**: when the negative path has meaning (fallback
  action, audit trail), provide an `else:` branch. When it does not, `else:`
  may be omitted; a bare `stop:` is acceptable when an explicit denial record
  aids debugging.

## Simple gate — single condition

```yaml
- alias: Act only when export is sufficient
  if:
    - condition: numeric_state
      entity_id: sensor.solar_export_3m_avg
      below: -3200
  then:
    - alias: Primary action
      ...
```

## Compound gate — resolved variable

When multiple blocking facts converge, resolve them into a single named
variable first:

```yaml
- alias: Resolve inputs once
  variables:
    allow_action: "{{ not (blocking_fact_a or blocking_fact_b) }}"

- alias: Execute only when allowed
  if:
    - condition: template
      value_template: "{{ allow_action | bool(false) }}"
  then:
    - alias: Primary action
      ...
```

## Scales to multiple independent paths

Apply a separate gate per path rather than one monolithic variable:

```yaml
- alias: Resolve inputs once
  variables:
    allow_notification: "{{ ... }}"
    allow_device_command: "{{ ... }}"

- alias: Send notification if allowed
  if:
    - condition: template
      value_template: "{{ allow_notification | bool(false) }}"
  then:
    ...

- alias: Issue device command if allowed
  if:
    - condition: template
      value_template: "{{ allow_device_command | bool(false) }}"
  then:
    ...
```

## When to use

- Any automation where the positive action path has preconditions.
- Suppression logic: cooldowns, SOC ladders, override flags, quiet hours,
  safety interlocks.
- Notification automations where actions must only execute on actual delivery.

## Boundaries and exceptions

- Safety-critical, security, or hardware-protection automations still use this
  pattern, but with stricter evidence for the positive execution condition:
  execute only when every required condition is provably met, and default to
  no action on uncertainty. See `guides/system_impact_class.md` for Class A–B
  classification guidance.
- Mutually exclusive multi-branch automations where several equally-weighted
  paths are exhaustive (e.g. a `choose` covering all reachable states). Forcing
  one branch into "the positive path" is artificial — each branch is its own
  positive case. Use `choose` per the skill's conditional control flow guidance.
- Unconditional action sequences with no preconditions, or automations already
  fully gated by their triggers and top-level conditions — the gate adds no
  value inside the action sequence.
