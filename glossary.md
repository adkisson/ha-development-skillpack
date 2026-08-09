# Glossary & Naming Conventions

This file defines vocabulary and naming conventions only. Workflow routing lives in `SKILL.md`; review authority lives in `/guides/review_and_checklist.md`.

## Acronyms & Terms

- **AD / AppDaemon**: Python-based Home Assistant app framework used when YAML becomes difficult to reason about, test, or maintain.
- **API recovery**: Handling unavailable, stalled, rate-limited, or cloud-dependent integrations without creating reload storms, command chatter, or unsafe retries.
- **BC**: Backward-Incompatible Change — a change that requires user configuration updates or removes/deprecates existing HA schema, keys, attributes, services, or behavior. Review applicability and scope are defined in spec/runtime.md.
- **Brains vs Muscles**: a pattern, not a mandate — separating meaningful derived-state/directive computation (brains, typically a template sensor) from deterministic actuation authority (muscles, automations/scripts) when that separation actually improves the design. See `workflows/architecture.md`; a simple native automation with no real derived-state layer needs no separate "brain."
- **Directive**: computed intent from a template sensor or app, usually paired with a human-readable `reason`; not direct actuation authority by itself.
- **DTT**: Developer Tools → Template; the HA UI template editor used for Jinja validation.
- **DTT-first**: validate Jinja logic and usable-state entity reads in Developer Tools before deployment approval; use defined-entity checks where existence matters — see `/guides/dtt_first_validation.md`.
- **Execution gating**: pattern where automations act only on positive evidence and default to no action on uncertainty.
- **HA**: Home Assistant.
- **HAF**: Household Acceptance Factor — household acceptance of automation behavior, nuisance risk, alerts, repeated toggles, sleep disruption, and automation fighting humans. Repeated annoyance is a production-level defect.
- **SIC**: System Impact Classification — worst-credible failure impact rating (Class A–D) assigned before any design work begins; see `/guides/system_impact_class.md`.
- **Staggering**: restart-delay strategy, usually on `timer.ha_startup_delay`, used to prevent thundering-herd behavior after HA restart.
- **Steward safety**: preservation of owner intent, entity IDs, aliases, scope, and existing behavior during edits.

## Naming Conventions

**Entity naming**: `area_device_purpose` — e.g., `bedroom_ceiling_light`, `garage_door_contact`, `kitchen_fridge_temp`.
