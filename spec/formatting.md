# Formatting, Units & Timezone

- **Units**: Temperature °F, Power W, Energy kWh by default. Convert at edges if upstream differs.
- **Rounding**: 1 decimal for temperature; `int(0)` for brightness; 0 decimals for percentages unless user‑facing text needs one.
- **Timezone**: **America/Los_Angeles**. Use `as_timestamp()` for calculations; format times for user messages with local time (AM/PM or 24‑hour per context).
- **Strings**: normalized via `| lower | trim`; avoid Python string methods.
