# Integration Degradation

**Principle**: Sensors depending on external integrations (cloud APIs, network devices, battery-constrained hardware) must degrade gracefully. Unavailability or staleness of upstream data should not cascade to downstream sensors or automations.

## Pattern

### Source Priority with Proxies
When primary source unavailable, cascade to proxy witnesses before zero defaults.

**Tier 1 (authoritative)**: Primary source (cloud API, official integration)  
**Tier 2 (proxy witness)**: Inferred from related local data (charging cable, power draw, presence sensor)  
**Tier 3 (safe default)**: Zero or safe fallback value

**Example**:
```jinja
# ✅ Cascading sources with proxy fallback
device_location: >
  {% if has_value('sensor.primary_location_api') and not is_stale %}
    {{ states('sensor.primary_location_api') }}
  {% elif has_value('binary_sensor.local_proxy_witness') %}
    {# Proxy: if local witness present, device is at home #}
    {# Note: proxy is coarse-grained (home/away only, not exact location) #}
    home
  {% else %}
    unknown
  {% endif %}
```

**Critical caveat**: Proxies must be *conservative* (only assert states strongly supported). Never fabricate precision values (exact locations, SOC percentages) via proxy—only coarse states like "home/away", "charging/not charging", "present/absent". Mark proxy-derived values in `reasoning`.

### Staleness as First-Class Failure Mode
Data can be *present but stale*—cloud APIs sleeping, rate limits, delayed polling. Don't just check `has_value`; check age.

```jinja
# Extract and age-check primary source
{% set as_of = state_attr('sensor.primary_external_source', 'last_update') %}
{% set as_of_dt = as_of | as_datetime | default(none) %}
{% set age_s = (as_timestamp(now()) - as_timestamp(as_of_dt)) | int(999999) if as_of_dt else 999999 %}
{% set stale_threshold_s = 300 %}  # 5 minutes
{% set is_stale = age_s > stale_threshold_s %}

# Use primary only if fresh AND present
{% if has_value('sensor.primary_external_source') and not is_stale %}
  {{ states('sensor.primary_external_source') }}
{% elif ... proxy ...
{% endif %}
```

Include age in state calculation: treat `is_stale=true` the same as "primary unavailable" (promote to proxy/default).

### Loose Availability Gates
Gate on truly critical inputs only; allow optional sources to fail silently. **Strongly prefer keeping sensor available with degraded `data_quality` over setting `availability: unavailable`**, which cascades failure.

**Anti-pattern** (AND-based cascades):
```jinja
availability: >
  {{ has_value('sensor.external_api_data') and has_value('sensor.external_api_status') }}
```
One upstream failure → entire sensor unavailable → cascades to all downstream consumers.

**Good pattern** (OR-based, loose; sensor stays available):
```jinja
availability: >
  {{ has_value('sensor.primary_energy_source') or has_value('sensor.proxy_witness') or true }}
  {# Always available; state + data_quality convey degradation #}
```

Better yet: **only set `availability: unavailable` if the sensor itself cannot be computed at all** (rare). Keep the sensor available, downgrade `data_quality`, and let downstream logic decide whether to trust the result.

### Safe Defaults
Always default external reads to safe values when all sources exhausted.

```jinja
# ✅ Good
soc: "{{ states('sensor.battery_level') | float(0) if has_value('sensor.battery_level') else 0 }}"

# ❌ Bad
soc: "{{ states('sensor.battery_level') | float }}"  # Fails on None
```

For JSON attributes (arrays/dicts):
```jinja
# ✅ Good: safe decode with fallback, no string slicing
{% set v = state_attr('sensor.allocator', 'zones') %}
{% if v is string %}
  {# If it's a JSON string, parse it; from_json handles errors gracefully #}
  {{ v | from_json(default=[]) }}
{% else %}
  {# If already a list/dict, use as-is #}
  {{ v | default([], true) }}
{% endif %}

# ❌ Bad: slicing corrupts JSON
{{ (v | trim)[1:-1] | from_json ... }}  {# Strips '[' and ']', breaking the parse #}
```

### Expose Degradation State (Machine-Readable)
Include attributes that explain *why* behavior changed and which tier is active.

