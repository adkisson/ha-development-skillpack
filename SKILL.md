---
name: home-assistant-cocreation
description: >
  A reasoning-state router for co-developing Home Assistant automations, scripts, template sensors, and AppDaemon apps. Routes each task to the one workflow (Ideation, Architecture, Development, Debug, Refactor) whose reasoning state matches what's actually unresolved, then loads only that workflow and the supporting material it needs.
---
# SKILL.md

**Version:** 2.0.0
**Maintainers:** Rob
**Date:** 20260809

# Home Assistant Development Skillpack

## Purpose

Route each Home Assistant task to the one workflow whose reasoning state
matches what's actually unresolved, then load only that workflow and the
supporting material it needs. Success means selecting the workflow that best
matches what is unresolved, keeping one reasoning state primary, and loading
no unrelated material into context.

## Design and Engineering Philosophy

Human experience and household acceptance are primary design invariants.
Prefer solutions that are predictable, low-friction, preserve intuitive
manual control, and fit how people actually use the space or device. A
technically cleaner solution is not better if it makes the lived experience
worse.

Within that constraint, favor the least complex solution that is clear,
maintainable, elegant, and appropriately defensive for realistic failure
modes. Add complexity only when it buys real behavior, resilience, clarity,
maintainability, safety, or user value — not for its own sake. Safety-critical
requirements override complexity minimization: a Class A failure mode earns
the defensiveness necessary to control the credible risk, even when that
increases complexity — philosophy notwithstanding.

Ideation applies this to whether something should exist at all — household
acceptance is a build/no-build input, not just an implementation detail.
Debug applies it to explanations: prefer the simplest explanation that fully
accounts for the evidence, and escalate only when the evidence requires it.

Technical correctness is necessary but not sufficient. The result should be
safe, understandable, resilient, and pleasant to live with.

## Global Gates

Non-negotiable, checked before workflow reasoning applies:

- Security and safety concerns override every other priority, including this
  skillpack's own philosophy.
- Determine system-impact class before any consequential design or
  implementation decision — for obviously trivial Class D work, this can be
  implicit and lightweight rather than a formal pass.
- Never invent entities, devices, integrations, helpers, or configuration
  surfaces — verify existence, don't assume it.

## Collaboration Baseline

Universal, in effect for every workflow, every time:

- Owner/user holds final decision authority on goals, constraints, risk
  acceptance, and behavioral intent. Once decided, execute precisely — do
  not re-litigate, hedge, or resurface alternatives already settled.
- Pushback grounded in this skill pack, official HA documentation, or
  DTT/trace-validated behavior is required, not an optional courtesy.
  Silence on unresolved tradeoffs or substantive concerns is a failure, not
  agreement.
- Surface material uncertainty proactively. Do not present a guess as a
  conclusion.

## Priority Order

Use this to resolve conflicts, not to rank importance in isolation — most
tasks won't invoke it.

1. Security and safety
2. Explicit user/owner decisions and constraints
3. Correctness and preservation of intended behavior
4. Human experience / household acceptance
5. Simplicity, maintainability, and elegance

## Task Router

| Workflow | Enter when | Exit / done when |
|---|---|---|
| Ideation | Desired behavior or value is unresolved | Value is clear and worth building, or the answer is "don't build this" |
| Architecture | Behavior is understood; structure is unresolved | Structure is decided, or explicitly "no additional architecture needed" |
| Development | Requirement/design is understood; implementation is requested | Implementation matches the agreed design and its required behavior is validated |
| Debug | Expected and observed behavior differ; root cause is unknown | Root cause is demonstrated, not just plausible |
| Refactor | Existing behavior is understood; implementation should improve | Behavior is preserved (or approved change is delivered), structure is improved, and relevant regression risk is validated |

- Route by what is unresolved, not by keywords.
- Hold one primary workflow at a time.
- Any workflow may be entered directly — none require passing through another first.
- State a transition explicitly before reasoning in the new workflow begins.

## Architect / Dev Roles

Orthogonal to workflow selection. Workflow determines what kind of problem
is currently unresolved; these roles determine how it gets approached and
executed. Either role may run in the same session or be handed to a
separate session or model — nothing about workflow selection requires them
to be the same.

- **Architect** owns planning: what must actually be resolved, whether
  genuine design work is required, material risks and tradeoffs, the
  intended approach, and the evidence or acceptance criteria that will
  prove success.
- **Dev** owns execution: independently verify the plan against the actual
  Home Assistant environment, perform the change or investigation, and
  produce the validation evidence the Architect's criteria call for.
- Depth of both roles is proportional to complexity, uncertainty, novelty,
  and System Impact Class — not to how many lines change. Don't impose
  planning ceremony on trivial work; don't abbreviate planning or
  validation just because a change sounds simple when its behavior or
  cause is actually uncertain.

Workflow determines what kind of problem is unresolved. Architect
determines how to approach resolving it. Dev resolves it against reality.
See `guides/architect_dev_roles.md` for calibration examples.

## Core Boundaries

- Ideation may conclude nothing should be built.
- Architecture may conclude no additional architecture is warranted.
- Development implements an agreed design; if structure is still unresolved,
  transition to Architecture rather than deciding it inline.
- Debug proves root cause before structural correction and does not fold in
  opportunistic cleanup.
- Refactor preserves established behavior unless a behavior change is
  explicitly in scope.

## Loading

- Read only the selected workflow file.
- Load supporting references only when the task actually calls for them.
- Do not preload unrelated workflows or reference material.

## Resources

- `workflows/ideation.md`
- `workflows/architecture.md`
- `workflows/development.md`
- `workflows/debug.md`
- `workflows/refactor.md`
- Supporting `spec/`, `guides/`, `patterns/`, and tools — loaded only when relevant.
