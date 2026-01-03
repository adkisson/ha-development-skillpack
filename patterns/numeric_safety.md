# Numeric Safety

**Principle**: Separate input preparation (raw → typed) from comparison logic. Use tolerance bands instead of exact equality.

## Raw & Typed Variables

Separate concerns: reading (raw), coercion (typed), logic (comparisons).

**✅ Good:**
```jinja
{% set brightness_raw = states('light.kitchen') %}
{% set brightness = brightness_raw | float(0) %}
{% set tolerance = 3 %}
{% set matches = (brightness - 80) | abs <= tolerance %}
```

**❌ Bad:**
```jinja
{% set matches = states('light.kitchen') | float(0) == 80 %}
{# Recomputes; harder to debug #}
```

**Why**: Single-read principle, type safety, reusable variables.

## Comparisons With Tolerance

Exact equality fails due to sensor noise, float precision, rounding.

| Domain | Tolerance | Example |
|--------|-----------|---------|
| Brightness (0-255) | 3–5 | `(actual - desired) \| abs <= 3` |
| Temperature | 0.5–1°C | `(actual - desired) \| abs <= 0.5` |
| Humidity / % | 1–2% | `(actual - desired) \| abs <= 2` |
| Power (W) | 5–10 | `(actual - desired) \| abs <= 10` |
| Color temp (K) | 50–100 | `(actual - desired) \| abs <= 100` |

## Common Pitfalls

```jinja
{% set brightness = states('light.kitchen') | float %}  {# ❌ None if unavailable #}
{% set brightness = states('light.kitchen') | float(0) %} {# ✅ Safe default #}

{% set a = "80" %}
{{ a < "100" }}  {# ❌ False (alphabetic) #}
{{ a | float < 100 | float }}  {# ✅ True (numeric) #}

{% set pct = 150 | int(0) %}  {# ❌ 150% invalid #}
{% set pct = 150 | int(0) | max(0) | min(100) %}  {# ✅ Clamped #}

{% set zones = state_attr('sensor.x', 'zones') %}  {# ❌ String JSON fails #}
{% set zones = state_attr('sensor.x', 'zones') | from_json(default=[]) %}  {# ✅ Safe #}
```

## Checklist
- [ ] Raw/typed variables separated?
- [ ] Safe defaults on numeric reads (`| float(0)`, `| int(0)`)?
- [ ] Tolerance defined and justified?
- [ ] Clamping applied to bounded values?
- [ ] JSON decoded with fallback?

---
**Last Updated**: 2026-01-02
