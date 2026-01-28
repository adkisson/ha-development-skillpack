# Once-Per-Day Alert Gating Pattern

## Purpose

When monitoring systems that may have persistent or recurring violations (temperature alerts, battery warnings, maintenance reminders), you often want:
- Alert sent once per calendar day, even if violation persists
- Automatic re-alert if violation resolves and recurs same day
- Clean re-alert on next calendar day if violation is still active

This pattern uses `input_datetime` helpers to gate alert dispatch, enabling fine-grained control over notification cadence without complex timers or state machines.

---

## Architecture

**Components:**
- `input_datetime.violation_alert_last_sent` — stores the datetime when alert was last sent
- **Template sensor** — detects violation state (brains)
- **Automation** — gates alert dispatch by comparing last-sent date against today (muscles)

**Logic flow:**
```
Violation occurs?
  ├─ Yes: Check if datetime is null OR older than today
  │   ├─ Yes: Send alert + set datetime to now()
  │   └─ No: Skip (already alerted today)
  └─ No: Clear datetime to null (enables same-day re-alert if violation recurs)
```

---

## Implementation Details

### 1. Helper Setup

Create one `input_datetime` per violation type:

```yaml
# input_datetime.yaml
violation_alert_last_sent:
  name: "Violation Alert Last Sent"
  has_date: true
  has_time: true
  icon: mdi:bell-alert
```

**Key points:**
- `has_date: true` — stores full date for calendar-day comparison
- `has_time: true` — records exact send time for debugging/audit
- No `editable: false` — owner may manually reset if needed (defensive)

---

### 2. Safe Datetime Comparison

**Pattern: Null-safe date comparison**

```jinja2
{% set last_sent = states('input_datetime.violation_alert_last_sent') %}
{% set last_sent_dt = as_datetime(last_sent, none) %}
{% set is_null_or_old = last_sent in ['unavailable', 'unknown', ''] or (last_sent_dt is not none and last_sent_dt.date() < now().date()) %}
{{ is_null_or_old }}
```

**Why this pattern:**
- `last_sent in ['unavailable', 'unknown', '']` catches null states without calling `as_datetime()` on them
- `as_datetime(last_sent, none)` returns `none` if parsing fails (safe fallback)
- `last_sent_dt is not none` guards against calling `.date()` on `none` (prevents errors)
- Only calls `.date()` if we have a valid datetime object
- Correctly handles first-ever alert (null → alerts immediately) and next-calendar-day persistence (old date → alerts again)

**Do NOT use:**
```jinja2
# ❌ WRONG: as_datetime(none, none).date() crashes
{{ as_datetime(last_sent, none).date() < now().date() }}

# ❌ WRONG: Assumes strftime always works
{{ last_sent | as_datetime | strftime('%Y-%m-%d') < now().strftime('%Y-%m-%d') }}
```

---

### 3. Timestamp Format Consistency

**When setting datetime, use `strftime`:**

```yaml
action: input_datetime.set_datetime
target:
  entity_id: input_datetime.violation_alert_last_sent
data:
  datetime: "{{ now().strftime('%Y-%m-%d %H:%M:%S') }}"
```

**Why `strftime` over `isoformat()`:**
- HA's native `input_datetime` renders as `YYYY-MM-DD HH:MM:SS` (no T, no timezone)
- `isoformat()` produces `YYYY-MM-DDTHH:MM:SS.micro+TZ` (inconsistent, verbose)
- `strftime` matches the native format for consistency in UI and parsing
- Easier to read in Developer Tools and logs

---

### 4. Resolve/Re-Alert Symmetry

**When violation clears, set datetime to null:**

```yaml
- alias: Clear alert timestamp if violation resolved
  if:
    - condition: template
      value_template: >
        {{ violation_state != 'active' and last_sent not in ['unavailable', 'unknown', ''] }}
  then:
    - action: input_datetime.set_datetime
      target:
        entity_id: input_datetime.violation_alert_last_sent
      data:
        datetime: null
```

**This enables:**
- Violation clears at 2:00 PM → datetime set to null
- Violation recurs at 4:00 PM (same day) → null datetime → alert sent again + datetime set to now
- Tomorrow morning, violation still active → datetime is yesterday → alert sent again + datetime updated to today

**Without this clear logic:**
- Once you've alerted today, you won't re-alert same day even if violation recurs
- Breaks the "re-alert on recurrence" requirement

---

## Complete Automation Example

