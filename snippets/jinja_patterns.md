# Jinja Patterns for Home Assistant -- Do / Don't

> Purpose: short, copy-paste-able idioms + **WHAT NOT TO DO** in HA
> Jinja.

------------------------------------------------------------------------

## Cheat Sheet

- **Always type states**: `states('sensor.x') | int(0)` / `| float(0)` *(or `float(none)` if 0 would be misleading)* → [Safe Reads](#safe-reads), [Nullable Attributes](#nullable-attributes--violation-flags)
- **Availability first**: `has_value('sensor.x')` *(and `| trim != ''` for REST/MQTT blanks)* → [Existence & Availability](#existence--availability)
- **Text normalization**: `| lower | trim` → [Text Normalization](#text-normalization)
- **Time math**: `as_timestamp()` / `now()`; avoid `.total_seconds()`; use `default=none` for non-timestamps → [Datetime Safety](#datetime-safety)
- **Attributes**: `state_attr('entity','attr') | default(...)` (never `states.entity.attributes...`) → [Attribute Access](#attribute-access)
- **JSON out**: `| tojson` → [JSON Packaging](#json-packaging)
- **CSV list**: `regex_findall('[^,]+') | map('trim') | map('lower') | reject('equalto','') | unique | list` → [String Operations](#string-operations-use-filters-not-python-methods)
- **Dict lookups**: prefer `'key' in d` + indexing; allow `.get()` only on literal dicts → [Dict Lookup With Defaults](#dict-lookup-with-defaults-scoped-get-guidance)
- **Iteration**: prefer `dict2items`; allow `.items()` only on literal dicts → [Keys/Values Iteration](#keysvalues-iteration)
- **Entity set iteration**: `label_entities()` / `area_entities()` / `floor_entities()` return flat **string lists** — use `expand()` before accessing `.state` or `.entity_id` → [Entity Set Iteration](#entity-set-iteration-labelareafloorfunctions)
- **No comments inside Jinja literals**: lists/dicts must contain **data only**.
  Put documentation **outside the template block** → [Comments in Jinja Literals](#comments-in-jinja-literals)

------------------------------------------------------------------------

## Safe Reads

**Do**

``` jinja
{% set v = states('sensor.power') | float(0) %}
{% set name = states('input_text.nickname') | default('unknown') %}
```

**Don't**

``` jinja
{{ states.sensor.power.state | float }}                 {# breaks if entity missing #}
{{ states('sensor.power') | float }}                    {# no default ⇒ NaN/None cascades #}
```

**Note:**\
Use `float(0)` when zero is a valid safe fallback.\
If zero would create a misleading value (e.g., false 0°F, 0%), use
`float(none)` and branch on `is none` instead (see *Nullable Attributes*
below).

------------------------------------------------------------------------

## Existence & Availability

**Do (idiomatic -- for standard HA entities)**

``` jinja
{% if has_value('sensor.foo') %}
```

**Do (conditional -- if source emits blank strings)**

``` jinja
{% if has_value('sensor.foo') and (states('sensor.foo') | trim) != '' %}
```

**Don't**

``` jinja
{% if states('sensor.foo') != 'unknown' %}
```

------------------------------------------------------------------------

## Text Normalization

**Do**

``` jinja
{% set cond = states('sensor.condition') | lower | trim %}
```

**Don't**

``` jinja
{% set cond = states('sensor.condition').lower() %}
```

------------------------------------------------------------------------

## Numbers & Math

**Do**

``` jinja
{% set a = states('sensor.a') | float(0) %}
{% set b = states('sensor.b') | float(0) %}
{{ (a - b) | round(2) }}
```

**Don't**

``` jinja
{{ float(states('sensor.a')) - float(states('sensor.b')) }}
```

------------------------------------------------------------------------

## Datetime Safety

**Do**

``` jinja
{# Parse a timestamp-like state safely (ISO, epoch, etc.) #}
{% set ts = as_timestamp(states('sensor.foo'), default=none) %}
{% set age = (as_timestamp(now()) - ts) if ts is not none else none %}
```

**Don’t**

``` jinja
{{ (now() - states.sensor.foo.last_changed).total_seconds() }}
```

**Note:**\
- `as_timestamp()` will return `none` (via `default=none`) if the state is not parseable as a timestamp (e.g., `"on"`).\
- Never access `.last_changed` via `states.sensor.x.last_changed` in templates; use supported helpers (`states()`, `state_attr()`, `as_timestamp()`) and explicit guards.


------------------------------------------------------------------------

## Numbers & Booleans from Strings

**Do**

``` jinja
{% set n = states('sensor.count') | int(0) %}
{% set on = is_state('switch.x','on') %}
```

**Don't**

``` jinja
{% if states('switch.x') == True %}
```

------------------------------------------------------------------------

## Nullable Attributes & Violation Flags

**Do**

``` jinja
{% set violation = 'high' if value > 68 else ('low' if value < 38 else none) %}
{% set temp = states('sensor.temp') | float(none) %}
```

**Don't**

``` jinja
{% set violation = 'high' if value > 68 else ('low' if value < 38 else 'null') %}
{% set temp = states('sensor.temp') | float(0) %}
```

**Why:**\
Return Jinja `none` when a value is truly unavailable. This allows safe
downstream checks like `temp is none`.\
Use `float(none)` when zero would create a false reading. Use `float(0)`
only when zero is a legitimate safe fallback.

------------------------------------------------------------------------

## Attribute Access

**Do**

``` jinja
{% set br = state_attr('light.kitchen','brightness') | int(0) %}
```

**Don't**

``` jinja
{{ states.light.kitchen.attributes.brightness }}
```

------------------------------------------------------------------------

## JSON Packaging

**Do**

``` jinja
{{ {'items': items, 'reason': reason} | tojson }}
```

**Don't**

``` jinja
{{ {'items': items, 'reason': reason} }}
```

------------------------------------------------------------------------

## Dict Lookup With Defaults (Scoped `.get()` Guidance)

**Do**

``` jinja
{% set d = states('sensor.payload') | from_json | default({}) %}
{% set val = d['key'] if 'key' in d else 0 %}
```

**Pragmatic Allowance**

``` jinja
{% set d = {'a': 1, 'b': 2} %}
{{ d.get('a', 0) }}
```

**Don't**

``` jinja
{{ states('sensor.payload') | from_json | default({}) .get('key', 0) }}
```

**Rule:**

-   Avoid Python methods (`.get()`, `.items()`, etc.) on objects
    returned from HA (`states()`, `state_attr()`, `from_json`, etc.).
-   `.get()` is acceptable on known dict literals you construct
    yourself.
-   For new artifacts or refactors where a Python method is directly
    implicated and easily replaced, prefer the filter/test pattern.
-   Do not expand refactor blast radius solely to remove a safe `.get()`
    on a literal dict.

------------------------------------------------------------------------

## Nested Lookup (guard each level)

**Do**

``` jinja
{% set d = states('sensor.payload') | from_json | default({}) %}
{% set item = (d['outer']['inner'] if 'outer' in d and 'inner' in d['outer'] else 0) %}
```

**Don't**

``` jinja
{{ d['outer']['inner'] }}
```

------------------------------------------------------------------------

## Keys/Values Iteration

**Do**

``` jinja
{% for pair in (d | dict2items) %}
  {{ pair.key }} → {{ pair.value }}
{% endfor %}
```

**Pragmatic Allowance**

``` jinja
{% set d = {'a':1,'b':2} %}
{% for k, v in d.items() %}
  {{ k }} → {{ v }}
{% endfor %}
```

**Rule:**

-   Avoid `.items()` on HA-returned or JSON-derived objects.
-   Acceptable on known literal dicts.
-   Prefer `dict2items` in new or refactored artifacts.

------------------------------------------------------------------------

## String Operations (use filters, not Python methods)

**Do**

``` jinja
{{ states('sensor.name') | replace('old','new') | lower | trim }}

{{ 'a,b,c'
   | regex_findall('[^,]+')
   | map('trim')
   | map('lower')
   | reject('equalto','')
   | unique
   | list }}
```

**Don't**

``` jinja
{{ states('sensor.name').replace('old','new').lower().strip() }}
{{ 'a,b,c'.split(',') }}
{{ 'a,b,c' | split(',') }}
```

------------------------------------------------------------------------

## List Building

**Do**

``` jinja
{% set result = [] %}
{% set result = result + ['item'] %}
```

**Don't**

``` jinja
{% set result = [] %}
{% do result.append('item') %}
```

------------------------------------------------------------------------

## Template Size & Cost

**Do**

``` jinja
{% set export = states('sensor.export') | float(0) %}
{% set buy = states('sensor.buy') | float(0) %}
```

**Don't**

``` jinja
{{ states('sensor.export') | float(0) > 100 and states('sensor.buy') | float(0) < states('sensor.sell') | float(0) }}
```

------------------------------------------------------------------------

## ⚠️ Trigger `for:` Template Complexity (Limited Context)

Trigger `for:` blocks have reduced template capability.

**Do**

``` jinja
for:
  seconds: |
    {% if night %} 20 {% elif irr <= 50 %} 90 {% else %} 25 {% endif %}
```

**Don't**

``` jinja
for:
  seconds: '{{ ([20, calculated_value, 120] | sort)[1] | float }}'
```

Move complex logic to template sensors or action templates.

------------------------------------------------------------------------

## ❌ Don't: `state_not` in conditions (invalid)

`state_not` is not a valid Home Assistant condition key and will raise
"Message malformed: extra keys not allowed".

**❌ Invalid**

``` yaml
condition:
  - alias: Reject when X is not 'on'
    state_not: 'on'
    entity_id: input_boolean.x
```

**✅ Valid**

``` yaml
condition:
  - alias: Reject when X is not 'on'
    condition: not
    conditions:
      - condition: state
        entity_id: input_boolean.x
        state: 'on'
```

------------------------------------------------------------------------

## Entity Set Iteration (label/area/floor functions)

`label_entities()`, `area_entities()`, `floor_entities()`, and
`integration_entities()` return **flat lists of entity ID strings** —
not state objects. Accessing `.state` or `.entity_id` on the raw results
silently returns `None` or errors.

**Do — IDs only**

``` jinja
{% for entity_id in label_entities('Security') %}
  {{ entity_id }}
{% endfor %}
```

**Do — need state or attributes: use `expand()` first**

``` jinja
{% for s in expand(label_entities('Security')) %}
  {{ s.entity_id }} is {{ s.state }}
{% endfor %}
```

**Don't**

``` jinja
{% for e in label_entities('Security') %}
  {{ e.entity_id }} is {{ e.state }}  {# e is a string — .entity_id and .state are None #}
{% endfor %}
```

**Note:** If the label/area might be empty, guard with a length check
before iterating to avoid silent no-ops.

------------------------------------------------------------------------

## Type Safety in Comparisons

**Good pattern:**

``` jinja
brightness_raw: "{{ states('light.kitchen') }}"
desired_brightness_raw: "{{ state_attr('input_number.target', 'value') }}"

brightness: "{{ brightness_raw | float(0) }}"
desired_brightness: "{{ desired_brightness_raw | float(0) }}"

tolerance_ok: "{{ (brightness - desired_brightness) | abs <= 5 }}"
```

**Bad:**

``` jinja
tolerance_ok: "{{ states('light.kitchen') | float(0) - state_attr(...) | float(0) <= 5 }}"
```

**Checklist item:** "Are numeric comparisons using typed variables, not
string-rendered states?"

------------------------------------------------------------------------

## Comments in Jinja Literals

**Do**

``` jinja
# Static lookup table for the template below
{% set values = [
  [1, 2],
  [3, 4]
] %}
```

``` yaml
# Holiday list used by the template below
is_holiday: >-
  {% set holidays = [
    [2027, 1, 1],
    [2027, 2, 15]
  ] %}
  {{ today in holidays }}
```

**Don't**

``` jinja
{% set values = [
  [1, 2], {# inline comment #}
  [3, 4]
] %}
```

**Rule:**  
Inside Jinja literals (`[]`, `{}`), keep content to **data only**.  
Put documentation **outside the Jinja expression**.

**Automation rule:**  
Do **not** use YAML comments for documentation in automations.  
Use `alias:` or `description:` instead.
