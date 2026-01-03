# Debugging Cookbook

## Tabs & Tools
- **DTT**: Developer Tools → Template (first stop for logic)
- **Traces**: Automation debug traces (end‑to‑end orchestration only)
- **Logbook/History**: sanity checks; avoid verbose production logs

## Techniques
- Inline `reason` attribute for human diagnosis.
- Keep `#debug_*` attributes commented for quick enabling.
- Use DTT snippets from the cookbook to probe computations.
- Validate one room/fixture at a time (binary isolation).
- Rollback plan: timestamped YAML copies for quick bisect.

## When to use Traces
- When the correct branch doesn’t execute in order, or timing seems off.
- Not for templating authoring; use DTT for that.
