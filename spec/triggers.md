# Trigger Standards (Event-Driven Preferred)

**Order of preference**
1. **Event/state-driven** (state, event, template) — first choice.
2. **Time-based** — only when necessary; minimum 60s cadence unless critical.

**Debounce & windows**
- Use `for:` windows on triggers rather than delays in actions.
- Specify `to:`/`from:` for booleans to avoid accidental oscillations.
- **Restart staggering**: on `timer.ha_startup_delay → idle`:
  - Critical: **<10s fixed**
  - Non‑critical: **25–75s randomized**
- **Startup triggers** only when post-restart actions are needed (e.g., state recovery, guard initialization). Avoid them for passive/event-driven automations.

**Template complexity in triggers**
- Trigger `for:` blocks have limited template capabilities; complex filter chains (e.g., `([20, value, 120] | sort)[1]`) fail silently in trigger contexts.
- **Do**: Use clear `if/elif/else` conditionals in trigger templates.
- **Don't**: Use filter chains or list operations in `for:` blocks; use action templates instead.

**Device-specific state triggers over generic broadcasts**
- When a device exposes state via entity attributes, prefer state triggers on the specific entity over generic event broadcasts (e.g., `zwave_js_value_notification`). Eliminates Z-Wave bus overhead and reduces system-wide latency.
- Caveat: Some devices may not persist state; verify the entity updates on your hardware before relying on state triggers.

**Creativity rule**
- Deviations allowed if justified inline in `description`/`alias`.
