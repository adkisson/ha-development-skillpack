# Event-Driven Templates (Patterns)

- Triggers include only entities that change outcomes; add HA startup gate:
  - Critical: `for: {seconds: <10}`
  - Non‑critical: `for: {seconds: '{{ range(45, 75) | random }}' }`
- State shape: short enums (`execute`, `conserve`, `hold`) or JSON map for batch ops.
- Attributes: `reason` + metrics; commented `#debug_…` attrs for quick flip‑on.
- Safe reads: `states()`/`state_attr()` with defaults; normalized strings; precompute vars.
- Hysteresis/cooldowns: implement in automation or via attributes; avoid jitter.
- Don’ts: `.get()`, `.items()`, `.split()`, `.append()`, `.replace()`, `.format()`, `.total_seconds()`.
- Prefer `has_value()` to raw `states() not in ['unknown','unavailable','']` checks: `has_value()` is the safe, idiomatic HA mechanism for availability. If the source is known to emit blank strings, add and (states(...)|trim) != ''.
