# System Impact Class

This guide defines how systems are classified by **worst-credible impact if they fail**.  
Impact classification determines required rigor, validation depth, and acceptable tradeoffs throughout design and review.

Classes are ordered by decreasing **severity** from **Class A (most severe)** to **Class D (least severe)**.

---

## Class A — Safety, Security & Threat Control

Failure can enable physical harm, unsafe access, loss of control over physical systems, or create exploitable vulnerabilities to theft or tampering.  
Includes systems where automation failure materially increases occupant risk or compromises control of physical access or safety-critical mechanisms.

---

## Class B — Property Damage & Significant Cost

Failure can cause **material property damage or material financial loss** without directly endangering occupants.  
These systems require conservative design and predictable failure recovery.

---

## Class C — Comfort & Nuisance

Failure is disruptive or annoying but does not create safety, security, or material damage risk.  
Design these systems for self-correction or easy manual override to maintain household acceptance.

---

## Class D — Cosmetic & Informational

Failure has no material real-world consequence beyond visibility or convenience.  
These systems prioritize simplicity and low maintenance.

---

## Classification Rules

Classification reflects **credible failure modes**, not worst-case scenarios or implausible cascades.  
If multiple classes plausibly apply or materiality is unclear, **assume the most severe applicable class** and verify with the user before proceeding.

---

## Context Elevation Rule

Elevate classification by one or more classes when normal operating conditions could create consequences matching a higher-severity class **and** the automation directly controls or gates execution of protective or mitigating operations for those consequences.

---

## Risk Assessment (Proportional)

Risk assessment is applied **only when required by System Impact Class** and is proportional to the system’s potential impact.

- **Class A**: Risk assessment is **required**.
- **Class B**: Risk assessment is **required** (brief format).
- **Class C**: Risk assessment is optional and often implicit.
- **Class D**: Risk assessment is not used.

When required, express risk using the following minimal structure:

- **Probability**: Likelihood of the failure mode occurring under normal conditions.
- **Impact**: Severity of the worst-credible consequence if it occurs.
- **Mitigation / Acceptance**: Design measures that reduce risk, or explicit acceptance of residual risk.
- **Detection / Recovery**: How failure is detected and what restores safe operation.

Risk assessment reflects **credible failure modes**, not worst-case scenarios or speculative cascades.
