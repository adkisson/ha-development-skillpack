## Changelog
## 2.0.0 - 20260809
- `SKILL.md` rebuilt around a five-workflow reasoning-state router (Ideation/Architecture/Development/Debug/Refactor), replacing the task-mode router and Session Modes.
- Added a Collaboration Baseline (owner authority, evidence-based pushback, surfacing uncertainty) and an Architect/Dev role axis orthogonal to workflow selection; calibration examples live in new `guides/architect_dev_roles.md`.
- Retired `guides/exploratory_mode.md`, `new_automation_intake.md`, `architecture_principles.md`, `systematic_debugging.md`; content absorbed into `workflows/*.md`.
- Added `guides/construct_selection.md`: single decision ladder (previously duplicated), native tier reordered purpose-specific → generic native → template, with an entity-targeting-authority rule. Corrected against current HA docs to distinguish HA's own 2025.12/2026.7 purpose-specific trigger/condition system from longstanding constructs like `sun`/`zone`/`device`.
- Added `guides/artifact_authority.md`: Samples & Scaffolds doctrine plus a placeholder-entity exemption from the anti-hallucination gate.
- `guides/review_and_checklist.md`: replaced the A–F letter grade with a weighted score (six categories) plus a hard-gate list; broadened HAF/UX beyond "shared spaces/schedules" and made it a standing invariant rather than a final-step-only check; removed fixed-option-count ceremony; softened absolute override wording.
- `guides/dtt_first_validation.md`: added a falsifiability requirement; entity validation and logic validation are now separate obligations.
- `spec/performance.md`: added a bounded domain-wide state-iteration rule. `spec/yaml_style.md`: softened the boolean `to:`/`from:` rule to allow deliberate dual-transition recompute.
- Sample/scaffold consistency sweep: removed entity IDs from automation descriptions; fixed changelog formatting in two samples; generalized `scaffolds/template_sensor.yaml` and `automation.yaml` off mandatory brains/muscles framing; removed an unexplained polling trigger.
- Syntax sweep: replaced residual deprecated `platform: template`/`platform: state`/singular top-level `trigger:`/`condition:`/`action:` with current `trigger: template` and plural `triggers:`/`conditions:`/`actions:` across `spec/yaml_style.md`, `guides/construct_selection.md`, `guides/review_and_checklist.md`, `patterns/recursive_loop.md`, and `snippets/jinja_patterns.md`; unwrapped two remaining multi-line description paragraphs in samples.
- Updated cross-references throughout to point at the new workflow files.
- Fixed `workflows/debug.md`'s exit boundary to match the Task Router: Debug ends at demonstrated root cause and hands off to Development/Refactor/Architecture for the correction, rather than staying open through implementation and revalidation.
- Standardized "Backward-compat(ibility)" prose to "Backward-Incompatible" terminology (`BC review` shorthand unchanged); scoped Development's BC requirement to "where applicable" to match the hard gate.
- Softened the glossary's Brains vs Muscles entry from a universal definition to an explicitly conditional pattern.
- Restored the 1.x doctrine that community sources (Reddit, forums, blogs) inform troubleshooting but aren't authoritative for HA syntax/schema, in `spec/runtime.md`.
- Removed personal/instance-specific examples from `cookbooks/dtt_techniques.md` and `guides/dtt_first_validation.md` (generic placeholders now, apostrophe-conversion lesson preserved).
- Fixed `tools/lint_templates.sh`: removed two patterns that flagged the pack's own recommended `| float(0)`/`| int(0)` filters as violations, narrowed the direct-state-access check to actual attribute access (was also flagging the recommended defined-entity check), and stopped matching inside full-line comments — it failed against the pack's own canonical samples before this fix.
- Fixed `tools/entity_snapshot.sh`: now actually resolves area names (entity-level override, else inherited from device) as its header always claimed; fixed a latent crash on any entity with no `device_id`. Both tool scripts changed from mode 0777 to 0755.
- Breaking change to file paths and structure relative to 1.x, per the restructure notice carried in the 1.0.1 README.
## 1.0.1 - 20260622
- 20260622-1600: Added automation/script nested `note:` guidance for schema-supported triggers, conditions, and actions; clarified `alias:` as trace identity and `note:` as maintenance rationale.
## 1.0.0 - 20260607
- Scaffold and sample corrections: fixed invalid YAML `elif` throughout; split mixed template+automation files into companion pairs; corrected `variables:` placement, canonical startup trigger doctrine, and restart recovery mode across all artifacts; removed GUI-fragile inline comments.
- `snippets/jinja_patterns.md`: fixed unsafe `from_json | default()` pipe pattern; use `from_json(default=...)`.
- `SKILL.md` rebuilt as dispatcher: added Artifact Map, strengthened samples/scaffolds authority hierarchy, renamed "Core HA rules" to "Core Skill Pack rules", narrowed BC review scope, added Compatibility forward-reference.
- Consolidated YAML authoring into `spec/yaml_style.md`; hardened review governance, Jinja standards, and architecture guidance; replaced `HOWTO.md` with `glossary.md`.
- Updated security guidance for narrow operational-identifier exceptions where no secrets mechanism exists.
## 0.7.4
- Added spec/zwave_js.md - Z-Wave JS Central Scene authoring guidance for exact device triggers, raw event routing, and the `value`/`value_raw` mismatch footgun.
- Added guides/cloud_api_actuation.md — defensive actuation pattern for cloud-backed entities covering confirm-retry-notify, recovery trigger, branch gate expansion, sustained unavailability hold, and complete trigger set reference.
- Added guides/integration_watchdog.md — config entry reload watchdog pattern for integrations with known, recurring, recoverable failure modes.
## 0.7.3
- Overhauled dtt_techniques.md with extremely successful scaffolding for uncovering issues
- Moved skill changelog into its own file
## 0.7.2
- Refined review checklist: added optional HALMark-inspired safety-level summary under Self-Critique, strengthened KISS native-first guidance, and clarified simpler-alternative handling.
- Updated license/provenance notes to reflect incorporation of the HALMark stewardship/safety-level review model.
- Resolved documentation/tooling ambiguity in /samples and HOWTO.md
- Clarified unique trigger ID
## 0.7.1
- Overhauled Roles & Decision-Making: Session Mode (exploratory/design/execution), strengthened debate and pushback expectations, source precedence for challenges, no-sycophancy rule added to Communication Style.
- Rewrote `guides/architecture_principles.md`: Tier 4 AppDaemon, execution gating promoted to first-class section, construct selection clarified, helper guard wording tightened, KISS option count aligned with rest of pack.
- Fixed `patterns/execution_gating.md`: execution gating is now universal, not Class A/B scoped.
- Hardened `guides/review_and_checklist.md`: construct selection and execution gating checklist items, HAF naming corrected, stagger ranges added to Deterministic Execution.
- Collapsed 0.5.x changelog into summary block.
- Added `guides/exploratory_mode.md`: structured feasibility triage process preceding intake; defines session flow, feasibility axes, and six dispositions (proceed/chunk/redesign/shelve/pass/build it anyway).
## 0.7.0
- Added `guides/new_automation_intake.md`: spec-first intake discipline adapted from
  Superpowers brainstorming skill; mandatory for Class A/B and architecturally novel
  work; abbreviated for Class C/D routine work; includes SIC gate and construct-
  selection branch (native → template sensor → automation/script → AppDaemon)
