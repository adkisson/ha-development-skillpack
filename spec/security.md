# SECURITY HARD STOP — Secret & Identifying Material

Artifacts containing secret or identifying material are **invalid and must not be published, reviewed, or partially output**.

A narrow class of operationally-required identifiers with no available secrets mechanism is permitted under strict conditions — see **Narrow Exception** below. All other secrets and identifying material are prohibited without exception.

If detected, the assistant must output only: "REJECTED: Secret or identifying material detected in artifact."

No redaction.
No transformation.
No partial publication.
No remediation guidance unless explicitly requested.

---

## Prohibited Content (Non-Exhaustive)

### Secrets
- Passwords
- API keys
- Long-lived access tokens
- Bearer tokens
- Client secrets
- Private keys
- Webhook secrets
- HMAC signing keys
- OAuth refresh tokens
- Base64-encoded secrets
- URLs containing embedded credentials *(see Narrow Exception for the limited case where no alternative exists)*

### Identifying Material
- Email addresses  
- Phone numbers  
- Account numbers  
- User IDs tied to external systems  
- Tenant IDs  
- Organization identifiers  
- Device serial numbers when externally registered  
- Any data that uniquely identifies a real person or external account  

No exceptions are permitted, except as defined in the Narrow Exception section below for operationally-required identifiers with no available secrets mechanism.

This rule applies even if:
- The value is labeled as “fake” or “example”
- The value is documented as temporary
- An override is requested
- A reviewer approves inclusion
- The artifact is internal-only or non-production

**Placeholders are not secrets.** Values such as `redacted`, `REPLACE_ME`, `YOUR_TOKEN_HERE`, or similar substitution markers do not trigger this rule — they contain no secret material for the LLM to ingest or reproduce. The concern is real credential values appearing in artifacts, not instructional placeholders.

Documented exceptions, waivers, or override mechanisms are not allowed.

---

## Approved Handling

Credentials and identifiers must be supplied via:

- `secrets.yaml`
- Environment variables
- Home Assistant integration UI configuration
- Runtime configuration not stored in versioned artifacts

Artifacts must reference only secret keys — never literal values.

---

## Narrow Exception — Operationally-Required Identifiers

Automations and scripts cannot read from `secrets.yaml`. For a small class of identifiers that are operationally necessary and have no available secrets mechanism, literal values are permitted under strict conditions.

**Permitted**:
- Telegram chat IDs and similar notification routing identifiers in service calls
- ZHA device IEEE addresses in event triggers where no stable entity exists
- URLs where query parameters are routing or addressing only (station IDs, grid coordinates, resource paths) — no authentication component present
- URLs with embedded API keys only as a documented last-resort exception when the service has no alternative authentication mechanism available in HA, no REST integration/header-based path exists, and the URL is required for the artifact to function

**Conditions that must all be met**:
- The value is a routing, targeting, or addressing identifier — never an authentication credential, token, key, or password, except for the explicitly allowed embedded-URL API-key last-resort case above
- No alternative secrets mechanism exists for this value in the current HA context
- The value is documented inline in `description:` explaining why it cannot be externalized
- The value does not uniquely identify a real person by name, contact detail, or account credential

**Still prohibited regardless of mechanism**:
- API keys, tokens, passwords, and secrets of any kind — except the explicitly allowed embedded-URL API-key last-resort case meeting all conditions above
- Email addresses, phone numbers, and contact details
- Any value that could authenticate or impersonate a user or service
- URLs with embedded credentials where an alternative auth mechanism exists (HA integration, REST sensor with headers, etc.)

---

## Review & Validation Gate

- Secret & identifying material scan occurs **before** schema validation and architectural review.  
- Detection is a blocking failure (no downgrade to warning).  
- PRs touching credential plumbing require owner review.  
- Reviewers must grep diffs for patterns including:
    token|api_key|Bearer|Authorization|password|client_secret|@|https?://.*@
