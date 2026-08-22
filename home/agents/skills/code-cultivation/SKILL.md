---
name: code-cultivation
description: Review and refactor code for semantic coherence, explicit invariants, clear ownership, and maintainable structure. Use when the user asks for clean-code or architecture review, root-cause refactoring, API/configuration/schema/test/documentation audit, or help fitting new behavior into an existing design.
---

# Code cultivation: make the structure tell the truth

Beautiful code minimizes the distance between what must be true and how that truth is represented. Review is causal model repair: recover the truth, find where the code contradicts it, fix the model where the invariant belongs, and make that truth hard to lose again.

Review the causal chain, not the file or diff. Keep that reasoning internal; report concrete findings and changes.

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

Domain, compatibility, security, and resource constraints may change this order; name the tradeoff. Similar syntax may encode different knowledge. Terse code can still be complicated. A thin wrapper may still own real context.

Correctness covers normal transitions and user workflows. A set of valid snapshots is not enough.

A smell is a lead, not a verdict. Evidence decides whether it matters. Match the fix to the evidence and the cost of being wrong. For risky changes, start with a reversible probe.

Match certainty to evidence. A sample, inference, or metadata check can be useful; it does not prove an exact claim unless the contract defines it that way.

## Modes

Infer the mode from the request. In review mode, report only material findings, say when suspicious code should stay, and impose no finding quota. For a refactor, repair proven causes with a clean cutover. When fitting new behavior, place it with its natural owner; reshape only when the surrounding model cannot express it cleanly.

## Work

### 1. Recover

Recover intent before judging shape.

- Write down intended behavior, normal transitions, and current behavior. A gap is evidence.
- Record the domain facts and valid states. Note who owns them and which boundaries, persistence rules, failure modes, or resource limits matter.
- Separate exact facts from estimates and review hints. Do not enforce more certainty than the evidence supports.
- For persisted or generated artifacts, trace the whole lifecycle: creation, editing, validation, execution, and resume or migration.
- Read the implementation, callers, tests, help, examples, and docs. Inspect history when the code looks half-migrated.
- Before changing an exported symbol or persisted shape, find its consumers. Blast radius is a query, not a guess.

Assume surprising code may encode a constraint until the causal chain proves otherwise. The current implementation is evidence of intent, not its authority.

### 2. Trace

Follow the relevant chain from input to representation to decision to effect. Prefer explicit, one-way information flow: later stages should not reconstruct facts discarded earlier, and local behavior should not depend on distant ambient knowledge.

Look for downstream code compensating for an upstream mismatch:

- flags, fields, or collections that must stay synchronized;
- claims named "exact", "safe", or "identical" but backed only by samples, metadata, or defaults;
- fields that become ignored or contradictory in some modes;
- mutable policy copied into identifiers, schemas, tests, or docs;
- validators that make a routine transition require coordinated edits;
- special cases, magic offsets, or cleanup after the fact;
- ambient reads, unexplained wrappers, or awkward fixtures;
- dead dependents left by an earlier migration.

The root may be the wrong representation or owner, a missing or needless distinction, a semantic lie, or an absent seam. It is not necessarily the oldest line, largest function, or most connected symbol.

### 3. Diagnose and challenge

Name the truth or invariant, show how the current shape contradicts it, and trace the compensations that follow.

Before acting, ask:

- What is the strongest case for keeping this code?
- What policy, context, capability, or protected invariant does this abstraction add?
- Is it redundant globally, or only from this local viewpoint?
- Is the state truly invalid, or is the model making a valid transition awkward?
- Does the evidence support an exact claim, or only a useful hint?
- Is the probe, fixture, selector, or measurement trustworthy?
- Who else depends on this behavior?
- Does a real requirement demand this generality, or only hypothetical reuse?

State confidence. If you cannot show the causal link, downgrade or drop the finding.

### 4. Reshape

Repair in the layer responsible for enforcing the invariant. Prefer moves that reduce the facts a maintainer must keep in sync:

