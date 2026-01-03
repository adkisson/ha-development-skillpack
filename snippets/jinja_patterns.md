# Jinja Patterns for Home Assistant – Do / Don’t

> Purpose: short, copy‑paste‑able idioms + **WHAT NOT TO DO** in HA Jinja.

## Safe Reads
**Do**
```jinja
{% set v = states('sensor.power') | float(0) %}
{% set name = states('input_text.nickname') | default('unknown') %}
```
**Don’t**
```jinja
{{ states.sensor.power.state | float }}                 {# breaks if entity missing #}
{{ states('sensor.power') | float }}                    {# no default ⇒ NaN/None cascades #}
```

## Existence & Availability
**Do**
```jinja
{% set ok = (states('sensor.foo') not in ['unknown','unavailable','']) %}
```
**Don’t**
```jinja
{% if has_value('sensor.foo') %}                        {# unreliable for missing entities #}
```

## Text Normalization
**Do**
```jinja
{% set cond = states('sensor.condition') | lower | trim %}
```
**Don’t**
```jinja
{% set cond = states('sensor.condition').lower() %}     {# Python method on None ⇒ error #}
```

## Numbers & Math
**Do**
```jinja
{% set a = states('sensor.a') | float(0) %}
{% set b = states('sensor.b') | float(0) %}
{{ (a - b) | round(2) }}
```
**Don’t**
```jinja
{{ float(states('sensor.a')) - float(states('sensor.b')) }} {# `float()` is Python, not a Jinja filter #}
```

## Datetime Safety
**Do**
```jinja
{% set t = as_timestamp(now()) %}
{% set age = (as_timestamp(now()) - as_timestamp(states.sensor.foo.last_changed)) %}
```
**Don’t**
```jinja
{{ (now() - states.sensor.foo.last_changed).total_seconds() }} {# total_seconds is Python and fails in triggers & elsewhere # #}
```

## Numbers & Booleans from Strings
**Do**
```jinja
{% set n = states('sensor.count') | int(0) %}
{% set on = is_state('switch.x','on') %}
```
**Don’t**
```jinja
{% if states('switch.x') == True %}                     {# string vs bool mismatch #}
```

