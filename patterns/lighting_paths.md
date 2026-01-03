# Lighting Control Paths (Speed vs Validation)

## ON-Path (off → on) — **Speed Priority**
- Minimal gates; central script does `light.turn_on` quickly.
- Compute brightness/ct fast; group/area targeting to reduce chatter.
- Small transition (e.g., 1.5s) smooths spikes.

## ADJUST-Path (on → tune brightness/ct/rgb) — **Overhead Optimized**
- Batch updates; idempotent guards; rate‑limit presence/lux loops.

## OFF-Path (on → off) — **Validation Priority**
- Respect presence/overrides/safety; graceful transitions.
- Log only if user‑visible or exceptional.
