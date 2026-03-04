# Runtime & Versioning Policy

- **HA Core floor**: target the latest release **minus ~1 month** (e.g., if latest is 2026.2, support ≥2026.1). Avoid features newer than the floor without explicitly confirming the running HA version.

- **Python**: use the version bundled with HA Core; avoid pinning external interpreters.

- **Add-ons**: AppDaemon, MQTT, and Python Scripts allowed when isolated. Any required integrations must be documented in YAML comments.

- **Restart behavior**: expect graceful restarts. Gate all non-trivial work (anything that makes decisions, allocates resources, or triggers actions) on `timer.ha_startup_delay → idle` with trigger-level `for:`.

- **Validation**: PR should state "Verified on HA <version> (≥ floor)" in the YAML description or adjacent comments.

## Refactor & Upgrade Policy

Any refactor or enhancement MUST include a review of Home Assistant release notes from the **last 12 months up to and including the current release**. Proactively adapt code for **backward-incompatible (breaking)** schema, attribute, service, or behavior changes affecting the **artifacts being authored, modified, or reviewed**.

The **reviewer or developer** must confirm the outcome in their **summary** (not in automation/script artifacts or changelogs) as:
- `BC review: done`
- `BC review: N/A`

> ⚠️ Never copy syntax, examples, or patterns from external sources without first confirming they are valid against the current HA Core version. Model training data lags — official HA documentation is the authoritative source.

## Attribute Size Limit (16,384 Bytes)

HA's recorder silently drops the entire attribute blob for an entity if
its serialized JSON exceeds 16,384 bytes. No error is raised and the
entity appears healthy in memory — the data is simply not written to the
DB. After restart, attributes are gone.

**Risk pattern**: trigger-based template sensors that accumulate state
via dict-merge (`dict(current, **new)`).

**Guard before committing**:
```jinja
{% set proposed = dict(current, **new) %}
{{ current if proposed | tojson | length > 16384 else proposed }}
```

Pair with a `logbook.log` or `persistent_notification` in the action
block so the caller knows the write was rejected.

- The 16,384-byte limit applies to the **total serialized JSON of all
  attributes** on the entity, not just one key.
- State value has a separate 255-character limit.
- `remove_variable` / `clear_variables` branches always reduce size —
  no guard needed on those paths.