## Nullable Attributes & Violation Flags
**Do**
````jinja
{% set violation = 'high' if value > 68 else ('low' if value < 38 else none) %}
{% set temp = states('sensor.temp') | float(none) %}
````
**Don't**
````jinja
{% set violation = 'high' if value > 68 else ('low' if value < 38 else 'null') %}  {# string "null", not Jinja none #}
{% set temp = states('sensor.temp') | float(0) %}  {# returns false 0°F when unavailable #}
````

**Why:** Returning Jinja `none` allows downstream logic to safely check `violation is none` or `violation != 'high'`. Returning string `"null"` requires string comparisons. Using `float(none)` prevents false-zero values (0°F, 0%) that confuse downstream alert logic.

## Attribute Access
**Do**
```jinja
{% set br = state_attr('light.kitchen','brightness') | int(0) %}
```
**Don’t**
```jinja
{{ states.light.kitchen.attributes.brightness }}       {# fails on unknown/unavailable #}
```

## JSON Packaging
**Do**
```jinja
{{ {'items': items, 'reason': reason} | tojson }}
```
**Don’t**
```jinja
{{ {'items': items, 'reason': reason} }}               {# Python dict repr, not JSON #}
```

## Dict Lookup With Defaults (no `.get()`)
**Do**
```jinja
{% set d = states('sensor.payload') | from_json | default({}) %}
{% set val = d['key'] if 'key' in d else 0 %}
```
**Don’t**
```jinja
{{ d.get('key', 0) }}                                  {# `.get()` is a Python method; blocked in HA Jinja #}
```

## Nested Lookup (guard each level)
**Do**
```jinja
{% set d = states('sensor.payload') | from_json | default({}) %}
{% set item = (d['outer']['inner'] if 'outer' in d and 'inner' in d['outer'] else 0) %}
```
**Don’t**
```jinja
{{ d['outer']['inner'] }}                              {# KeyError if any level missing #}
```

## Keys/Values Iteration (avoid `.items()`)
**Do**
```jinja
{% for pair in (d | dict2items) %}
  {{ pair.key }} → {{ pair.value }}
{% endfor %}
```
**Don’t**
```jinja
{% for k, v in d.items() %}                            {# `.items()` is a Python method; blocked #}
  {{ k }} → {{ v }}
{% endfor %}
```

## String Operations (use filters, not Python methods)
**Do**
```jinja
{{ states('sensor.name') | replace('old','new') | lower | trim }}
{{ 'a,b,c' | split(',') }}
```
**Don’t**
```jinja
{{ states('sensor.name').replace('old','new').lower().strip() }}
{{ 'a,b,c'.split(',') }}
```

## List Building (no `.append()`)
**Do**
```jinja
{% set result = [] %}
{% set result = result + ['item'] %}
{% set result = result + [variable] %}
```
**Don’t**
```jinja
{% set result = [] %}
{% do result.append('item') %}                          {# `.append()` is Python; blocked in HA Jinja #}
```
**Alternative for dynamic construction**
```jinja
{% set items = namespace(list=[]) %}
{% for x in range(0,3) %}
  {% set items.list = items.list + [x] %}
{% endfor %}
{{ items.list }}
```

## Template Size & Cost
**Do**
```jinja
{# Precompute once #}
{% set export = states('sensor.export') | float(0) %}
{% set buy = states('sensor.buy') | float(0) %}
{% set sell = states('sensor.sell') | float(0) %}
```
**Don’t**
```jinja
{{ states('sensor.export') | float(0) > 100 and states('sensor.buy') | float(0) < states('sensor.sell') | float(0) }}
{# repeats expensive state() calls; harder to read/test #}
```

---
## ⚠️ Trigger `for:` Template Complexity (Limited Context)

Trigger `for:` blocks have **reduced template capabilities** compared to action templates. Complex filter chains and list operations fail silently or with cryptic errors.

**Do: Simple if/elif/else conditionals**
```jinja
for:
  seconds: |
    {% if night %} 20 {% elif irr <= 50 %} 90 {% elif irr <= 300 %} 60 {% else %} 25 {% endif %}
```

**Don't: Filter chains or list ops in trigger `for:`**
```jinja
for:
  seconds: '{{ ([20, calculated_value, 120] | sort)[1] | float }}'  {# Fails silently in trigger context #}
```

**Workaround**: Move complex calculations to **action templates** or **template sensors**, then reference them in triggers.

---
## ❌ Don't: `state_not` in conditions (invalid)

`state_not` is not a valid Home Assistant condition key and will raise:
“Message malformed: extra keys not allowed”.

```yaml
# ❌ Invalid
condition:
  - alias: Reject when X is not 'on'
    state_not: 'on'
    entity_id: input_boolean.x
```

## ✅ Do: Use `condition: not` + nested `state`

```yaml
# ✅ Valid
condition:
  - alias: Reject when X is not 'on'
    condition: not
    conditions:
      - condition: state
        entity_id: input_boolean.x
        state: 'on'
```

### Type Safety in Comparisons
When comparing numeric values, always separate raw input from typed variable:

**✅ Good pattern:**
```jinja
# Raw inputs (string from state)
brightness_raw: "{{ states('light.kitchen') }}"
desired_brightness_raw: "{{ state_attr('input_number.target', 'value') }}"

# Typed (safe for math/comparisons)
brightness: "{{ brightness_raw | float(0) }}"
desired_brightness: "{{ desired_brightness_raw | float(0) }}"

# Comparison uses typed variables, not raw strings
tolerance_ok: "{{ (brightness - desired_brightness) | abs <= 5 }}"
```

**❌ Bad:**
```jinja
tolerance_ok: "{{ states('light.kitchen') | float(0) - state_attr(...) | float(0) <= 5 }}"
```
(Recomputes conversions multiple times; harder to debug)

**Checklist item:** "Are numeric comparisons using typed variables, not string-rendered states?"
