# Runtime & Versioning Policy

- **HA Core floor**: target the latest release **minus ~1 month** (e.g., if latest is 2025.12, support ≥2025.11). Avoid features newer than the floor without explicitly confirming the running HA version.

- **Python**: use the version bundled with HA Core; avoid pinning external interpreters.

- **Add-ons**: AppDaemon, MQTT, and Python Scripts allowed when isolated. Any required integrations must be documented in YAML comments.

- **Restart behavior**: expect graceful restarts. Gate all non-trivial work (anything that makes decisions, allocates resources, or triggers actions) on `timer.ha_startup_delay → idle` with trigger-level `for:`.

- **Validation**: PR should state "Verified on HA <version> (≥ floor)" in the YAML description or adjacent comments.

## Refactor & Upgrade Policy

Any refactor or enhancement must include a review of Home Assistant Release Notes from the **last 12 months up to and including the current release**. Proactively adapt code for breaking schema, attribute, or behavior changes discovered.

Document the review outcome as:
- `Release notes review: done`
- `Release notes review: N/A`

Include this in PR notes or YAML comments.

> ⚠️ Confirm that any copied examples or external references match the current HA Core version.
