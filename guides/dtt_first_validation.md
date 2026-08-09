# DTT-First Validation

**Source:** Adapted from Superpowers `test-driven-development` skill
(obra/superpowers, MIT License, Jesse Vincent / Prime Radiant, v5.0.7)

## Purpose

State expected behavior explicitly before deployment approval. Validate
logic in Developer Tools → Templates before deployment. Confirm
orchestration separately with Automation Traces.

No Jinja-bearing or entity-dependent artifact may be approved for deployment until DTT/entity validation is complete. Draft YAML and patch review may occur before DTT when the artifact is explicitly marked not deployment-ready.

**Core principle:** Unvalidated logic is unfinished work, regardless
of how confident the implementation looks.

## The Iron Law

```
NO JINJA-BEARING LOGIC DEPLOYED WITHOUT DTT VALIDATION FIRST
```

Validation depth scales with logic complexity. Simple, non-branching
service-call-only changes require only entity existence confirmation.
Conditional or computed logic requires full template validation.

Applies to:
- Template sensors (always)
- Conditions containing Jinja expressions
- Trigger `for:` values using Jinja
- Any computed value driving automation behavior
- Bug fixes that touch templates or conditions

## Two Obligations: Entity Validation and Logic Validation

DTT validation is two separate obligations, not one. Completing one does
not satisfy the other.

- **Entity validation**: every referenced entity must be mechanically
  verified to exist (Step 3, below) — not inferred, and not handed back to
  the user to check one by one.
- **Logic validation**: where DTT can exercise the template/state logic,
  the test must be falsifiable and must demonstrate the logic behaves
  correctly — not merely that it renders (Step 2, below).

Entity-existence validation alone does not prove behavioral correctness. A
template that references only confirmed, existing entities can still
compute the wrong answer.

## The Validation Cycle

### Step 1 — State Expectations Explicitly

Before opening Developer Tools, write down in plain terms:

- What should this template return when everything is working?
- What should it return when a key entity is unavailable?
- What should it return at startup before helpers are restored?
- What downstream behavior depends on this output?

This step is not optional. Skipping it means you are validating
without a target — you will not recognize a wrong result when you
see one.

### Step 2 — Validate Logic in Developer Tools

Prefer validating a single combined Jinja expression when it matches
the real decision path and remains understandable. Break validation
into smaller pieces only to isolate ambiguity, debug failures, or
verify complex interacting logic. Do not validate components in
isolation when the production behavior depends on their interaction —
fragmented checks hide interaction failures and produce false
confidence.

Run validation in Developer Tools → Templates against meaningful
current state. Confirm outputs match stated expectations.

**Validate representative states.** Current live state may be
favorable. If your stated expectations include unavailability,
startup, or degraded behavior, verify your template handles those
paths correctly — either by reading logic carefully against safe
defaults, or by using mock variables within the expression (e.g.,
temporary `{% set %}` values substituting for live entity states)
to simulate those states.

See `cookbooks/dtt_techniques.md` for combined expression patterns
and degraded-state mock examples.

**Falsifiability requirement.** A validation test must be capable of
failing for at least one plausible incorrect implementation. Do not treat a
test as sufficient merely because expected text, an entity ID, or a
configuration fragment appears in the rendered output — that shows the
template rendered, not that its logic is correct.

For logic with branching, thresholds, precedence, fallback behavior, or
overrides: test the expected path **and** at least one materially
different state, boundary, or negative case that would expose an incorrect
implementation. A threshold condition validated only against a value that's
obviously above the threshold hasn't been tested — validate a value near
the boundary too.

### Step 3 — Confirm Entity References

Every entity referenced in the artifact must be validated explicitly
before deployment. Do not rely on naming conventions, inferred
corrections, or assumed spelling — entity naming in real systems is
messy: possessive apostrophes become underscores (HA converts `'`
to `_`, so "Kid's Room" becomes `kid_s_room`, not
`kids_room`); real names, nicknames, and abbreviations are used
inconsistently across devices; integrations may append suffixes or
modify names on re-pairing.

**Validation proceeds in two steps when a usable-state check fails.**

#### Step 3a — Run explicit usable-state check for every entity

```jinja
{# Validate all entities used in this artifact #}
{{ has_value('sensor.kid_s_room_temp') }}
{{ has_value('binary_sensor.front_door') }}
{{ has_value('input_boolean.guest_mode') }}
```

