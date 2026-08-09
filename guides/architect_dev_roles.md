# Architect / Dev Roles — Calibration Examples

Elaborates `SKILL.md`'s Architect/Dev Roles principles with two worked
examples. The principles themselves — what each role owns, and that depth
scales to the problem, not the workflow — live in `SKILL.md`; this file
exists so `SKILL.md` doesn't have to carry worked examples to stay legible.

**Trivial case — alias reword.** Architect's pass is one line: "display-only,
behavior-preserving." Dev makes the edit and confirms it. Anything more is
process theater — the risk doesn't justify it.

**High-uncertainty case — automation firing at 3 a.m. with no known cause.**
Architect has real work to do first: establish the expected behavior,
identify candidate authoritative paths to the light, frame falsifiable
hypotheses, and decide which evidence surfaces actually matter — Traces,
Logbook/history, other automations' runs, restart state, integration
health, physical/manual input — and what would count as demonstrated root
cause. Dev then investigates against that plan, returns evidence, and
executes only the correction the evidence supports. If the evidence reveals
conflicting automation authority over the same entity, Architect may
genuinely move into architecture and redesign the control boundary — that's
a legitimate escalation, not scope creep.

The difference in role depth isn't caused by the workflow or the size of
the diff — proportionality applies within every workflow. Scale the
Architect and Dev passes to the actual complexity, uncertainty, novelty,
and impact of the problem.
