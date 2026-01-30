# Review & Checklist — How‑To + Rubric (Single Source of Truth)

Use this for every change. Goal: **simplest robust** solution that is restart‑safe, idempotent, and observable.

## A) Review Flow (Detailed)
0) **System Impact Classification**: Before review, classify the system by **worst-credible impact if it fails** (Class A–D) using `/guides/system_impact_class.md`.
   - Record the selected class.
   - Briefly note the worst-credible failure mode.
   - Document any **Context Elevation** reasoning if applicable.
   - The assigned class determines the required rigor for all subsequent review steps.
1) **KISS gate**  
   - Propose a simpler alternative if one exists; document why rejected.  
   - For complex problems, present **3–10 options** and choose the simplest viable.
2) **Syntax & Structure**  
   - Use **current release -1** as minimum YAML/Jinja standards (per Home Assistant docs); reject deprecated or "also works" syntax.
   - GUI‑friendly YAML: `alias`, `description`; plural keys; `id:` per trigger; `alias:` at all levels (triggers/conditions/actions/variables/repeat branches).
   - **Comments only in template sensors** (`#debug_*`, `# deps:`, `# verified:`). Automations and scripts use `alias:` and `description:` only.
3) **DTT Probes (Developer Tools → Template) — Mandatory Pre-Deployment**  
   - Test all Jinja, entity references, and sensor outputs **before** writing YAML. Verify entities exist with correct names (account for system naming quirks), and confirm sensors produce expected outputs.
   - Test with actual entity states from your HA instance. For unavailable entities (e.g., solar production at night) or extreme values, confirm the entity exists and structure, then override with test values to validate logic branches.
   - If logic passes DTT but fails after deployment, iteratively refine in DTT until it works live.
   - Use cookbook snippets for availability/defaults, entity name checks, time math.
4) **Traces vs DTT**  
   - Use **DTT** for template logic and unit‑style checks.  
   - Use **Automation Traces** only when orchestration/timing must be verified. No repo‑wide `store_traces: true` mandate.
5) **Live Test**  
   - Exercise a happy‑path trigger. Observe Logbook only for significant events; otherwise remain silent.
6) **Best-in-Class Review (Intent Alignment)**  
   - For all code, ask:
     1. **Primary intent?** (Lights ON = speed; Lights OFF = validation; Recovery = network efficiency; Notification = reliability)
     2. **Implementation matches intent?** (Minimize checks for ON; rich validation for OFF; sequential+guarded for recovery)
     3. **Conditions in right place?** (Cheap checks first in conditions block; expensive operations only on needed paths)
     4. **Network traffic minimized?** (Z-Wave/Zigbee sequential+delayed; HA helpers redundant-call-safe; light transitions batched)
7) **Wait Conditions & Timeouts**  
   - Prefer `wait_template` with timeout over fixed delays when feasible.
   - Include `continue_on_timeout: true` for graceful fallthrough.
   - Guard exclusion lists: always check for empty string `''` in negation filters (e.g., `not in ['dead','unknown','unavailable','']`).
8) **Restart & Recovery**  
   - Critical paths: **fixed `<10s` `for:`** on `timer.ha_startup_delay` trigger.  
   - Non‑critical: **randomized `for:` (e.g., 45–75s)** on the trigger.  
   - No artificial `delay` actions for staggering; use the trigger's `for:` instead.
9) **Idempotency & Chatter**  
   - Guard device calls; batch by group/area; rate‑limit noisy inputs; minimal bounded retry.
10) **Overrides & Safety**  
   - Manual/guest/safety modes always win. See `/spec/safety.md` for patterns.
11) **Breaking Changes (12 months)**  
   - Any refactor or enhancement: review last 12 months of [HA Release Notes](https://www.home-assistant.io/latest-release-notes/). Proactively adapt code for breaking schema/attribute/behavior changes. Document "BC review: done/N/A".
12) **Changelog & Versioning**
   - Format: `YYYYMMDD-HHMM: Single sentence summary.`  
   - Timezone: **America/Los_Angeles** (local time).
  a) **Automations & Scripts**  
    - Add **CHANGELOG** block in YAML `description:` (not YAML `#` comments).  
    - `description:` is Markdown-rendered; when using list items (`- ...`), a blank line MUST separate `CHANGELOG:` from the first item.
  b) **YAML-defined entities (e.g., template sensors)**  
    - Use YAML `# CHANGELOG:` comments near the top of the definition.
