# GUI Editor Quirks (Round-Trip Safety)

The behaviors below are expected when editing automations or scripts in the Home Assistant GUI, switching to YAML, and then returning to the GUI. They should not be treated as bugs or regressions.

## 1. Jinja Template Reflow in YAML Fields

**Symptom**  
Multi-line Jinja templates embedded in YAML scalar fields may have whitespace, line breaks, or inline statements reflowed after GUI edits or YAML parsing.

This can occur in any YAML field that accepts a Jinja-rendered scalar, including (but not limited to):

- `for:` durations (seconds, minutes, etc.)
- `value_template`
- `condition: template`
- `data:` blocks
- `variables:` blocks
- Script items: definitions
- Any field using `>`, `|-`, or `>-` with embedded Jinja

**Before** (hand-written YAML):
```yaml
value_template: >-
  {% set x = 1 %}
  {% if x > 0 %}
    true
  {% else %}
    false
  {% endif %}
```

**After GUI edit or round-trip parse:**
```yaml
value_template: >-
  {% set x = 1 %} {% if x > 0 %}
    true
  {% else %}
    false
  {% endif %}
```

**Verdict**  
Acceptable. The rendered Jinja output is unchanged; only formatting differs.

**Guidance:**
- Semantic correctness matters; formatting does not. Whitespace stability is not guaranteed for embedded Jinja.
- For `for:` fields, the rendered value **must resolve to a numeric duration** (integer or float seconds); formatting changes that don't alter the numeric value are not defects.
- Ensure templates reliably render to the expected scalar type (boolean, number, string, list).

---

## 2. Condition Nesting (AND / OR Wrapping and Reordering)

**Symptom**  
Explicit `condition: and` wrappers may be added or removed, and condition order may shift—especially inside OR branches.

**Before** (flat implicit AND):
```yaml
if:
  - condition: trigger
    id: my_trigger
  - condition: state
    entity_id: sensor.x
    state: "on"
  - condition: or
    conditions: [...]
```

**After GUI edit** (explicit AND wrapper):
```yaml
if:
  - condition: and
    conditions:
      - condition: trigger
        id: my_trigger
      - condition: state
        entity_id: sensor.x
        state: "on"
      - condition: or
        conditions: [...]
```

**Verdict**  
Functionally identical.

**Guidance:**
- The skill prefers flatter structures for readability.
- GUI-introduced nesting is not a defect.
- Reviewers may flatten for clarity but must not block deployment over this.

---

## 3. State String Quoting Normalization

**Symptom**  
State values may toggle between quoted and unquoted forms.

**Before:**
```yaml
to: "on"
```

**After GUI edit:**
```yaml
to: on
```

**Verdict**  
Both are valid YAML and functionally identical.

**Guidance:**
- Do not enforce quote style.
- Accept quoted or unquoted state strings equally.

---

## 4. Entity ID Scalar vs List Formatting

**Symptom**  
A single `entity_id` may toggle between scalar and list notation.

**Before:**
```yaml
entity_id: binary_sensor.presence
```

**After GUI edit:**
```yaml
entity_id:
  - binary_sensor.presence
```

**Verdict**  
Functionally identical.

**Guidance:**
- Accept both forms.
- GUI often prefers list notation for consistency.

---

## 5. Key Reordering After GUI Alias Edits (Any Level)

**Symptom**  
When editing an `alias` field in the Home Assistant GUI, the GUI may reorder keys within the same YAML mapping. This behavior is not limited to triggers and can occur at multiple levels, including:

- Triggers
- Conditions
- Actions
- Choose / If / Then blocks
- Script steps
- Any YAML object where an `alias` is edited via the GUI

**Before** (hand-written YAML):
```yaml
- id: my_block
  condition: state
  entity_id: sensor.x
  alias: My condition
```

**After GUI edit:**
```yaml
- condition: state
  entity_id: sensor.x
  alias: My condition (edited)
  id: my_block
```

