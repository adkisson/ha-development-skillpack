# Performance & Chatter

- Prefer **event‑driven** over time‑pattern polling. If polling is required, enforce a minimum **60s** interval unless critical.
- **Scope state triggers**: a `state` trigger with only `entity_id` also fires on every attribute change. Add `to: null` when only the state matters; omit it only when the logic reads the entity's attributes.
- **Derive once from noisy sources**: when several automations depend on a fast-updating sensor (power, energy), derive one entity from it — a `threshold`, `statistics`, `derivative`, or `filter` sensor, or a trigger-based template sensor — and trigger on that.
- Batch updates by **group/area**; avoid rapid repeated per‑device calls.
- Use `repeat: for_each:` for controlled fan‑outs; avoid unbounded loops; keep iterations <10 per tick.
- **Wait, don't poll**: use `wait_for_trigger` or `wait_template` with a timeout, not a `repeat` … `until` loop around a short `delay`. Set `mode`/`max` so `queued` or `parallel` runs cannot accumulate.
- Keep templates efficient: precompute; avoid repeated `states()` calls.
- **Know what re-renders a template**: a template re-renders whenever something it references changes. Reading `states` re-renders on any state change (at most once a minute), `states.<domain>` on any change in that domain (up to once a second), and `now()` every minute. A trigger-based template sensor renders only when its triggers fire; use one when the value is needed only on specific changes.
- **Bound domain-wide state iteration**: avoid unbounded iteration over `states.<domain>` (e.g. `states.light`, `states.sensor`) in frequently evaluated templates. Prefer an explicit entity set, a `group`, or a label/area where semantically appropriate — a bounded source whose membership and cost are known. Domain-wide iteration is acceptable only when the requirement is genuinely domain-wide and the evaluation frequency and cost are understood; this is not a blanket ban on `states.<domain>`, it's bounded-by-default for anything evaluated often.
- **Recorder load**: every state and attribute change is written to history. Keep attributes small and stable (`patterns/template_sensor_attributes.md`), and exclude internal or debug-only entities from the recorder when their history has no use.
- Avoid INFO‑level log spam; enable DEBUG only during active debugging via a helper switch.
