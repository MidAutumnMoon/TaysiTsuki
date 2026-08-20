---
name: code-cultivation
description: Review and refactor code for semantic coherence, explicit invariants, clear ownership, and maintainable structure. Use when the user asks for clean-code or architecture review, root-cause refactoring, API/test/comment audit, or help fitting new behavior into an existing design.
---

# Code cultivation: make the structure tell the truth

Beautiful code minimizes the distance between what must be true and how that truth is represented. Review is causal model repair: recover the truth, find where the code contradicts it, fix the model where the invariant belongs, and make that truth hard to lose again.

The unit of review is the causal chain, not the file or diff. Use this doctrine to decide; do not recite it to the user unless asked. Findings and changes must stay concrete.

## Taste

Quality is contextual. Optimize for the code's real lifetime, ownership, risks, and change pressures, not an imagined general-purpose future.

When qualities conflict, use this order by default:

1. Observable behavior and domain truth.
2. Explicit, enforced invariants.
3. Clear ownership, visible dependencies, and local reasoning.
4. Fewer independently maintained facts and degrees of freedom.
5. Less mechanism and indirection.
6. Precise, readable expression.
7. Superficial uniformity, lower nesting, or fewer lines.

Explicit domain, compatibility, security, and resource constraints may override this order; name the tradeoff when they do. Repeated syntax may encode different knowledge. Terse code may still be complicated. Thin wrappers can own real context.

A smell is a hypothesis, not a verdict. Taste opens the investigation; evidence decides it. Match the intervention to the evidence and the cost of being wrong. Expensive or hard-to-reverse changes need stronger proof; under uncertainty, prefer a reversible probe that settles the question.

## Modes

Infer the mode from the request. In review mode, report only material findings, say when suspicious code should stay, and impose no finding quota. For a refactor, repair proven causes with a clean cutover. When fitting new behavior, place it with its natural owner; reshape only when the surrounding model cannot express it cleanly.

## Work

### 1. Recover

Recover intent before judging shape.

- Establish intended behavior and record what the code does now. Preserve the intended behavior; treat any gap between the two as evidence.
- Identify only the relevant domain facts, valid states, ownership, trust boundaries, persistence, failure behavior, and resource constraints.
- Read the implementation and its callers, tests, and comments. Inspect history when the code looks half-migrated.
- Before changing an exported symbol, compute its references. Blast radius is a query, not a guess.

Assume surprising code may encode a constraint until the causal chain proves otherwise. The current implementation is evidence of intent, not its authority.

### 2. Trace

Follow the relevant chain from input to representation to decision to effect. Prefer explicit, one-way information flow: later stages should not reconstruct facts discarded earlier, and local behavior should not depend on distant ambient knowledge.

Look for downstream code compensating for an upstream mismatch:

- coupled flags or collections that must stay synchronized;
- special cases, magic offsets, or cleanup after the fact;
- multiple constants, schemas, comments, or tests carrying one fact;
- ambient reads, wrappers around wrappers, or awkward fixture setup;
- dead dependents left by an earlier migration.

The root may be the wrong representation or owner, a missing or needless distinction, a semantic lie, or an absent seam. It is not necessarily the oldest line, largest function, or most connected symbol.

### 3. Diagnose and challenge

Name the truth or invariant, show how the current shape contradicts it, and trace the compensations that follow.

Before acting, ask:

- What is the strongest case for keeping this code?
- What policy, context, capability, or protected invariant does this abstraction add?
- Is it redundant globally or only when viewed locally?
- What else changes if this code moves or disappears?
- Is the probe, fixture, or measurement trustworthy?
- Does a real requirement demand this generality, or only a hypothetical future?

State confidence. If you cannot show the causal link, downgrade or drop the finding.

### 4. Reshape

Repair in the layer responsible for enforcing the invariant. Prefer moves that reduce the facts a maintainer must keep in sync:

- choose a representation that excludes invalid states;
- merge independently maintained facts, not merely similar syntax;
- introduce a missing distinction or remove an unnecessary one;
- move responsibility to its natural owner and expose ambient dependencies;
- remove an abstraction with no semantic delta, or add the seam whose absence generates compensation.

Make a clean cutover: migrate callers and remove obsolete paths, parallel implementations, and stale explanations. Compatibility is a domain constraint, not an automatic virtue; preserve it only for real external consumers or an explicit requirement.