(Keys reordered; semantic meaning unchanged.)

**Verdict**  
Functionally identical.

**Guidance:**
- YAML key order is not semantically meaningful in Home Assistant; the skill requires stable `id:` values and clear `alias:` fields, not fixed key ordering.
- Accept GUI-induced reordering at any level of the automation or script; do not enforce key order during review.
- **Rule of thumb**: If the same keys exist with the same values, key ordering differences are never a defect.

---

## 6. Empty Blocks Auto-Insertion

**Symptom**  
The GUI automatically inserts empty structural blocks in YAML that are omitted in hand-written configurations. These blocks are harmless but appear inconsistent after round-trips.

Common examples:

**Global `conditions:` block** (when none exist in pure YAML):
```yaml
# Pure YAML (no top-level conditions):
actions:
  - if: [...]
    then: [...]

# After GUI edit:
conditions: []
actions:
  - if: [...]
    then: [...]
```

**`metadata: {}` and `data: {}` on actions:**
```yaml
# Pure YAML:
- action: timer.cancel
  target:
    entity_id: timer.x

# After GUI edit:
- action: timer.cancel
  metadata: {}
  target:
    entity_id: timer.x
  data: {}
```

**Other possible empty blocks:**
- `variables: {}` on scripts
- `repeat: {}` (when repeat logic not used)
- `data: {}` on actions that don't require data parameters

**Verdict**  
Acceptable. Empty blocks are syntactically valid per Home Assistant schema and have no functional impact. An empty `conditions: []` block is equivalent to omitting the block entirely.

**Validation Standard**  
Consult Home Assistant's [Automation](https://www.home-assistant.io/docs/automation/) and [Script](https://www.home-assistant.io/docs/scripts/) docs. If the schema marks a field optional and accepts empty values without consequence, the block is harmless.

**Guidance:**
- YAML-only workflows can omit empty blocks for cleanliness.
- GUI-edited automations will re-add them; this is expected.
- Do not spend review time removing or flagging empty blocks.
- **Critical rule**: If an empty block is harmless per Home Assistant's published standards, it must not be corrected in code review and must not require a changelog entry.
- The blocks are documentation of GUI-safe structure; removing them only to have them re-added on next edit wastes reviewer time.

---

## Guidance for Reviewers

**YAML-only workflows** (git + editor):  
Maintain clean formatting; GUI quirks won't appear.

**GUI-heavy workflows**:  
Expect these changes on every edit. Don't block reviews over formatting.

**Mixed workflows**:  
Accept reformatting as the cost of GUI convenience. Document behavioral/architectural changes in changelogs only, not YAML churn.

**Skill enforcement**:  
Review substance (intent, logic, safety, efficiency), not formatting. GUI-induced changes are neutral.

---

## Changelog Accuracy Rule

If a changelog entry claims a behavioral change (e.g., "excluded dog bed from fallback logic"), the code must reflect that behavior.

**Formatting-only GUI artifacts:**
- Do not require changelog entries.
- Must not be described as refactors or fixes.
- Changelogs exist to prevent regressions—not to document YAML churn.

---

## Summary Table

| Quirk | Triggered By | Functional Impact | Review Action |
|---|---|---|---|
| Jinja template reflow | GUI parse/edit | None | Accept |
| AND/OR wrapping | GUI edit | None | Accept or flatten |
| State quoting | YAML parser | None | Accept both |
| Entity scalar vs list | GUI preference | None | Accept both |
| Key reorder (alias edit) | GUI alias edit | None | Accept |
| Empty blocks | GUI structure enforcement | None | Accept; do not "correct" |

---

## Skill Evolution Note

If additional GUI quirks are discovered that materially affect:
- Correctness
- Maintainability
- Or reviewer clarity

Document them here or open an issue in the Skill Pack repository. The skill is expected to evolve with real-world usage patterns.