13) **Exceptions**  
   - Deviations allowed **only if documented inline** (in `description`, `alias`, or sensor comments).
14) **Self‑Critique & Verdict**  
   - Risks, alternatives, rollback. Verdict categories below.

## B) Verdicts
- **Production‑ready** · **Low‑risk w/ notes** · **Needs revision** · **Do not ship**

## C) Copy‑Paste Checklists
### Master
- [ ] KISS & scope clear; simpler alternative considered/ruled out
- [ ] GUI‑friendly automation/script YAML; `alias:` mandatory at all levels; `description:` at automation/script/sensor level; `id:` per trigger
- [ ] **Comments policy**: Automations/scripts are **comment-free YAML**; intent lives only in `alias:` and `description:`. Template sensors **must** include inline comments and commented `#debug_*` attributes. AppDaemon comments for complex logic only
- [ ] **Startup triggers** only when post-restart actions needed (state recovery, initialization); avoid for passive automations
- [ ] Brains vs muscles respected; scripts for fan‑outs; concurrency sane
- [ ] Control flow safety: `if/then` wraps `choose/default` branches (prevents unwanted default execution)
- [ ] Restart gates on triggers (`timer.ha_startup_delay` w/ appropriate `for:`); **no action delays**
- [ ] Jinja safety: safe defaults (`| float(0)`, `| int(0)`)
- [ ] No Python methods (`.get()`, `.items()`, `.total_seconds()`, etc.)
- [ ] String normalization: `| lower | trim`
- [ ] Time math: `as_timestamp()` not `.total_seconds()`
- [ ] Type safety: raw/typed variables separated; comparisons use typed with tolerance
- [ ] Availability: `has_value()` for entity checks (1)
- [ ] Event-driven preferred; if polling, ≥60s & justified
- [ ] Fast-fail condition ordering: cheap checks first; likely failures early; expensive Jinja last
- [ ] Chatter minimized; idempotent guards; groups/areas; rate‑limit as needed
- [ ] Observability: `reason` attr when external or ambiguous inputs exist; production logs only for significant events
- [ ] DTT probes provided; traces referenced if orchestration validated
- [ ] Best-in-class review completed: intent clarity, implementation alignment, condition placement, network efficiency
- [ ] Wait strategies: `wait_template` preferred; exclusion lists guard empty string; `continue_on_timeout: true` used
- [ ] Breaking changes (12 months) reviewed; documented as "BC review: done/N/A"
- [ ] Exceptions documented inline (description/alias/comments)
- [ ] Risks/alternatives/rollback documented; verdict chosen

### Automation Sub‑Checklist
- [ ] Minimal, precise triggers; unique `id` and `alias`
- [ ] Randomized vs fixed `for:` per criticality on HA restart
- [ ] Variables precomputed once; branches small & ordered cheap→expensive
- [ ] No device calls inside loops without guards
- [ ] No logging; description/alias carry intent only
- [ ] Trigger coverage: each trigger ID referenced exactly once; else: branch logs trigger.id for catch-all validation

### Script Sub‑Checklist
- [ ] `mode` and `max` reflect expected concurrency
- [ ] Centralizes device calls; idempotent guard; optional bounded retry
- [ ] No logging except significant failure paths
- [ ] No comments; description/alias carry context

### Template Sensor Sub‑Checklist
- [ ] Minimal trigger set + HA startup gate
- [ ] Clear directive state + `reason` attribute
- [ ] Safe reads; expected commented `#debug_…` attributes
- [ ] Optional `# deps:` and `# verified:` documentation for clarity

### Time Math & Timezone Safety Sub-Checklist
- [ ] Conversions explicit and consistent (`as_timestamp()` for math; `as_datetime()` only for parsing/display)
- [ ] Local vs UTC intentional (`now()` vs `utcnow()`); no mixing within a calculation
- [ ] Staleness/age math safe for `none`/invalid datetimes (guard + safe default like `999999`)
- [ ] Time-of-day logic uses numeric comparisons (hour/minutes), not `"HH:MM"` string comparisons
- [ ] Randomized delays/schedules correct and deterministic for intent (inclusive ranges; `range(45, 76)` for "45–75")
- [ ] Once-per-day schedules account for DST (anchored `at:` vs elapsed-time logic)

### Deterministic Execution
- [ ] No templated randomization in critical paths (or documented as accepted tradeoff)
- [ ] Post-restart gates use 45–75s random `for:` delay (prevents thundering herd)


-----
(1) If the source is known to emit blank strings, add and (states(...)|trim) != ''.
