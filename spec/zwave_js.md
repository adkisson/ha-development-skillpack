# Z-Wave JS Central Scene Authoring

Central Scene gestures are stateless Z-Wave JS value notifications. Capture a live gesture in Tools → Events using `zwave_js_value_notification` before authoring automation YAML.

Home Assistant documents Central Scene notifications as `zwave_js_value_notification` events. Observed and documented payloads include fields such as `device_id`, `endpoint`, `command_class`, `command_class_name`, `property`, `property_key`, `value`, and `value_raw`.

## TL;DR

| Pattern | Use for | Trigger breadth | Routing location | Main footgun |
|---|---|---|---|---|
| Exact device trigger | Fixed dimmer/switch gestures | Narrow | Trigger-level | `value:` may require raw integer while runtime uses label |
| Raw event trigger | Many-button remotes, broad routing, exploration | Broad | Action conditions | Must normalize or verify `value` format |

Default to exact device triggers for fixed paddle gesture sets. Use raw event triggers for many-button controllers, exploratory capture, or when device-trigger schema is unavailable.

---

## Pattern A — Fixed gesture set: exact device triggers

Use for dimmers and switches where a small number of gestures are bound.

```yaml
triggers:
  - trigger: device
    domain: zwave_js
    device_id: <device_id>
    type: event.value_notification.central_scene
    subtype: Endpoint 0 Scene 001
    command_class: 91
    endpoint: 0
    property: scene
    property_key: "001"
    value: 3
    id: up
    alias: Double tap up
```

Multiple exact triggers may share the same `id:` when they intentionally route to the same action branch.

```yaml
triggers:
  - trigger: device
    domain: zwave_js
    device_id: <device_id>
    type: event.value_notification.central_scene
    subtype: Endpoint 0 Scene 001
    command_class: 91
    endpoint: 0
    property: scene
    property_key: "001"
    value: 3
    id: up
    alias: Double tap up
  - trigger: device
    domain: zwave_js
    device_id: <device_id>
    type: event.value_notification.central_scene
    subtype: Endpoint 0 Scene 001
    command_class: 91
    endpoint: 0
    property: scene
    property_key: "001"
    value: 4
    id: up
    alias: Triple tap up
```

### Footgun: trigger schema value vs runtime value

For Z-Wave JS Central Scene device triggers in the tested HA schema, `value:` is the raw integer from `value_raw`.

At runtime, `trigger.event.data.value` may surface the label string.

Example observed mapping:

```text
Captured event payload:
  value: KeyPressed2x
  value_raw: 3

Working device trigger:
  value: 3

Action condition:
  trigger.event.data.value == 'KeyPressed2x'
```

Do not assume the trigger YAML `value:` and runtime `trigger.event.data.value` use the same representation.

### Hand-authored YAML risk

For Central Scene device triggers, `endpoint:` may be required by the schema. Omitting required schema fields can produce load-time errors such as:

```text
Message malformed: required key not provided @ data['endpoint']
```

Prefer UI-generated device-trigger YAML as the starting point, then harden it for production.

---

## Pattern B — Broad raw event trigger

Use for many-button scene controllers, exploratory capture, or devices where the exact device-trigger schema is unavailable.

```yaml
triggers:
  - trigger: event
    event_type: zwave_js_value_notification
    event_data:
      domain: zwave_js
      device_id: <device_id>
      endpoint: 0
      command_class: 91
      command_class_name: Central Scene
      property: scene
```

Route in actions using:

```text
trigger.event.data.property_key
trigger.event.data.value
trigger.event.data.value_raw
```

For a known single dimmer or switch, direct reads are usually enough after verifying the payload:

```yaml
actions:
  - variables:
      scene: "{{ trigger.event.data.property_key }}"
      key: "{{ trigger.event.data.value }}"
```

For high-cardinality remotes, normalize defensively:

```yaml
actions:
  - variables:
      scene: "{{ trigger.event.data.property_key }}"
      label_value: "{{ trigger.event.data.value }}"
      raw_value: "{{ trigger.event.data.value_raw }}"
      value_map:
        0: KeyPressed
        1: KeyReleased
        2: KeyHeldDown
        3: KeyPressed2x
        4: KeyPressed3x
        5: KeyPressed4x
        6: KeyPressed5x
      key: >
        {% if label_value in ['KeyPressed','KeyHeldDown','KeyReleased',
            'KeyPressed2x','KeyPressed3x','KeyPressed4x','KeyPressed5x'] %}
          {{ label_value }}
        {% elif raw_value in value_map %}
          {{ value_map[raw_value] }}
        {% else %}
          unknown
        {% endif %}
```

Treat the map as a fallback convenience, not an authority. Captured payloads are authoritative for the device being automated.

---

## Validation checklist

1. Capture the live gesture payload in Tools → Events using `zwave_js_value_notification`.
2. Confirm `device_id`, `endpoint`, `property_key`, `value`, and `value_raw`.
3. If using exact device triggers, start from UI-generated YAML when possible.
4. Reload automations to catch schema errors.
5. Run each gesture and inspect the trace.
6. Confirm the trigger fires only for intended gestures.
7. Confirm action conditions compare against the runtime representation actually present in `trigger.event.data`.
