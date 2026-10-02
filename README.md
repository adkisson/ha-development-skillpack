
# Home Assistant Skill Pack

**An idiosyncratic prompt, design principles, and pattern set for working with Home Assistant YAML/Jinja**

---

## What this is

This repository contains a **[skill](https://github.com/anthropics/skills) pack** I use when vibe coding (h/t to Anthropic, but it also works as a project file with ChatGPT) with Home Assistant YAML and Jinja.  It compiles and documents the things that have worked and approaches to fix those that LLMs still get wrong much of the time.

It is:

* based on **my** HA instance and interests (and strong opinions about what works for me),
* a common set of design principles and guidelines,
* a set of constraints,
* a mental model for discussing automations,
* a collection of trial-and-error solutions from a hobbyist, 
* and incomplete.

It reflects how *I* currently think about HA coding — not a universal framework or best-practice guide.

---

## What this is not

* Not a drop-in HA set of automations, scripts, etc.
* Not guaranteed to be correct for anyone else's setup
* Not an exhaustive skill for all domains of HA
* Not an official HA approach

---

## Why it exists

As my desire for HA functionality far outstripped my own ability to code (or even structurally think through the setup), I turned to LLMs to see if I could augment my skills.  After a few small automation enhancements, I realized that I was going to get nowhere without very structured documentation of prompts, constraints, and gotchas.  Those started well before Anthropic introduced skills and form the basis of everything here.

---

## How I Use This Skill

I use this Skill across several prompt sessions — sometimes with different AI models.

First, I ask one AI to act as architect — planning whatever the problem actually needs, whether that's a full design, a debugging strategy, or a one-line note that a change is trivial: discuss it in plain English, present options with tradeoffs, identify potential flaws and shortcomings, pressure-test the approach before any code is written, and document testing/acceptance criteria. The goal is to surface and resolve design problems early — not after they're baked into YAML.

Second, I ask it (often a different model) to act as dev: review the design and push back on implicit assumptions, then implement the agreed design and validate it in Tools → Template before I call it done.

If something already built breaks, that's a separate debugging pass — root cause first, no quick patches. If I just want existing behavior cleaned up without changing it, that's a separate refactor pass.

Each step feeds back into the previous as needed — design is pressure-tested before coding begins, and code is pressure-tested before it ships.

---

## Upgrading from 1.x

Version 2.0.0 reorganized the pack around five reasoning-state workflows routed from `SKILL.md`, with breaking changes to file paths and structure. The pack favors outcome- and evidence-driven guidance written for current reasoning-capable models, so behavior may differ with smaller or self-hosted LLMs. See `changelog.md` for details.

---

## Feedback welcome

I’m sharing this in the hope that others will spot flaws, failure modes, or better ways to structure the same ideas.

If your reaction is *“this wouldn’t work for me,”* that’s expected — it's tailored to my way of organizing my thoughts and to my specific interests in HA.  Even so, I hope that some of the structure and guidelines at least spark useful thoughts/discussion.

---

## License

Use, fork, modify, or ignore freely.
No warranty, no claims.

---
