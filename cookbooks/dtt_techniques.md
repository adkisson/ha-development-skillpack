# Developer Tools Template (DTT) Techniques

## Batch queries for efficiency
Query multiple related values in a single DTT submission instead of atomic tests. Reduces context-switching and lets you verify interactions in one shot.

**Good** (one query, all related outputs):
```jinja
{# Validate: sources, tiers, safe defaults, and state outcome together #}
Primary: {{ states('sensor.api_data') }}, Proxy: {{ has_value('binary_sensor.local_witness') }}
Tier: {% if states('sensor.api_data') != 'unavailable' %}primary{% elif has_value('binary_sensor.local_witness') %}proxy{% else %}default{% endif %}
Safe value: {{ states('sensor.api_data') | float(0) if states('sensor.api_data') != 'unavailable' else 0 }}
{{ { 'all_checks': true, 'ready_for_deploy': true } | tojson }}
```

**Bad** (atomic tests, context lost):
```
Query 1: {{ states('sensor.api_data') }}
Query 2: {{ has_value('binary_sensor.local_witness') }}
Query 3: {{ states('sensor.api_data') | float(0) }}
```

## Inspect basics
```jinja
{{ states('sensor.power') | float(0) }}
{{ state_attr('light.kitchen','brightness') | int(0) }}
```

## Check availability & normalize
```jinja
{% set ok = has_value('sensor.foo') %}
{% set cond = states('sensor.condition') | lower | trim %}
```

## Validate entity names (catch typos, including apostrophe-to-underscore confusion)
**Background**: Home Assistant sanitizes entity IDs, converting apostrophes (`'`) to underscores (`_`). A user naming a sensor "kid's room" becomes `kid_s_room`, but typos like `kids_room` (missing apostrophe handling) are easy to introduce.
**Tip**: When entity names contain possessives (e.g., "kid's room"), expect HA to convert the apostrophe to underscore in the entity_id. Always validate in Developer Tools after creating entities with special characters.

```jinja
{# Example: catching both typos and apostrophe-substitution mismatches #}
{% set expected = ['light.kid_s_room_main', 'light.kid_s_room_lamp'] %}
{% set all = states | map(attribute='entity_id') | list %}
{% set missing = [] %}
{% for eid in expected %}
  {% if eid not in all %}
    {% set missing = missing + [eid] %}
  {% endif %}
{% endfor %}
Missing: {{ missing | tojson }}
{# For each missing entity, suggest close matches (handles typos, apostrophe-to-_ confusion) #}
{% for m in missing %}
  {% set base = m | replace('_','') %}
  {% set suggestions = all | select('search', base[0:6]) | list %}
  Suggest for {{ m }}: {{ suggestions[0:5] | tojson }}
{% endfor %}
```

## Package debug JSON
```jinja
{{ {
  'export_w': states('sensor.solar_export_3m_avg') | float(0),
  'buy': states('sensor.energy_buy_rate') | float(0)
} | tojson }}
```

## Avoid Python methods (use Jinja filters instead)

**`.items()`** → use `dict2items` filter:
```jinja
{% for p in (d | dict2items) %}{{ p.key }}={{ p.value }}{% endfor %}
```

**`.get(key, default)`** → use bracket access with `default` filter:
```jinja
{% set val = d['temperature'] | default(72, true) %}
```

Or for HA attributes (not dict access):
```jinja
{% set val = state_attr('sensor.payload', 'temperature') | default(72, true) %}
```

**`.split(sep)`** → use `split()` filter:
```jinja
{% set parts = states('sensor.csv_data') | split(',') %}
{{ parts[0] if (parts | length) > 0 else '' }},
{{ parts[1] if (parts | length) > 1 else '' }}
```

**`.append(item)`** → use list concatenation (reassign—lists don't mutate in place):
```jinja
{% set xs = xs + ['c'] %}
```

**`.lower()` / `.upper()`** → use filters:
```jinja
{% set s = states('sensor.foo') | lower %}
```

**`len(x)`** → use `| length` filter:
```jinja
{% if (parts | length) > 1 %}...{% endif %}
```

## Time math (safe)
```jinja
{% set lc = states['sensor.foo'].last_changed if states['sensor.foo'] is not none else none %}
{% set age = (as_timestamp(now()) - as_timestamp(lc)) if lc else none %}
```

## Testing with Unavailable/Degraded Entities
Test graceful degradation in DTT by querying your full template logic in one batch (see "Batch queries for efficiency"). Set up a mock state dict with missing/malformed data, then verify in one shot:
- Sensor stays available (doesn't cascade failure)
- `data_quality` and `reasoning` accurately reflect which tier is active
- Safe defaults applied (`| float(0)`, `| from_json(default=[])`)
- Downstream sensors still render without errors

**Example (batch query)**:
```jinja
{# Test: primary API down, proxy available; fetch all outcomes in one query #}
{% set mock_primary = 'unavailable' %}
{% set mock_proxy = 'on' %}
{% set mock_age_s = 450 %}
{% set is_stale = mock_age_s > 300 %}

Primary available: {{ mock_primary != 'unavailable' }}
Is stale: {{ is_stale }}
Active tier: {% if mock_primary != 'unavailable' and not is_stale %}primary{% elif mock_proxy in ['on', true] %}proxy{% else %}default{% endif %}
Safe default: {{ 0 if mock_primary == 'unavailable' else 42 }}
Data quality: {% if mock_primary != 'unavailable' and not is_stale %}fully_operational{% elif is_stale %}degraded_stale{% elif mock_proxy in ['on', true] %}degraded_proxy{% else %}no_data{% endif %}
{{ { 'test_matrix': ['primary_only', 'primary_stale', 'primary_proxy', 'all_down'], 'ready': true } | tojson }}
```

**Test matrix**: Run one query per scenario (primary only, primary+stale, primary+proxy, all down). Verify state, `data_quality`, and safe defaults together. DTT validates logic, not timing or race conditions—validate behavior in real runtime after logic checks pass.
