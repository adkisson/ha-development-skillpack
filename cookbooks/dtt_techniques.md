# Developer Tools Template (DTT) Techniques

## The standard: monolithic probe, single paste

Every DTT validation session produces one probe covering all
concerns for the artifact. Run it as a single paste. This is not
a preference — it is the required approach.

Fragmented validation (one query per variable, one query per
branch) is a failure mode. It hides interaction failures, produces
false confidence, and leaves the real decision path untested.
The only valid reason to split a probe is a technical constraint
that prevents combination — not convenience, not readability.

The sections below describe how to build a complete monolithic
probe and the techniques that go inside it.

---

## Step 1 — Entity pre-flight (separate, before the probe)

Run a dedicated pre-flight before building the main probe. One
`has_value()` call per entity used in the artifact — no exceptions:

```jinja
{# Pre-flight: validate all entities used in this artifact #}
{{ has_value('sensor.kid_s_room_temp') }}
{{ has_value('binary_sensor.front_door') }}
{{ has_value('input_boolean.guest_mode') }}
```

All lines should return `true` under normal operating conditions.
If any return `false`, determine whether this reflects a naming
issue or a valid transient state before proceeding.

If a naming issue is suspected, attempt discovery before stopping:

```jinja
{# Surface candidates by area, label, or integration #}
{{ area_entities('Kid\'s Room') | list }}
{{ label_entities('climate') | list }}
{{ integration_entities('zwave_js') | list }}
```

If discovery surfaces the correct name, update and re-run.
If not, stop and request the validated name — do not guess.

Pre-flight is a separate paste that runs before the main probe.
It is not a section inside the probe.

See `guides/dtt_first_validation.md` for the full entity validation
doctrine including usable-state vs. existence distinction.

---

## Step 2 — Build the monolithic probe

After pre-flight passes, build one probe covering all logic in the
artifact. Structure it in labeled sections, run the whole block as
a single paste.

**Build the probe from the artifact, not from memory.** Extract
entity lists, trigger IDs, variable names, and branch conditions
directly from the YAML. This is what guarantees complete coverage —
a probe reconstructed from memory will miss entities, skip branches,
and use subtly different names. If the artifact has 12 entities,
the probe has 12 entity checks.

Each section should have:
- A comment header stating what is being validated
- An inline expected-output annotation
- A deterministic PASS/FAIL signal where the output is known

**Standard section order:**
1. Entity reference check (defined-entity confirmation, after pre-flight)
2. Live states (informational — what are sensors reading right now)
3. Name/mapping validation with PASS assertions
4. Scenario setup (mock variables — see technique below)
5. Per-branch logic validation
6. Gate/condition checks
7. Adversarial probes (last — see technique below)

```jinja
{# ============================================================ #}
{# DTT Validation — My Automation                               #}
{# Run as a single paste after pre-flight passes.               #}
{# ============================================================ #}

{# --- SECTION 1: Entity reference check                       #}
{# Confirms entities are defined. Pre-flight has_value() is    #}
{# still mandatory before this probe — this is not a repeat.   #}
ENTITY REFERENCES:
sensor.foo defined:        {{ states.sensor.foo is not none }}
binary_sensor.bar defined: {{ states.binary_sensor.bar is not none }}

{# --- SECTION 2: Live states — informational                  #}
CURRENT STATES (foo should be numeric, bar should be off):
foo: {{ states('sensor.foo') }}
bar: {{ states('binary_sensor.bar') }}

{# --- SECTION 3: Name mapping — all PASS lines should be True #}
NAME MAPPING:
{% set mock_entity = 'sensor.foo' %}
{% if mock_entity == 'sensor.foo' %}{% set result = 'Foo Device' %}
{% else %}{% set result = 'Unknown' %}{% endif %}
{{ mock_entity }}: {{ result }} — PASS: {{ result == 'Foo Device' }}

{# --- SECTION 4: Logic branch — condition A                   #}
{# Expected: result_a when foo > 50                            #}
BRANCH A (foo=60, expected result_a):
{% set mock_foo = 60 %}
{% if mock_foo > 50 %}result_a{% else %}result_b{% endif %}

{# --- SECTION 5: Gate condition                               #}
{# Expected: true under normal operation                       #}
ALL-CLEAR GATE:
{{ not is_state('binary_sensor.bar', 'on') }}

{# --- SECTION 6: Adversarial — string-truthy check            #}
{# Expected: BROKEN if-result shows TRUTHY — BUG when co=false #}
{% set detector_name = 'Foo' %}
{% set smoke = true %}
{% set co = false %}
{% set both_on %}
  {% if detector_name == 'Foo' %}{{ smoke and co }}{% endif %}
{% endset %}
both_on raw: "{{ both_on }}"
BROKEN if-result: {% if both_on %}TRUTHY — BUG{% else %}FALSY — correct{% endif %}
```

---

## When a section fails: surgical correction, not full rebuild