```jinja
active_tier: >
  {% if has_value('sensor.primary_external_source') and not is_stale %}
    primary
  {% elif has_value('binary_sensor.local_proxy_witness') %}
    proxy
  {% else %}
    default
  {% endif %}

source_entity: >
  {% if active_tier == 'primary' %}
    sensor.primary_external_source
  {% elif active_tier == 'proxy' %}
    binary_sensor.local_proxy_witness
  {% else %}
    (safe_default)
  {% endif %}

age_s: "{{ age_s | int(999999) }}"

is_stale: "{{ is_stale }}"

data_quality: >
  {% if has_value('sensor.primary_external_source') and not is_stale %}
    fully_operational
  {% elif is_stale %}
    degraded_stale_primary
  {% elif has_value('binary_sensor.local_proxy_witness') %}
    degraded_using_proxy_witness
  {% else %}
    degraded_safe_default
  {% endif %}

reasoning: >
  {% if data_quality == 'fully_operational' %}
    Primary source operational (age: {{ age_s }}s)
  {% elif data_quality == 'degraded_stale_primary' %}
    ⚠️ Primary API present but stale (age: {{ age_s }}s); using cached value
  {% elif data_quality == 'degraded_using_proxy_witness' %}
    ⚠️ Primary API unavailable; using proxy witness (coarse-grained only)
  {% elif data_quality == 'degraded_safe_default' %}
    ⚠️ Primary and proxy unavailable; using safe default
  {% else %}
    ❌ No sources available
  {% endif %}
```

### Hysteresis: Prevent Tier Flapping
Without delays, sources flap between tiers during intermittent outages. Add promotion/demotion delays:

```yaml
trigger:
  - platform: state
    entity_id: sensor.primary_external_source
    to: unavailable
    for: "00:00:05"  # Don't degrade until primary is *really* down
id: primary_failed
```

Require primary to be good for N seconds before promoting back (via automation `for` delays on recovery triggers). Advanced: use helpers to persist tier state across HA restarts if needed.

### Distinguish State Semantics
The state itself should be meaningful. Use conventions:

* `unavailable` (HA entity state) = "integration/transport failure" (device offline, API down, token expired)
* `unknown` (state value) = "integration working but I cannot determine the value" (sensor misconfigured, data missing)
* `none` or missing attribute = "source didn't provide the field"

Include these distinctions in `data_quality` and `reasoning`.

### Downstream Compliance
Automations and consumers check `data_quality` or `active_tier` before critical actions.

**Pattern A** (by data_quality):
```yaml
condition: template
value_template: >
  {{ state_attr('sensor.my_directive', 'data_quality') in ['fully_operational', 'degraded_stale_primary', 'degraded_using_proxy_witness']
     or is_state('input_boolean.manual_override', 'on') }}
```

**Pattern B** (by active_tier, cleaner):
```yaml
condition: template
value_template: >
  {{ state_attr('sensor.my_directive', 'active_tier') in ['primary', 'proxy']
     or is_state('input_boolean.manual_override', 'on') }}
```

Manual overrides always bypass degradation checks (escape hatch).

## Use Cases
- **Cloud APIs**: Token expiration, rate limiting, maintenance windows
- **Device sleep**: Vehicles (sleep mode), battery sensors (low battery radio cutoff), door locks (RF dropout)
- **Regional APIs**: Account/region mismatch
- **Polling delays**: Stale data from slow integrations

## When to Use This Pattern

Apply defensively based on integration reliability tier:

| Integration Type | Reliability | Typical Failure Modes |
|---|---|---|
| HA-Native Helpers | Very High | HA restart only |
| Local RF (Zigbee, Z-Wave, Thread) | High | Device sleep, RF congestion, firmware quirks |
| Local IP / LAN Devices | High | Network resets, DHCP churn, Wi-Fi drops |
| Cloud APIs | Moderate–High | Auth expiration, rate limits, maintenance windows |
| Battery / Sleepy Devices | Low | Sleep modes, missed polls, firmware bugs |

**Rule**: Match availability gate strictness to integration reliability. Very high reliability allows stricter AND gates. Low reliability requires full degradation + staleness + hysteresis strategy.

## Checklist
- [ ] Availability gates on critical inputs only (OR-based, prefer sensor stays available)
- [ ] Source priority defined: primary → proxy witness → safe default
- [ ] All external reads have safe defaults (`| float(0)`, `| from_json(default=[])`)
- [ ] JSON/list parsing uses safe `from_json(default=)` without string slicing
- [ ] Staleness tracked: `as_of`, `age_s`, `is_stale` attributes computed
- [ ] `data_quality` includes both unavailability AND staleness states
- [ ] `active_tier` (primary|proxy|default|none) explicitly exposed for consumers
- [ ] `source_entity` attribute shows which source is currently active
- [ ] Hysteresis/debounce applied to prevent tier flapping (via delays or helper)
- [ ] Downstream automations check `active_tier` or `data_quality` before critical actions
- [ ] Proxy values are coarse-grained only (never precise/fabricated)
- [ ] Proxy derivations marked in `reasoning` for transparency
- [ ] Manual overrides bypass degradation checks (escape hatch)

## See Also
- `/spec/safety.md` — Manual overrides always win
- `/patterns/event_driven_templates.md` — Prefer event-driven to polling
- `/cookbooks/dtt_techniques.md` — Testing with unavailable/stale entities
