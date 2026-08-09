# Architecture

## Objective

Decide structure — construct tier, whether derived-state logic needs
separating from actuation, and control-flow shape — before implementation
begins.

## Invariants

- System Impact Classification comes before any architectural decision;
  rigor and defensiveness scale with it.
- Choose the least-complex construct tier that fully solves the problem, via
  `guides/construct_selection.md`. Justify only choices that are materially
  non-obvious or that add complexity beyond the simplest tier — don't
  narrate ruling out every higher tier when the answer is obvious, and
  don't manufacture a fixed number of candidate options for their own sake.
- Determine whether derived-state logic and actuation need separating at
  all. A simple native automation may have no separate "brain" — forcing a
  template-sensor/automation split onto trivial work is exactly the
  complexity this pack argues against. Where separation *is* warranted,
  computed directives/state stay non-authoritative (carry a `reason` when
  the logic is non-trivial) and there is exactly one clear, deterministic
  actuation authority.
- Identify and preserve whatever safety, authority, and override precedence
  actually applies to this system. Don't assume every design needs an
  override construct — but where one is needed (manual override, guest/
  house-sitter mode, safety coordinator), it takes priority over normal
  logic and is evaluated first.
- `choose` only for provably mutually exclusive branches (discriminated by
  trigger ID, entity state, or another HA-native signal). `if/then/else` for
  prioritized or overlapping conditions. `elif` is not valid HA YAML.
- HAF is a structural question here, not only a final check: does this
  structure preserve intuitive manual control, predictable behavior, clear
  authority, and reasonable recovery? A technically clean structure that
  surprises the person living with it is not a good structure.

## Completion

- Construct tier decided, with justification present only where the choice
  isn't self-evident.
- Any required state/actuation boundary defined — or explicitly decided
  not to be needed.
- Applicable safety/authority/override precedence identified and reflected
  in the design.

## Transitions

- → **Development** once structure is decided.
- → **Ideation** if feasibility doubt resurfaces during design.
- "No additional architecture needed" is a valid exit for trivial or
  already-settled work.

## Applicable References

- `guides/construct_selection.md` — when the construct tier isn't already
  obvious.
- `guides/system_impact_class.md` — when not already classified upstream.
- `patterns/execution_gating.md` — when the control-flow gating shape is
  non-trivial.
- `scaffolds/options_matrix.md` — when comparing multiple viable structural
  options.
- `guides/artifact_authority.md` — when samples or scaffolds are being
  consulted to inform the decision.