Fix only what broke — do not rebuild the entire probe. Identify
whether the failure is a probe bug or an artifact bug. If the
probe was wrong, fix the section and re-run. If the artifact has
a bug, fix the artifact first, then update the probe to match,
then re-run. A section failure that exposes an artifact bug is a
success — fix the artifact, update the probe, confirm corrected
behavior, then deploy.

---

## Technique: Scenario-driven mock variables

When logic depends on conditions that cannot be forced live —
time of day, outside temperature, solar production at night,
extreme values — define a named scenario block near the top of
the probe (after entity checks, before logic sections). Change one
variable to switch the entire probe to a different test case.

Two patterns:

### Pattern A — Single active_scenario switcher

Use when scenarios are parallel: same logic, different inputs.
Change `active_scenario` at the top, re-run, different case.

```jinja
{# ============================================================ #}
{# SCENARIO UNDER TEST — change this value to switch test case  #}
{# Options: normal | hot_day | night | startup | all_unavailable #}
{% set active_scenario = 'hot_day' %}
{# ============================================================ #}

{% if active_scenario == 'normal' %}
  {% set mock_outside_temp = 72 %}
  {% set mock_forecast_high = 85 %}
  {% set mock_hour = 14 %}
  {% set mock_solar_w = 3200 %}
{% elif active_scenario == 'hot_day' %}
  {% set mock_outside_temp = 102 %}
  {% set mock_forecast_high = 108 %}
  {% set mock_hour = 15 %}
  {% set mock_solar_w = 4100 %}
{% elif active_scenario == 'night' %}
  {% set mock_outside_temp = 78 %}
  {% set mock_forecast_high = 95 %}
  {% set mock_hour = 2 %}
  {% set mock_solar_w = 0 %}
{% elif active_scenario == 'startup' %}
  {% set mock_outside_temp = 'unavailable' %}
  {% set mock_forecast_high = 'unavailable' %}
  {% set mock_hour = 8 %}
  {% set mock_solar_w = 'unavailable' %}
{% elif active_scenario == 'all_unavailable' %}
  {% set mock_outside_temp = 'unavailable' %}
  {% set mock_forecast_high = 'unavailable' %}
  {% set mock_hour = 12 %}
  {% set mock_solar_w = 'unavailable' %}
{% endif %}

{# --- SECTION: Active scenario summary                        #}
SCENARIO: {{ active_scenario }}
outside_temp: {{ mock_outside_temp }}
forecast_high: {{ mock_forecast_high }}
hour: {{ mock_hour }}
solar_w: {{ mock_solar_w }}

{# --- SECTION: Decision logic under test                      #}
{# Expected for hot_day: must_run                              #}
directive: {% if mock_outside_temp == 'unavailable' %}degraded
{% elif mock_outside_temp | float(0) >= 85 or mock_forecast_high | float(0) >= 95 %}must_run
{% elif mock_outside_temp | float(0) >= 78 %}comfort
{% else %}eco{% endif %}
```

### Pattern B — Per-section mock block

Use when scenarios are structurally different: different logic
paths, different variables in play. Each section declares its own
mocks inline.

```jinja
{# --- SECTION 4: smoke only — expected: one smoke line        #}
{# Case: Living Room smoke=true, CO=false                      #}
{% set mock_detector = 'Living Room Smoke Detector' %}
{% set mock_smoke = true %}
{% set mock_co = false %}
...logic using mock_detector, mock_smoke, mock_co...

{# --- SECTION 5: CO only — expected: one CO line              #}
{# Case: Garage CO=true, smoke=false                           #}
{% set mock_detector = 'Garage Smoke Detector' %}
{% set mock_smoke = false %}
{% set mock_co = true %}
...same logic block, different inputs...
```

Both patterns may appear in the same probe: Pattern A at the top
for the main decision tree, Pattern B in later sections for
isolated branch validation.

Mock variables are for DTT only — never ship `{% set mock_* %}`
in production artifacts.

---

## Technique: Adversarial sections

Always add adversarial sections for known Jinja footguns. These
go last in the probe and specifically probe failure modes that
happy-path validation cannot catch.

Adversarial sections serve two purposes: they validate that the
probe logic is sound, and they can expose bugs in the artifact
itself that pre-existing logic carried forward undetected. A
passing happy-path probe on broken logic is the worst outcome —
the adversarial section is what prevents it. When an adversarial
section confirms a bug in the artifact, fix the artifact first,
then update the probe to reflect the corrected logic.

### String-rendered boolean (most common footgun)

Jinja renders multi-line `if/elif` blocks as strings. Any
non-empty string — including `"  False  "` — is truthy.

```jinja
{# BROKEN — both_on is the string "  False  ", always truthy   #}
both_on: |-
  {% if detector_name == 'Foo' %}{{ smoke and co }}{% endif %}
...
{% if both_on %}...combined message...{% endif %}
```

Probe:

