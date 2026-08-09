# Ideation

## Objective

Establish whether an idea is worth building — and if so, what disposition
and structural expectations it carries into the next workflow — before any
design or implementation effort is spent. A session may legitimately end
with "don't build this."

## Invariants

- The core question is whether this is worth having, not just whether it's
  buildable: will it improve the lived experience, or create friction? HAF
  starts here, as an input to the disposition — not as something checked
  for the first time once the thing already exists.
- Draw out the idea to the point where its intent, expected outcome, and
  constraints are actually clear — meet a one-sentence idea or a fully
  worked-out one where it is. Don't proceed to disposition on an
  unconfirmed understanding of the ask.
- When the owner doesn't know a material aspect of the expected outcome,
  probe with concrete, feasible possibilities rather than dropping the
  question — an unexamined "I haven't thought about that" hides real
  decisions.
- Two HA-specific risks are non-obvious enough that they need explicit
  attention, not just general judgment: **household acceptance** (would this
  annoy, surprise, or erode trust with people who didn't ask for it?) and
  **HA-native boundary** (does this stay within native constructs and
  helpers, or does it push into template-sensor or AppDaemon territory —
  and is that complexity actually justified by the value?). Also call out
  **hardware feasibility** (does the assumed hardware exist, and does it
  actually behave the way the idea assumes?) and **dependency risk** (does
  this lean on integrations or devices that are unreliable or unproven?)
  when they're in play — these are real HA failure modes, not generic
  brainstorming hygiene.
- Ordinary judgment calls — is there real practical value, is this more
  clever than necessary — don't need a separate checklist pass; they're
  already covered by the "least complex solution that earns its complexity"
  philosophy this pack runs on. Apply it, don't re-derive it as a distinct
  step.
- Evaluate until the disposition is clear, not until every angle is
  exhausted. If a fatal flaw surfaces, say so immediately, then check
  whether it's addressable before calling a disposition.
- Both critical (poke holes) and creative (propose how it could work, or
  what would need to change) posture stay active throughout — not
  sequential phases.

## Completion

A stated disposition with rationale:

- **Build** — feasible and valuable; if too large or coupled to state as
  one piece, break it into independently-buildable chunks, each carrying
  its own disposition and its own next-workflow routing.
- **Not yet** — directionally sound but blocked (missing hardware/
  integration, unresolved dependency) or flawed as proposed (needs
  redesign) — name specifically what would need to be true for this to
  become Build.
- **Don't** — doesn't survive scrutiny: weak use case, disproportionate
  investment, or no viable path. Name what would change the answer, if
  anything.
- **Build it anyway** — no strong practical case, but genuine learning,
  experimentation, or creative value, and the owner makes that call
  consciously. Not a bypass — everything downstream applies in full.

## Transitions

Route by what's still unresolved, not by a fixed hop:

- Build / Build-it-anyway (per chunk, if chunked) → **Architecture** when
  construct tier, state/actuation separation, or control flow isn't yet
  obvious.
- Build / Build-it-anyway → **Development** directly only when the
  disposition already implies a settled, trivial structure with no design
  ambiguity left to resolve.
- Not yet / Don't → session ends here. No workflow entered until the named
  blocker or flaw is resolved.

## Applicable References

- `guides/system_impact_class.md` — when household or failure-impact risk
  is material to the disposition.
