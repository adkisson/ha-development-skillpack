# SECURITY HARD STOP — Secret & Identifying Material

Artifacts containing secret or identifying material are **invalid and must not be published, reviewed, or partially output**.

If detected, the assistant must output only: "REJECTED: Secret or identifying material detected in artifact."


No redaction.  
No transformation.  
No partial publication.  
No remediation guidance unless explicitly requested.

---

## Scope

This rule applies to all artifact surfaces, including:

- YAML  
- Templates  
- Scripts  
- Comments  
- Example blocks  
- Documentation sections  
- TODO placeholders  
- Embedded payloads (JSON, form data, headers)  

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
- URLs containing embedded credentials  

### Identifying Material
- Email addresses  
- Phone numbers  
- Account numbers  
- User IDs tied to external systems  
- Tenant IDs  
- Organization identifiers  
- Device serial numbers when externally registered  
- Any data that uniquely identifies a real person or external account  

No exceptions are permitted.

This rule applies even if:
- The value is labeled as “fake” or “example”
- The value is documented as temporary
- An override is requested
- A reviewer approves inclusion
- The value is marked as redacted but still present
- The artifact is internal-only or non-production

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

## Review & Validation Gate

- Secret & identifying material scan occurs **before** schema validation and architectural review.  
- Detection is a blocking failure (no downgrade to warning).  
- PRs touching credential plumbing require owner review.  
- Reviewers must grep diffs for patterns including:
    token|api_key|Bearer|Authorization|password|client_secret|@|https?://.*@