```jinja
{# --- SECTION N: string-truthy probe                          #}
{# Expected: raw renders "False"; IF check incorrectly passes  #}
{% set detector_name = 'Foo' %}
{% set smoke = true %}
{% set co = false %}

{% set both_on %}
  {% if detector_name == 'Foo' %}{{ smoke and co }}{% endif %}
{% endset %}

both_on raw: "{{ both_on }}"
both_on trimmed: "{{ both_on | trim }}"
BROKEN if-result: {% if both_on %}TRUTHY{% else %}FALSY{% endif %}
BUG CONFIRMED: {{ both_on and both_on | trim | lower == 'false' }}
```

If `BROKEN if-result` renders `TRUTHY` when smoke=true/co=false,
the variable is a string. Fix: evaluate the boolean inline.

```jinja
{# FIXED — inline boolean, no string intermediary              #}
{%- set both_on = (detector_name == 'Foo' and smoke and co) -%}
{% if both_on %}...{% endif %}
```

### Other adversarial probes to add when warranted

- Float/int coercion: confirm `| float(none) is not none` guards
  work when a sensor emits a string like `"unavailable"`
- Empty string gate: confirm `| trim != ''` catches blank-string
  sensor states that `has_value()` would pass
- Namespace scope: confirm a `namespace()` variable mutated inside
  a loop is visible outside it

---

## Technique: Mock variables for state simulation

Use `{% set %}` variables to simulate entity states that are not
currently live — unavailable sensors, startup conditions, degraded
integrations, extreme values like night-time solar or peak heat.

```jinja
{# Simulate: primary unavailable, proxy available #}
{% set mock_temp = 'unavailable' %}
{% set mock_fallback = '72.5' %}

Result: {{ mock_fallback | float(0) if mock_temp == 'unavailable' else mock_temp | float(0) }}
Safe default applied: {{ mock_temp == 'unavailable' }}
```

---

## Reference snippets

Quick-reference patterns for use inside probes.

### Inspect basics

```jinja
{{ states('sensor.power') | float(0) }}
{{ state_attr('light.kitchen','brightness') | int(0) }}
```

### Check availability & normalize

```jinja
{% set ok = has_value('sensor.foo') %}
{% set cond = states('sensor.condition') | lower | trim %}
```

### Package debug JSON

```jinja
{{ {
  'export_w': states('sensor.solar_export_3m_avg') | float(0),
  'buy': states('sensor.energy_buy_rate') | float(0)
} | tojson }}
```

### Unavailable/degraded entity test

```jinja
{# Test: primary API down, proxy available #}
{% set mock_primary = 'unavailable' %}
{% set mock_proxy = 'on' %}
{% set mock_age_s = 450 %}
{% set is_stale = mock_age_s > 300 %}

Primary available: {{ mock_primary != 'unavailable' }}
Is stale: {{ is_stale }}
Active tier: {% if mock_primary != 'unavailable' and not is_stale %}primary{% elif mock_proxy in ['on', true] %}proxy{% else %}default{% endif %}
Safe default: {{ 0 if mock_primary == 'unavailable' else 42 }}
Data quality: {% if mock_primary != 'unavailable' and not is_stale %}fully_operational{% elif is_stale %}degraded_stale{% elif mock_proxy in ['on', true] %}degraded_proxy{% else %}no_data{% endif %}
```

Run one probe per scenario (primary only, primary+stale,
primary+proxy, all down). Verify state, `data_quality`, and safe
defaults together.

---

## Avoid Python methods (use Jinja filters instead)

**`.items()`** → use `dict2items` filter:

```jinja
{% for p in (d | dict2items) %}{{ p.key }}={{ p.value }}{% endfor %}
```

**`.get(key, default)`** → use bracket access with `default` filter:

```jinja
{% set val = d['temperature'] | default(72, true) %}
```

Or for HA attributes:

```jinja
{% set val = state_attr('sensor.payload', 'temperature') | default(72, true) %}
```

**`.split(sep)`** → use `split()` filter:

```jinja
{% set parts = states('sensor.csv_data') | split(',') %}
{{ parts[0] if (parts | length) > 0 else '' }},
{{ parts[1] if (parts | length) > 1 else '' }}
```

**`.append(item)`** → use `namespace()` for loop-scoped
accumulation. Bare list reassignment does not propagate out of a
loop scope — the outer variable is unchanged. Always use
`namespace()` when accumulating inside a loop:

```jinja
{% set ns = namespace(items=[]) %}
{% for x in things %}
  {% set ns.items = ns.items + [x] %}
{% endfor %}
{{ ns.items | join(', ') }}
```

Outside loops, bare reassignment is fine:

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

---

## Time math (safe)

```jinja
{% set lc = states['sensor.foo'].last_changed if states['sensor.foo'] is not none else none %}
{% set age = (as_timestamp(now()) - as_timestamp(lc)) if lc else none %}
```
