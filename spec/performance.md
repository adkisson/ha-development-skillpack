# Performance & Chatter

- Prefer **event‑driven** over time‑pattern polling. If polling is required, enforce a minimum **60s** interval unless critical.
- Batch updates by **group/area**; avoid rapid repeated per‑device calls.
- Use `repeat: for_each:` for controlled fan‑outs; avoid unbounded loops; keep iterations <10 per tick.
- Keep templates efficient: precompute; avoid repeated `states()` calls.
- **Bound domain-wide state iteration**: avoid unbounded iteration over `states.<domain>` (e.g. `states.light`, `states.sensor`) in frequently evaluated templates. Prefer an explicit entity set, a `group`, or a label/area where semantically appropriate — a bounded source whose membership and cost are known. Domain-wide iteration is acceptable only when the requirement is genuinely domain-wide and the evaluation frequency and cost are understood; this is not a blanket ban on `states.<domain>`, it's bounded-by-default for anything evaluated often.
- Avoid INFO‑level log spam; enable DEBUG only during active debugging via a helper switch.
