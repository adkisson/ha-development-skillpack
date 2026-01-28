# YAML Template Header Standards

Every YAML must include:
- `alias:` (human-readable title) and `description:` (purpose + key decisions).
- A concise **CHANGELOG** using the rules defined in §12 (**Changelog & Versioning**).
- Dependencies list in comments if relevant (`input_boolean.*`, `timer.*`, `sensor.*`).
- “Last verified on HA <version>” comment.

---

## Example (Automation / Script)

```yaml
alias: Lighting – Porch Wave Pattern
description: >
  Subtle wave effect for evenings; minimal chatter; idempotent guard applied.

  **CHANGELOG:**

  - 20251022-1200: Debounce and restart gate tuned.
# deps: input_boolean.evening_mode, light.porch_group

```

## Notes

- Automations and scripts use Markdown-rendered `description:` changelogs.
- When using Markdown list items (`- ...`), a blank line is required after `CHANGELOG:`
- YAML-defined entities that do not support Markdown-rendered descriptions use # CHANGELOG: comments instead (see §12b).
- Include an `alias:` at the top level and everywhere the Home Assistant schema permits it (all triggers, conditions, and action steps, including nested ones).
- See snippets/jinja_patterns.md for micro-patterns (e.g., replacing invalid state_not with condition: not).
