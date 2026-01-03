# YAML Template Header Standards

Every YAML must include:
- `alias:` (human‑readable title) and `description:` (purpose + key decisions).
- A concise **CHANGELOG** block (commented or within description) with dates.
- Dependencies list in comments if relevant (`input_boolean.*`, `timer.*`, `sensor.*`).
- “Last verified on HA <version>” comment.

**Example**

```yaml
alias: Lighting – Porch Wave Pattern
description: >
  Subtle wave effect for evenings; minimal chatter; idempotent guard applied.
  #
  # CHANGELOG:
  # - 2025-10-22: Debounce and restart gate tuned. Verified HA 2025.10.
# deps: input_boolean.evening_mode, light.porch_group
# verified: HA 2025.10.x
```

- Include an `alias:` at top-level **and** inside every trigger, condition, and action block to improve traces and diffs.
- See `snippets/jinja_patterns.md` for micro-patterns (e.g., replacing invalid `state_not` with `condition: not`).
