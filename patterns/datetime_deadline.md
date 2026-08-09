# Datetime Deadline Pattern

## TL;DR

* Use `input_datetime` (date + time) as the **canonical deferred-intent primitive**
* Store an **absolute deadline**, not a countdown
* Use sentinel `2999-01-01 00:00:00` for inactive state
* Evaluate via: `now() >= deadline`
* Always **clear or re-arm** after consuming
* Design for **idempotent execution**
* Declare an explicit **overdue policy in `description:`**
* Use `timer` only for:

  * countdown UX
  * cancelable grace windows
  * protective cooldowns

---

## Purpose

Define the canonical method for representing deferred one-shot intent using a persisted, inspectable, and restart-safe model.

This pattern standardizes:

* how deadlines are stored
* how they are evaluated
* how they are consumed
* how they behave across restart and failure

---

## Core Principle

Use `input_datetime` (date + time) as the **source of truth for deferred intent**.

The stored value represents:

> “This action is intended to occur at this exact moment in time.”

This is a **deadline**, not a countdown.

---

## When to Use

Use this pattern when:

* the system needs to remember a future action across restart
* the action represents a durable intent (not a transient process)
* logic can be expressed via comparison with `now()`

---

## When NOT to Use

Do not use this pattern when the system is modeling a **live countdown**.

Use `timer` instead for:

* countdown UX (remaining time, pause/resume/cancel)
* cancelable grace windows
* protective cooldowns (e.g., compressor lockout, API lockout)

---

## Required Configuration

### Datetime Helper

* MUST use `input_datetime`
* MUST include both date and time:

  * `has_date: true`
  * `has_time: true`

Time-only helpers are not valid for this pattern.

---

## Sentinel Value

### Canonical inactive value

```yaml
2999-01-01 00:00:00
```

### Rules

* Represents **inactive / unscheduled**
* MUST NOT be used for real scheduling
* MUST be used instead of null/blank values
* MUST be used consistently across all implementations

### Rationale

* Not realistically schedulable
* Resistant to fat-finger errors
* Avoids boundary conditions (e.g., `9999`)
* Safe across HA, Python datetime, and database usage

---

## Canonical Semantics

All logic MUST use these definitions:

* **inactive**

  ```
  deadline == sentinel
  ```

* **active**

  ```
  deadline != sentinel
  ```

* **due**

  ```
  active AND now() >= deadline
  ```

No alternate interpretations are allowed.

---

## Canonical Semantics Template

Use `as_timestamp()` for all deadline comparisons. Direct object comparison
between `as_datetime()` output and `now()` raises a `TypeError` at runtime
because `as_datetime()` on a bare string produces an offset-naive datetime
while `now()` is offset-aware. This is a silent production failure — no
YAML-level warning.

**Correct pattern (timestamp-based):**

\```jinja
{% set sentinel_ts = as_timestamp(as_datetime('2999-01-01 00:00:00')) | float(0) %}
{% set deadline_ts = as_timestamp(as_datetime(
     states('input_datetime.pool_pump_override_deadline'),
     as_datetime('2999-01-01 00:00:00'))) | float(0) %}
{% set now_ts = as_timestamp(now()) | float(0) %}
{% set active = deadline_ts != sentinel_ts %}
{% set due = active and now_ts >= deadline_ts %}

active={{ active }}
due={{ due }}
\```

**Do NOT use object comparison — this raises TypeError at runtime:**

\```jinja
{# WRONG — raises TypeError: can't compare offset-naive and offset-aware datetimes #}
{% set deadline = as_datetime(deadline_str, as_datetime('2999-01-01 00:00:00')) %}
{% set active = deadline != as_datetime('2999-01-01 00:00:00') %}
{% set due = active and now() >= deadline %}
\```

Interpretation:

* inactive = `deadline_ts == sentinel_ts`
* active = `deadline_ts != sentinel_ts`
* due = `active and now_ts >= deadline_ts`

Unparseable or unavailable values fall back to sentinel via the `as_datetime()`
default argument, producing `deadline_ts == sentinel_ts` → inactive.

Use real entity IDs in production code. Avoid alternate semantics.

---

## Consume Rule

Any automation or script that acts because of the deadline MUST:

* clear the deadline to the sentinel, OR
* re-arm it with a new valid datetime

This applies to:

* time-based triggers
* restart recovery
* manual execution paths

Failure to do this results in stale or repeated execution.

---

## Canonical Consume Actions

### Clear to inactive sentinel

```yaml
- action: input_datetime.set_datetime
  target:
    entity_id: input_datetime.pool_pump_override_deadline
  data:
    datetime: "2999-01-01 00:00:00"
```

### Re-arm to a new deadline

```yaml
- action: input_datetime.set_datetime
  target:
    entity_id: input_datetime.pool_pump_override_deadline
  data:
    datetime: "{{ (now() + timedelta(minutes=30)).strftime('%Y-%m-%d %H:%M:%S') }}"
```

Rules:

* consume paths MUST clear to sentinel or re-arm
* do not use null, blank, or empty-string clearing
* use full datetime format only
* route writes through the named owner

---

## Execution Model

### Idempotent Execution (REQUIRED)

All deadline-driven automations MUST be safe to execute more than once.

Reason:

* Home Assistant commonly uses `continue_on_error: true`
* success/failure cannot be reliably enforced in YAML
* clearing based on success is not robust

### Rule

Execution MUST be:

* inherently idempotent, OR
* guarded such that repeated execution is safe

---

## Overdue Policy

Each implementation MUST declare its overdue behavior in `description:`.

### Requirements

* MUST be explicitly stated in `description:`
* MUST select one of the allowed policies
* MUST be reviewable as written

### Allowed policies

* execute immediately if overdue
* execute only within a defined staleness window
* skip and clear if stale
* escalate / notify instead of executing

No implicit overdue behavior is allowed.

---

## Restart Reconciliation

Systems using this pattern MUST implement startup reconciliation.

On restart:

* evaluate all active deadlines
* determine if due
* apply overdue policy
* ignore sentinel values

This ensures no work is silently missed.

See: `patterns/restart_resilience.md` for canonical restart sequencing and implementation guidance.

---

## Ownership Rule

Each deadline helper MUST have exactly one writer of record.

### Requirements

* Owner MUST be named in `description:`

Example:

```yaml
Owner: automation.pool_pump_override
```

* Only the owner may write the helper directly
* Other automations/scripts MUST route changes through the owner

This prevents multi-writer race conditions and ambiguity.

---

## DST Handling

Do not schedule fixed wall-clock deadlines during DST transition windows:

* 01:00–03:00 local time on transition days

Prefer:

```jinja
now() + duration
```

Do NOT attempt to use UTC/Z time with `input_datetime`.

---

## Dashboard / UI Rule

Sentinel-backed datetime helpers SHOULD NOT be exposed directly in dashboards.

If user-facing visibility is required:

* use derived/template sensors
* present meaningful states (e.g., “inactive”, “scheduled”)