`has_value()` returns `false` when an entity is missing or its state
is `unknown` or `unavailable`. All lines should return `true` under
normal operating conditions. If any return `false`, determine whether
this reflects a naming or reference issue or a valid transient state
before proceeding. If a naming issue, move to Step 3b before
stopping.

When you genuinely need to confirm an entity is defined regardless
of its current state (rare):

```jinja
{{ states.sensor.your_entity_id is not none }}
```

#### Step 3b — Attempt discovery before asking (strongly suggested)

When Step 3a returns `false` for any entity and a naming issue is
suspected, attempt to surface the correct name using area, label, or
integration queries before stopping:

```jinja
{# Surface candidates by area, label, or integration #}
{{ area_entities('Kid\'s Room') | list }}
{{ label_entities('climate') | list }}
{{ integration_entities('zwave_js') | list }}
```

Scan the candidate list for the intended entity. If found, use the
correct name and re-run Step 3a.

**General principle:** When any validation or check fails, the first
course of action is always to proactively attempt to identify the
correct answer before stopping to ask. Stopping to ask is the last
resort, not the first response.

If discovery does not surface a match, stop and request the
validated entity name — do not guess, infer, or normalize spelling
by assumption.

See `cookbooks/dtt_techniques.md` for entity name validation patterns.

### Step 4 — Refactor and Re-validate

After logic is confirmed correct:
- Simplify Jinja expressions (remove redundant filters, clarify logic)
- Tighten conditions
- Confirm chatter guards are correct
- Re-run Developer Tools validation to confirm output is unchanged

## Relationship to Automation Traces

Developer Tools → Templates validates **logic** — computed values,
conditions, state expressions.

Automation Traces validate **orchestration** — trigger firing,
condition evaluation sequence, and action execution in live context.

DTT validation must precede trace review. A clean trace running
unvalidated logic is not a passing result.

## Validation Checklist

Before any logic-bearing artifact is considered ready for deployment:

- [ ] Expected outputs stated explicitly before validation began
- [ ] Logic validated as a combined expression matching the real
      decision path; fragmented only where needed to isolate
      ambiguity or debug failures
- [ ] Validated against meaningful state, including unavailability
      and startup conditions
- [ ] For branching, threshold, precedence, fallback, or override logic:
      at least one materially different state, boundary, or negative case
      tested in addition to the expected path — the test can fail for a
      plausible incorrect implementation, not just confirm rendering
- [ ] All entity references mechanically validated: use has_value() where usable state matters; use defined-entity checks where existence matters. Not inferred, not handed to the user to check one by one.
- [ ] Defensive Jinja patterns applied and confirmed in output —
      see `snippets/jinja_patterns.md` for reference (safe defaults,
      type coercion, text normalization, structured input handling,
      and others)
- [ ] Refactor complete — logic simplified, output still correct

## Common Rationalization Failures

| Excuse | Reality |
|---|---|
| "It looks correct" | Run it. Looking correct proves nothing. |
| "The expected text/entity ID showed up in the output" | Rendering isn't proof. A test that can't fail for a plausible incorrect implementation hasn't tested anything — validate a case that would expose a wrong implementation too. |
| "I'll run separate checks for each piece" | Fragmented checks hide interaction failures. Validate the real decision path together. |
| "The entity name is obvious" | It is not. Validate every referenced entity explicitly — do not normalize apostrophes, nicknames, or spelling by assumption (`kid_s_room` not `kids_room`). |
| "`unknown` means the entity is missing" | `unknown` is also a valid runtime state for entities that exist. Use `has_value()` for usable-state checks; use `states.domain.object_id is not none` when defined-entity confirmation is required. |
| "Current state looks right" | Confirm safe defaults cover unavailability and startup paths too. |
| "I'll validate after deployment" | DTT/entity validation is the gate for deployment approval. Draft YAML may exist before DTT only when explicitly marked not deployment-ready. |
| "This is a simple fix" | Simple fixes touch logic. Logic requires DTT. |
| "No Jinja, just a service call" | Confirm entity existence. Full cycle not required. |
| "It returned false, I'll ask" | Attempt discovery first — area, label, or integration queries often surface the correct name without interruption. |
