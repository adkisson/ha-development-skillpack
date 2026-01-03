# Safety & Error Handling

- `continue_on_error: true` is acceptable for transient transports (e.g., flaky mesh); document rationale inline.
- Critical actuators (HVAC, locks, garage doors) must enforce **min‑run/min‑off** timers where applicable.
- Retries must be **bounded** (e.g., one retry with short backoff).
- Safety/override helpers always take precedence over efficiency logic.
- **Graceful Integration Degradation**: Sensors depending on external APIs or unreliable integrations must degrade gracefully. Use safe defaults, loose availability gates (only require truly critical inputs), expose degradation state (`data_quality`, `reasoning`), and ensure downstream automations check degradation status before proceeding. See `/patterns/integration_degradation.md`.
- **Proxy Witnesses**: When primary sources unavailable, infer coarse-grained state from local evidence (e.g., charging cable presence, power draw, proximity). Proxies are conservative and never fabricate precision values; mark proxy-derived results in `reasoning`.
**Edge Case Clause**: When a standard would prevent a safe outcome, explicitly justify the exception inline (description/alias/comments).