```yaml
alias: Violation Monitoring – Alert Once Per Day
description: >
  Monitors violation state. Sends alert at most once per calendar day, with
  automatic re-alert if violation resolves and recurs same day.
  
  **CHANGELOG:**
  
  - 20260127-0600: Updated with CHANGELOG
  - 20260126-1430: Updated with YAML standards current as of version 2026.1.x

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
  - alias: Capture violation state and last-sent timestamp
    variables:
      violation_state: >
        {{ state_attr('sensor.violation_status', 'violation_flag') | default(none) }}
      last_sent: >
        {{ states('input_datetime.violation_alert_last_sent') }}
      now_date: >
        {{ now().date() }}

  - alias: Send alert if violation active and gated
    if:
      - condition: template
        value_template: >
          {% set last_dt = as_datetime(last_sent, none) %}
          {% set should_alert = last_sent in ['unavailable', 'unknown', ''] or (last_dt is not none and last_dt.date() < now_date) %}
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
          {{ violation_state != 'active' and last_sent not in ['unavailable', 'unknown', ''] }}
    then:
      - action: input_datetime.set_datetime
        target:
          entity_id: input_datetime.violation_alert_last_sent
        data:
          datetime: null

mode: single
```

---

## Common Variations

### Multiple violations with different cadences

Create separate `input_datetime` helpers per violation (e.g., `temp_high_alert_last_sent`, `temp_low_alert_last_sent`). Use the same gating logic independently for each.

**Benefit:** Temp-high violation can alert while temp-low is suppressed (if both exist), and each resets independently.

### Alert every N days instead of once per day

Change the date comparison:

```jinja2
{% set days_since_alert = (now().date() - last_sent_dt.date()).days %}
{{ days_since_alert >= 3 }}  # Alert every 3 days
```

### Alert with grace window before sending

Use a timer (separate from datetime gating) to delay alert for N minutes, allowing brief violations to self-resolve:

```yaml
- alias: Start grace window when violation detected
  if:
    - condition: template
      value_template: "{{ violation_state == 'active' }}"
  then:
    - action: timer.start
      target:
        entity_id: timer.violation_grace_window
      data:
        duration: "00:05:00"

- alias: Send alert if grace window expired and still violated
  if:
    - condition: trigger
      id: timer_expired
    - condition: template
      value_template: "{{ violation_state == 'active' }}"
  then:
    # ... gating logic + send alert ...
```

---

## Real-World Examples

- **Wine Fridge Monitoring** — Temperature/humidity/offline alerts, once per day per violation type, resolve/re-alert same day
- **Battery Alerts** — Low battery warnings, once per day, clear when battery recovers
- **Maintenance Reminders** — Filter replacement due dates, once per day until action taken
- **Oven Alerts** — Running too long warnings, once per N hours (variation on pattern)

---

## Testing & Validation

**In Developer Tools → Templates:**

```jinja2
# Test null case (first alert)
{% set last_sent = '' %}
{% set last_sent_dt = as_datetime(last_sent, none) %}
{% set is_null_or_old = last_sent in ['unavailable', 'unknown', ''] or (last_sent_dt is not none and last_sent_dt.date() < now().date()) %}
{{ is_null_or_old }}
# Expected: True (should alert)

# Test today's date (already alerted)
{% set last_sent = '2025-12-10 10:00:00' %}
{% set last_sent_dt = as_datetime(last_sent, none) %}
{% set is_null_or_old = last_sent in ['unavailable', 'unknown', ''] or (last_sent_dt is not none and last_sent_dt.date() < now().date()) %}
{{ is_null_or_old }}
# Expected: False (should NOT alert)

# Test yesterday's date (next calendar day)
{% set last_sent = '2025-12-09 10:00:00' %}
{% set last_sent_dt = as_datetime(last_sent, none) %}
{% set is_null_or_old = last_sent in ['unavailable', 'unknown', ''] or (last_sent_dt is not none and last_sent_dt.date() < now().date()) %}
{{ is_null_or_old }}
# Expected: True (should alert again)
```

---

## Gotchas & Troubleshooting

**Gotcha 1:** Automation doesn't re-alert after violation clears and recurs
- **Cause:** Missing "clear timestamp on resolve" logic
- **Fix:** Add the else branch that sets datetime to null

**Gotcha 2:** `as_datetime(null, none)` crashes automation
- **Cause:** Not guarding with `is not none` before calling `.date()`
- **Fix:** Use the pattern from section 2 above

**Gotcha 3:** Timestamp format mismatch when parsing
- **Cause:** Using `isoformat()` which includes timezone/microseconds
- **Fix:** Use `strftime('%Y-%m-%d %H:%M:%S')`

**Gotcha 4:** Alert fires multiple times on same day
- **Cause:** Trigger fires multiple times but datetime check doesn't gate properly
- **Fix:** Ensure `last_sent in ['unavailable', 'unknown', '']` is first condition (fast-fail)

---

## Related Patterns

- **Restart Resilience** — Ensures datetime helpers survive HA restart
- **Safe Jinja** — Proper filtering and error handling for `as_datetime()` calls
- **Idempotent Actions** — Setting datetime multiple times is safe (write-only)

---

_Last updated: 2026-01-27
