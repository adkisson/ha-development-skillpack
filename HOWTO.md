# HOWTO (Onboarding & Table of Contents)

Use this as your entry point. The skill is a reasoning framework for producing robust HA YAML/Jinja.

## Layout & Naming (kept here exclusively)
- `guides/` — review how‑to & principles
- `patterns/` — restart resilience, idempotency, chatter control, lighting paths
- `cookbooks/` — DTT techniques & debugging (incl. traces)
- `snippets/` — Jinja Do/Don’t anti‑patterns
- `templates/` — automation/script/template_sensor scaffolds + option matrix
- `samples/` — coherent examples with `alias:` everywhere and YAML changelogs
- `tools/` — helper shell scripts (`entity_snapshot.sh`, `lint_templates.sh`)
- `spec/` — focused guardrails (runtime, triggers, safety, security, formatting, notifications, performance)

**Entity naming:** `area_device_purpose` (e.g., `bedroom_ceiling_light`).  
**Timestamped files (optional):** `<category>–YYYYMMDD–HHMM.yaml`.

## Workflow
1) Draft using `/templates/*.yaml` (automation/script/template_sensor).  
2) Check `/spec/*` guardrails (runtime, triggers, safety, security, formatting, notifications, performance).  
3) Validate logic in **DTT** first (Developer Tools → Template).  
4) **Reviewers** make a good‑faith pass to catch Jinja issues **before** running `tools/lint_templates.sh`.  
5) Run the linter, then submit PR following **/guides/review_and_checklist.md**.  
6) Include concise **CHANGELOG** in YAML descriptions or `#` comments; **do not** keep changelog in `SKILL.md`.

## Glossary (no shorthand assumptions)
- **HA**: Home Assistant
- **DTT**: Developer Tools → **Template**
- **BC**: **Breaking Change** — a change that requires user config adjustments or deprecates HA schema/keys/behavior
- **Idempotent**: Running the same action again doesn’t change state
- **Brains vs Muscles**: templates decide; automations/scripts act
- **Hysteresis**: guards to prevent oscillation between states
- **Staggering**: randomized restart delay to avoid storms
- **Timezone**: America/Los_Angeles (local time)

- See `guides/validator_flow.md` for the human validator checklist.
- See `patterns/template_sensor_attributes.md` for attribute design.
