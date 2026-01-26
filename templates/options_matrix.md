# Option Matrix – Decision Template

> Use this when a problem has multiple viable designs. Keep KISS in mind: the goal is to surface 3–10 options, compare crisply, and choose the simplest robust path.

## Problem Statement
One sentence on what we’re solving and constraints.

## Candidate Options (3–10)
1. Option A — short name
2. Option B — short name
3. Option C — short name

## Criteria & Weights (sum to 100)
- Simplicity (KISS): 30
- Reliability (restarts, idempotency): 20
- Chatter/perf impact: 15
- Maintainability (brains vs muscles, reuse): 15
- UX/observability (logging, reason attrs): 10
- Time-to-ship: 10

## Scoring Table (0–5 per criterion)
| Option | Simplicity×30 | Reliability×20 | Chatter×15 | Maintainability×15 | UX×10 | TTS×10 | Weighted Total |
|-------:|---------------:|---------------:|-----------:|-------------------:|------:|------:|---------------:|
| A      | 4 (120)        | 5 (100)        | 4 (60)     | 4 (60)             | 3 (30)| 4 (40)| **410**        |
| B      | 5 (150)        | 3 (60)         | 5 (75)     | 3 (45)             | 4 (40)| 3 (30)| **400**        |
| C      | …              | …              | …          | …                  | …     | …     | …              |

## Notes & Risks
- Bullet notable risks or unknowns for top options.

## Decision
- Chosen option: __A__
- Why: one line tying back to KISS + top criteria.
- Follow-ups: TODOs with owners.
