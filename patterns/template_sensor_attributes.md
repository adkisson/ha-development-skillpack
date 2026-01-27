# Template Sensor Attribute Design Patterns

## Why
Attributes explain **why** a sensor is in its current state. Keep state atomic; let attributes narrate context, support debugging, and gate downstream automations.

## Principles
- **`reason` attribute**: short, human-readable string for DTT/traces/dashboards
- **debug_* attributes**: optional intermediate calcs, typically kept commented out in production YAML for quick enablement when needed
- **Don't republish raw facts**: don't pass upstream entity state/attributes as sensor attributes unless you need a **snapshot** for auditability/consistency (e.g., decision-point values that multiple downstream actions depend on). Consumers should query source entities directly.
- **Avoid churny timestamp attributes**: don't expose `last_updated` or `last_changed`-style timestamps that update frequently and create recorder noise. Compute `age_s` for staleness detection instead. Only expose timestamps when semantically meaningful and stable (e.g., schedule boundaries, tariff effective dates, forecast valid-from times).
- **State shape**: prefer enums/simple strings over JSON blobs; complex data belongs in helpers or separate attributes

## Debug Attributes
Keep intermediate calculations as debug_* attributes, commented in production YAML. Uncomment the lines in your YAML to expose them in the sensor's attributes; then reload templates or restart HA as appropriate. Re-comment when diagnosis complete:

```jinja
attributes:
  reason: >
    {% if data_quality == 'fully_operational' %}
      Primary source active
    {% else %}
      ⚠️ Degraded or unavailable
    {% endif %}
  
  # debug_active_tier: "{{ active_tier }}"
  # debug_age_s: "{{ age_s }}"
  # debug_is_stale: "{{ is_stale }}"
  # debug_primary_available: "{{ has_value('sensor.primary_source') }}"
  # debug_proxy_available: "{{ has_value('binary_sensor.proxy_witness') }}"
```

Uncomment lines in YAML, reload templates/restart, then re-comment when done. The sensor will expose those attributes for inspection in Developer Tools or automations.

## Degradation & Observability
For sensors depending on external data sources (e.g., non-Home Assistant APIs or REST sensors), expose degradation state via attributes (see `/patterns/integration_degradation.md`).

**Pattern: `active_tier` + `data_quality` + `reasoning`**:
```jinja
attributes:
  active_tier: >
    {% if has_value('sensor.primary_source') and not is_stale %}primary
    {% elif is_state('binary_sensor.proxy_witness','on') %}proxy
    {% else %}default
    {% endif %}
  
  data_quality: >
    {% if active_tier == 'primary' and not is_stale %}fully_operational
    {% elif active_tier == 'primary' and is_stale %}degraded_stale_primary
    {% elif active_tier == 'proxy' %}degraded_using_proxy_witness
    {% else %}degraded_safe_default
    {% endif %}
  
  reasoning: >
    {% if data_quality == 'fully_operational' %}
      Primary source active (age: {{ age_s }}s)
    {% elif data_quality == 'degraded_stale_primary' %}
      ⚠️ Primary present but stale (age: {{ age_s }}s); using last known value
    {% elif data_quality == 'degraded_using_proxy_witness' %}
      ⚠️ Primary unavailable; using proxy witness (coarse-grained)
    {% else %}
      ❌ All sources unavailable; using safe default
    {% endif %}
```

**Downstream automation** reads attributes before proceeding:
```yaml
condition: template
value_template: >
  {{ state_attr('sensor.my_directive', 'active_tier') in ['primary', 'proxy']
     or is_state('input_boolean.manual_override', 'on') }}
```

## See Also
- Template integration docs: https://www.home-assistant.io/integrations/template/
- `/patterns/integration_degradation.md` — Degradation strategies
- `/cookbooks/dtt_techniques.md` — Debugging with attributes

---

_Last updated: 2026-01-27
