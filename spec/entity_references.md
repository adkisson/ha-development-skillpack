# Entity References

## Prefer entity_id over device_id

- **Always use `entity_id`** in triggers, conditions, actions, and service call targets.
- `device_id` is an internal registry identifier that changes silently when a device is removed and re-added (re-pair, coordinator swap, exclusion/inclusion). Automations break with no error — they simply stop executing.
- `entity_id` is stable across re-pairs as long as the entity name is not manually changed in the registry.

## Target selectors

- Use `entity_id` in `target:` blocks. Use `area_id` when the intent is broadcast control across all devices in an area (e.g., turn off all lights in an area).

## ZHA button/remote exception

- Buttons and remotes that fire events only and have no state entity cannot use state triggers. For these, use a `zha_event` trigger with `device_ieee` (the hardware MAC address).
- Document in the automation `description:` that the trigger relies on a ZHA MAC address and must be updated if the physical device is swapped.
