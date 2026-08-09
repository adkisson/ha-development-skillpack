# Debugging Cookbook

Quick-reference card for HA debugging tools and techniques.
For the full debugging methodology, see `workflows/debug.md`.
For DTT validation patterns, see `cookbooks/dtt_techniques.md`.

---

## Tabs & Tools

- **DTT** (Developer Tools → Templates): first stop for all logic
  failures — templates, conditions, computed values. See
  `guides/dtt_first_validation.md` for the full validation cycle.
- **Automation Traces**: orchestration only — trigger firing,
  condition sequence, action execution. See
  `workflows/debug.md` for when and how to use traces versus DTT.
- **Logbook / History**: first move for intermittent failures —
  check entity state history over the failure window before
  attempting reproduction. See `workflows/debug.md`
  for guidance on matching evidence to failure surface.
- **Configuration → YAML editor**: review raw automation, script,
  and template sensor structure without the GUI abstracting it.

---

## Techniques

### Template sensors

- Add an inline `reason` attribute to surface human-readable
  diagnosis for complex logic:
  ```yaml
  reason: >-
    {% if not has_value('sensor.foo') %}no_data
    {% elif ... %}...
    {% endif %}
  ```
- Keep `#debug_*` attributes in template sensors commented out
  in production. Enable by uncommenting when diagnosis is needed;
  re-comment when done. Never delete them — they are free to carry
  and invaluable when a sensor behaves unexpectedly later.
  ```yaml
  # debug_raw_value: "{{ states('sensor.foo') }}"
  # debug_tier: "{{ tier }}"
  ```

### Isolation

- Validate one room, area, or fixture at a time. Binary isolation
  narrows logic failures faster than end-to-end testing.
- For multi-sensor logic, mock individual inputs using
  `{% set %}` variables in DTT to isolate which input is
  producing the unexpected result. See `cookbooks/dtt_techniques.md`
  for mock variable patterns.
- Do not rely solely on current live state — validate degraded
  and edge cases using mock variables in DTT before concluding
  the logic is correct.

### Rollback

- Keep timestamped YAML copies or version control commits before
  modifying complex automations or template sensors. Enables quick
  bisect when a fix introduces a regression.
