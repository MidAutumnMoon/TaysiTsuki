---
name: challenge-architecture
description: Adversarial architecture review of work just completed. Use when user wants to challenge the architecture or design.
---

## Challenge architecture

**Think out side of the box.**

Challenge the whole feature, not just the diff. Preserve behavior; treat the current structure as negotiable.

- **Check the fit.** Read callers and similar features. If starting fresh, would you put this logic here, with these boundaries? What existing concepts could replace newly introduced ones?
- **Trace the data.** Follow an interaction end to end. Where is the source of truth? Which state could be derived instead of stored? Where do callers manage another component’s internals?
- **Question the interfaces.** Can callers express intent without knowing the machinery? Can they request invalid combinations? Does each layer hide complexity or merely pass it along?
- **Test the boundaries.** Walk through one plausible next requirement. What must change together, and why? Would moving, merging, or deleting code reduce that coordination? Use this as a design test, not a reason to build speculative flexibility.
- **Refactor what matters.** Fix ownership and responsibilities before polishing interfaces and names. Require a concrete benefit for each change; leave sound code alone.

Use teammates for independent critiques when available. Run relevant checks. Show meaningful changes, trade-offs, and verification—not a review transcript.

