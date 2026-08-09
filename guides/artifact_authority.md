# Artifact Authority — Samples & Scaffolds

This doctrine is real but not universal — it only matters when samples or
scaffolds are actually being consulted. Loaded by `workflows/development.md`,
`workflows/refactor.md`, and `workflows/architecture.md` (when comparing
structural options); not relevant to Ideation or Debug.

## Samples

Samples in `/samples/` are production-quality examples, not authority. They
illustrate acceptable output quality but do not define required structure.

**Samples are not scaffolds.** Do not use them as starting templates. Do not
imitate sample structure unless:
- The owner explicitly requests an example-derived artifact, or
- The task is to review, repair, or extend that specific sample family.

When samples are consulted, they inform the standard; they do not override
skill rules, patterns, or owner decisions.

## Scaffolds

For canonical starting structure, use `/scaffolds/` — not `/samples/`.
Scaffolds are structural authority; samples may clarify intent but may not
define structure.

| Artifact | Canonical scaffold |
|---|---|
| Automation | `/scaffolds/automation.yaml` |
| Script | `/scaffolds/script.yaml` |
| Template sensor | `/scaffolds/template_sensor.yaml` |
| Options comparison | `/scaffolds/options_matrix.md` |

## Placeholder Entities

Samples and scaffolds necessarily reference entities like `sensor.example_*`
or `light.example_*` that don't exist in any real installation — this
doesn't violate the Global Gate against inventing entities. Example/scaffold
entity IDs are deliberate, non-deployable placeholders, exempt from
existence validation only while used as repository examples. Every
placeholder must be replaced with, and mechanically validated against, real
installation entities per `guides/dtt_first_validation.md` before an
artifact built from a sample or scaffold can be considered
deployment-ready.
