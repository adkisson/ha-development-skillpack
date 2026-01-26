# Restart Resilience (Patterns)

| Type | Trigger `for:` window | Purpose |
|------|----------------------|----------|
| **Critical** | `<10s` fixed | Safety/security/HVAC |
| **Non‑critical** | `45–75s` randomized | Reconciliation tasks |
| **Diagnostic** | `>90s` fixed or skipped | Optional, no actuation |

Guidelines:
- Use **trigger‑level `for:`** on `timer.ha_startup_delay → idle` to stagger; **do not** use action delays.
- Reconcile directives once; avoid actuation storms.
- Prefer timers over long `for:` for persistence across restarts.
- Idempotency after restart: guard re‑sends.

## Offline Sensor Detection at Boot (Edge Case Recovery)

**Scenario:** Sensor is already unavailable when HA starts, state restores as unavailable without a state-change event, offline timer is idle, and no trigger fires to start the grace window.

**Solution:** Add a startup recovery trigger after `timer.ha_startup_delay` reaches idle:
```yaml
triggers:
  - id: startup_sensor_unavailable
    alias: HA startup with sensor already unavailable
    trigger: state
    entity_id: timer.ha_startup_delay
    to: idle
    for:
      seconds: '{{ range(45, 75) | random }}'  # Non-critical automation delay
```

Then check sensor state and start offline grace window:
```yaml
actions:
  - alias: Start offline timer if sensor unavailable at startup
    if:
      - condition: trigger
        id: startup_sensor_unavailable
      - condition: state
        entity_id: sensor.monitored_sensor
        state:
          - unavailable
          - unknown
      - condition: state
        entity_id: timer.offline_grace_window
        state: idle
    then:
      - action: timer.start
        target:
          entity_id: timer.offline_grace_window
        data:
          duration: "00:05:00"
```

This ensures offline detection doesn't miss sensors that were disconnected before HA booted.
````
