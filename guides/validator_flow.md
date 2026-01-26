# Validator Flow — Human Review Checklist

Use this mental model while reviewing any automation/script/template.

```
┌─────────────┐
│ Start Review│
└──────┬──────┘
       ↓
[A] Touches devices?
    ├─ Yes → Idempotency & guard clauses
    └─ No  → Proceed
[B] Runs on startup?
    ├─ Yes → Restart staggering window (`for:` random 45–75s)
    └─ No  → Proceed
[C] High-frequency triggers?
    ├─ Yes → Debounce / rate-limit
    └─ No  → Proceed
[D] Safety / overrides?
    ├─ Yes → Confirm precedence order
    └─ No  → Consider if needed
[E] Aliases at all levels?
    ├─ Yes → ✅
    └─ No  → Add missing aliases
```

**Text form**
1) Idempotency for device actions
2) Startup stagger windows
3) Debounce / rate-limits
4) Safety override precedence
5) Aliases in triggers, conditions, actions