- Added `guides/dtt_first_validation.md`: RED/GREEN/REFACTOR validation cycle reframed
  in DTT-first vocabulary; replaces TDD software framing with HA-native equivalents
- Added `guides/systematic_debugging.md`: four-phase root-cause debugging methodology
  adapted from Superpowers; HA-localized with Developer Tools and Trace substitutions
- Added complexity-scaling rule: process depth gated on impact class + novelty axes,
  not impact alone; documented in new_automation_intake.md
- Added `LICENSE` third-party attribution for Superpowers (obra/superpowers, MIT,
  Jesse Vincent / Prime Radiant, v5.0.7)
## 0.6.0
- Added `patterns/datetime_deadline.md`: canonical datetime-based deferred intent pattern
- Updated doctrine: `input_datetime` is now the default for deferred one-shot intent; `timer` limited to countdown use cases
- Introduced required overdue policy and explicit helper ownership (named owner)
- Canonicalized datetime parsing and range semantics (`as_datetime(value, default)`, `range(45, 76)` for "45–75")
- Clarified `max_exceeded: silent` as context-dependent (not universally required)
- Added scoped exception for guarded `.last_updated` / `.last_changed` access for staleness calculations
## 0.5.x
- Added HAF (Household Acceptance Factor) as a required review step,
  sub-checklist, and Core Rule.
- Formalized three-tier Decision Ladder in architecture principles;
  added `spec/entity_references.md` guardrails.
- Added `patterns/execution_gating.md` and `patterns/recursive_loop.md`.
- Added `spec/runtime.md`: attribute size limit and dict-merge guard.
- Hardened trigger/event guardrails, Jinja constraints, YAML standards,
  blueprint guidance, and secrets policy.
- Standardized terminology: backward-incompatible changes.
## 0.4.x
- Introduced System Impact Classification (Class A–D).
- Standardized restart/recovery posture and trigger-level staggering.
- Formalized Safe Jinja constraints and YAML structure expectations.
- Strengthened review flow, validation discipline (DTT-first), and changelog/versioning rules.
- Clarified control-flow, idempotency, chatter control, and integration degradation patterns.