- choose a representation that excludes invalid states and keeps normal transitions local;
- merge independently maintained facts; add or remove distinctions when the domain requires it;
- move responsibility to its natural owner and expose ambient dependencies;
- keep mutable policy in data rather than labels;
- remove knobs that are ignored or have no proven purpose;
- keep exact facts separate from heuristic inputs when both are needed;
- remove an abstraction with no semantic delta, or add the seam whose absence generates compensation.

Make a clean cutover: migrate callers and remove obsolete paths, parallel implementations, and stale explanations. Compatibility is a requirement to prove, not a default. If stored data changes, choose and document migration, explicit version rejection, or compatibility.

Scale the reshape to the evidence. Permission for architectural or breaking change is not a mandate to rewrite unrelated code.

While exploring, favor reversible changes that teach you something. Once the direction works, remove probes, reconcile duplicate mechanisms, normalize names, and leave one coherent design.

### 5. Re-scan

After changing ownership, dependencies, validation, or representation, inspect the affected causal chain:

- Which compensations and second-order dependents are now dead?
- Did the change expose a missing seam or create another representation of the same fact?
- Replay the simplest normal edit or state transition. Does it still work locally?
- If stricter validation breaks a normal workflow, is the input wrong or the model?
- Do code, tests, schemas, help, and docs still agree, including versions and stated limits?
- Does the next plausible change now have one obvious home?

Re-scan once. Continue only if the second pass uncovers another material cause. This catches fallout without turning review into an endless rewrite.

### 6. Prove and guard

Verify intended behavior against the observed baseline. A green build proves validity, not behavior.

- Reproduce the suspected failure or contradiction with the narrowest trustworthy probe before changing it.
- Exercise the real flow, including ordinary edits, persistence, transitions, and recovery.
- If the contract says "exact", inspect all relevant data or use a check with the same guarantee. Measure heuristics separately.
- At external boundaries, inspect the resulting artifact or state; a return value or exit code is insufficient.
- Test affected boundaries, failure paths, scale, and concurrency.
- For UI or layout, verify the actual surface and measure relationships, not isolated values.
- For removals and renames, prove no live callers or persisted references remain.
- When evidence surprises, check the selector, fixture, environment, and probe before blaming the code.

Guard recurrence-prone invariants at the strongest practical layer:

1. representation, type, or data constraint;
2. ownership or API design;
3. validation at a trust boundary;
4. behavioral test;
5. comment for a nonlocal constraint that cannot be encoded.

Dead residue needs no memorial. Add a test only when an observable contract lacks protection against a plausible regression.

## Lenses

Use only those suggested by the evidence.

- **Semantics and evidence:** Do names, contracts, behavior, and certainty agree?
- **State:** Can invalid combinations exist, or do valid transitions require coordinated mutation?
- **Ownership:** Is the invariant enforced by its natural owner or recovered through ambient knowledge?
- **Abstraction:** What policy, context, capability, or protected invariant does this layer add?
- **Information flow:** Is information carried forward or reconstructed after being discarded?
- **Change topology:** How many places encode one fact, and where would the next plausible change land?
- **Operational contract:** Do I/O, latency, cancellation, concurrency, persistence, recovery, and external effects match the contract?
- **Evolution:** Can schemas, versions, generated artifacts, and routine user edits change deliberately?
- **Tests and docs:** Do tests, help, examples, comments, and docs agree on the stable promises?

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

Metrics are signals, not objectives. Do not extract code merely to lower nesting or file length, and do not merge roles because their values happen to match. Do not give a heuristic an exact-sounding name or add generality without real pressure. Do not patch a symptom while its generator is reachable.

A local one-off is fine if it stays local and duplicates no policy. Verbose code is fine when it exposes a real constraint. Delete stale explanations; preserve live constraints and state current limits.

Stop when each relevant truth has one owner, normal transitions stay local, code and user-facing material agree, and behavior is proven. Remaining discomfort needs a concrete failure or change cost before more work.
