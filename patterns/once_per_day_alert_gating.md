# Once-Per-Day Alert Gating Pattern

## TL;DR

- Use `input_datetime` with full date+time to store the last alert timestamp
- Use sentinel `2999-01-01 00:00:00` to represent “no alert sent yet”
- Send the alert when the violation is active and either:
  - no alert has been sent yet, or
  - the last alert was sent on a prior calendar day
- Clear back to the sentinel when the violation resolves to allow same-day re-alert on recurrence
- This is a specialized cadence pattern built on the datetime-first doctrine

---

## Purpose

When monitoring systems that may have persistent or recurring violations (temperature alerts, battery warnings, maintenance reminders), you often want:

- alert sent once per calendar day, even if the violation persists
- automatic re-alert if the violation resolves and recurs the same day
- clean re-alert on the next calendar day if the violation is still active

This pattern uses `input_datetime` helpers with the canonical datetime model to gate alert dispatch without complex timers or state machines.

---

## Architecture

**Components:**
- `input_datetime.violation_alert_last_sent` — stores the last alert timestamp
- template sensor — detects violation state (brains)
- automation — gates alert dispatch by comparing the last-sent day against today (muscles)

**Logic flow:**
```text
Violation occurs?
  ├─ Yes: Check if last_sent is sentinel OR older than today
  │   ├─ Yes: Send alert + set datetime to now()
  │   └─ No: Skip (already alerted today)
  └─ No: Clear datetime to sentinel (enables same-day re-alert)
```

---

## Helper Setup

Create one `input_datetime` per violation type:

```yaml
violation_alert_last_sent:
  name: "Violation Alert Last Sent"
  has_date: true
  has_time: true
  icon: mdi:bell-alert
```

**Key points:**
- `has_date: true` stores the calendar day for daily gating
- `has_time: true` records the exact send time for debugging and audit
- no null/blank clearing is used

---

## Sentinel

```text
2999-01-01 00:00:00
```

In this pattern, the sentinel means **“no alert sent yet”**, not “disabled.”

That makes the sentinel state immediately eligible to alert when the violation is active.

Rules:
- represents unsent / reset state
- replaces all null / blank usage
- must not be used for real scheduling

---

## Canonical Semantics

Use repeated literal sentinel parsing in comparisons and fallback defaults. Do not depend on cross-variable datetime serialization.

```jinja
{% set last_sent = as_datetime(
  states('input_datetime.violation_alert_last_sent'),
  as_datetime('2999-01-01 00:00:00')
) %}
{% set active = last_sent != as_datetime('2999-01-01 00:00:00') %}
{% set last_sent_day = as_timestamp(last_sent) | timestamp_custom('%Y-%m-%d', true) %}
{% set today_day = as_timestamp(now()) | timestamp_custom('%Y-%m-%d', true) %}
{% set is_new_day = active and last_sent_day < today_day %}
```

Interpretation:
- unsent = sentinel
- active = not sentinel
- eligible = (not active) OR new calendar day

---

## Core Gating Logic

```jinja
{% set last_sent = as_datetime(
  states('input_datetime.violation_alert_last_sent'),
  as_datetime('2999-01-01 00:00:00')
) %}

{% set active = last_sent != as_datetime('2999-01-01 00:00:00') %}
{% set last_sent_day = as_timestamp(last_sent) | timestamp_custom('%Y-%m-%d', true) %}
{% set today_day = as_timestamp(now()) | timestamp_custom('%Y-%m-%d', true) %}
{% set should_alert = (not active) or (last_sent_day < today_day) %}

{{ violation_state == 'active' and should_alert }}
```

---

## Consume Behavior

### Set when alert is sent

```yaml
- action: input_datetime.set_datetime
  target:
    entity_id: input_datetime.violation_alert_last_sent
  data:
    datetime: "{{ now().strftime('%Y-%m-%d %H:%M:%S') }}"
```

### Clear when violation resolves

```yaml
- action: input_datetime.set_datetime
  target:
    entity_id: input_datetime.violation_alert_last_sent
  data:
    datetime: "2999-01-01 00:00:00"
```

This symmetry enables:
- alert sent this morning
- violation resolves this afternoon
- violation recurs this evening
- alert is allowed again immediately

---

## Overdue Policy

**Overdue Policy:** execute immediately if overdue (daily gate ensures evaluation)

Reason:
- the daily check must send the alert if a prior eligible day was missed

---

## Complete Automation Example

```yaml
alias: Violation Monitoring – Alert Once Per Day
description: >
  Monitors violation state. Sends alert at most once per calendar day, with
  automatic re-alert if the violation resolves and recurs the same day.

  Owner: automation.violation_alert_monitor
  Overdue Policy: execute immediately if overdue

triggers:
  - id: violation_changed
    alias: Violation state changed
    trigger: state
    entity_id: sensor.violation_status

  - id: daily_gate
    alias: Daily check at 10:00 AM
    trigger: time
    at: "10:00:00"

conditions: []

actions:
  - alias: Capture violation state and last-sent values
    variables:
      violation_state: >
        {{ state_attr('sensor.violation_status', 'violation_flag') }}

      last_sent: >
        {{ as_datetime(
          states('input_datetime.violation_alert_last_sent'),
          as_datetime('2999-01-01 00:00:00')
        ) }}

      active: >
        {{ last_sent != as_datetime('2999-01-01 00:00:00') }}

      last_sent_day: >
        {{ as_timestamp(last_sent) | timestamp_custom('%Y-%m-%d', true) }}

      today_day: >
        {{ as_timestamp(now()) | timestamp_custom('%Y-%m-%d', true) }}

      should_alert: >
        {{ (not active) or (last_sent_day < today_day) }}

  - alias: Send alert if violation active and eligible
    if:
      - condition: template
        value_template: >
          {{ violation_state == 'active' and should_alert }}
    then:
      - action: telegram_bot.send_message
        data:
          message: "⚠️ Violation Alert"

      - action: input_datetime.set_datetime
        target:
          entity_id: input_datetime.violation_alert_last_sent
        data:
          datetime: "{{ now().strftime('%Y-%m-%d %H:%M:%S') }}"

  - alias: Clear timestamp if violation resolved
    if:
      - condition: template
        value_template: >
          {{ violation_state != 'active' }}
    then:
      - action: input_datetime.set_datetime
        target:
          entity_id: input_datetime.violation_alert_last_sent
        data:
          datetime: "2999-01-01 00:00:00"

mode: single
```

---

## Optional Grace Window

If needed, use a `timer` to delay alerting briefly and cancel if the violation clears before the grace window ends.

That is a valid timer use case because it is a **cancelable grace window**, not durable deferred intent.

---

## Testing & Validation

Validated in Developer Tools → Templates for:

- fallback from `unknown` to sentinel
- stable equality between repeated `as_datetime('2999-01-01 00:00:00')` calls
- sentinel detection via object comparison
- same-day suppression
- next-day re-alert eligibility

Representative outcomes:
- `helper_raw = 'unknown'` → active `False`, should_alert `True`
- `helper_raw = '2999-01-01 00:00:00'` → active `False`, should_alert `True`
- `helper_raw = '2026-04-10 09:00:00'` on the same day → active `True`, should_alert `False`
- `helper_raw = '2026-04-09 09:00:00'` on the next day → active `True`, should_alert `True`

---

## Related Patterns

- `/patterns/datetime_deadline.md`
- `/patterns/restart_resilience.md`
- `/snippets/jinja_patterns.md`
