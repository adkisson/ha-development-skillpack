# Performance & Chatter

- Prefer **event‑driven** over time‑pattern polling. If polling is required, enforce a minimum **60s** interval unless critical.
- Batch updates by **group/area**; avoid rapid repeated per‑device calls.
- Use `repeat: for_each:` for controlled fan‑outs; avoid unbounded loops; keep iterations <10 per tick.
- Keep templates efficient: precompute; avoid repeated `states()` calls.
- Avoid INFO‑level log spam; enable DEBUG only during active debugging via a helper switch.