Scale the reshape to the evidence. Permission for architectural or breaking change is not a mandate to rewrite unrelated code.

During exploration, optimize for learning and reversibility. Once the direction works, consolidate: remove probes, reconcile duplicated mechanisms, normalize names, and leave one coherent representation.

### 5. Re-scan

After changing ownership, dependencies, or representation, inspect the affected causal chain:

- Which compensations and second-order dependents are now dead?
- Did the change expose a missing seam or create another representation of the same fact?
- Are names, tests, comments, schemas, and persisted-data assumptions still true?
- Does the next plausible change now have one obvious home?

Re-scan once. Continue only when new evidence exposes another material cause. This bounded second pass is the heart of chain-reaction review.

### 6. Prove and guard

Verify intended behavior against the observed baseline. A green build proves validity, not behavior.

- Exercise the real flow for behavior and state changes.
- Test affected boundaries, failure paths, scale, and concurrency.
- For UI or layout, verify the actual surface and measure relationships or invariants, not isolated values.
- For removals and renames, prove no live callers remain.
- When evidence surprises, rule out a bad selector, fixture, state, or probe before diagnosing the code.

Guard recurrence-prone invariants at the strongest practical layer:

1. representation, type, or data constraint;
2. ownership or API design;
3. validation at a trust boundary;
4. behavioral test;
5. comment for a nonlocal constraint that cannot be encoded.

Dead residue needs no memorial. Add a test only when an observable contract lacks protection against a plausible regression.

## Lenses

Use only those suggested by the evidence.

- **Semantics:** Do names, contracts, and behavior agree?
- **State:** Can invalid combinations exist or coupled values drift?
- **Ownership:** Is the invariant enforced by its natural owner or recovered through ambient knowledge?
- **Abstraction:** What policy, context, capability, or protected invariant does this layer add?
- **Information flow:** Is information carried forward or reconstructed after being discarded?
- **Change topology:** How many places encode one fact, and where would the next plausible change land?
- **Operational contract:** Do resource use, I/O volume, latency, cancellation, concurrency, persistence, and failure behavior match the contract and expected scale?
- **Tests and comments:** Do they protect stable promises or narrate incidental implementation?
- **Time:** Is this live intent, migration residue, or persisted legacy shape?

## Reporting

Reason from cause to effect. Report in the shortest form that preserves the argument:

```text
evidence -> violated truth -> root and confidence -> consequence -> change or keep -> proof/guard
```

Order findings by semantic impact, recurrence risk, and confidence, not ease of cleanup. Do not force trivial edits into this format.

## Contrasts

These examples show the reasoning, not implementations to copy.

### Remove the generator, not its compensation

```text
Signal: an active state adds a border and subtracts the same width from padding.
Shallow: tune the compensating calculation.
Causal: reserve the border in every state and change only its color.
Why: stable geometry removes both the shift and its compensation.
```

### Repair the promise, not the fixture

```text
Signal: after env_clear, a child still resolves commands through ambient PATH.
Shallow: adapt the test fixture to the inherited environment.
Causal: trace the builder; it cleared only overrides while the process inherited ambient variables. Represent "clear ambient" explicitly and honor it when spawning.
Why: test friction exposed a production API whose behavior contradicted its name.
```

### Prove the abstraction before deleting it

```text
Signal: filesystem methods appear to duplicate the standard library.
Naive: delete the wrappers.
Trace: they rebase paths against a logical cwd, attach contextual errors, and share semantics with command execution.
Decision: keep them. Thinness is not absence of value; the wrappers own context.
```

## Restraint

This skill covers structural and semantic quality. Run specialist security, performance, accessibility, and domain passes when those claims matter.

Metrics are signals, not objectives. Do not extract code just to lower nesting or file length, or merge semantic roles because their values happen to match. Do not introduce generality without real pressure or replace clear local code with a framework for hypothetical consistency. Do not patch a symptom while its generator is reachable, and do not force every investigation to end in a refactor.

A one-off is acceptable when it is honestly local and creates no duplicated knowledge or cascade. Verbose code is acceptable when it exposes a real constraint. Deletion is evidence of simplification, not its definition.

Stop when the relevant truth has one authoritative home, misuse is structurally difficult, the affected causal chain is clean, behavior is proven, and remaining discomfort points to no concrete failure or future change cost.
