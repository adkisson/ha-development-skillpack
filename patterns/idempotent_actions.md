# Idempotent Actions (Patterns)
- Guard service calls (compare desired vs current).
- Batch via groups/areas; one call beats many.
- Retry once for transient errors; `continue_on_error: true` only when justified.
- Scripts handle fan‑outs; automations call scripts.
