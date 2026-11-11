---
name: code-cultivation
description: Review and refactor code so each unit completes a clear job, APIs return usable results, invalid states are hard to represent, and ownership and dependencies are explicit. Use for clean-code and architecture reviews, root-cause refactors, API/configuration/schema/test/documentation audits, or fitting new behavior into an existing design.
---

Start with what the caller needs, not the techniques used to produce it. If every caller must run `download(source)` and then `verify(file, expected_hash)`, and an unverified tarball has no valid use, those steps are one operation. Expose `fetch_tarball(source, expected_hash)` and return either a verified tarball or an error. Private helpers may still handle network I/O and hashing; callers should not have to coordinate them.

Apply the same test to a module or service. For example, an updater may replace a pin only after all downloaded artifacts and generated records identify the same release. Organize the module around that job, rather than a row of equally prominent `fetch`, `parse`, and `render` stages.

Ask two questions throughout the review:

1. What job does this code finish?
2. What must the structure guarantee before that job is finished?

Naming the job is not enough. A tidy operation can still permit contradictory states, duplicate facts, hide dependencies, or mishandle failures and resource limits.

## Find the job

Before judging names or abstractions:

- Read the behavior, callers, tests, help, examples, schemas, and relevant documentation. Inspect history if the code looks half-migrated.
- Write one concrete sentence: "This code produces X. X is valid only when Y. This prevents Z."
- Record the valid states and ordinary transitions.
- Identify who should own state, policy, validation, cleanup, retries, and commit.
- Decide which intermediate values have legitimate uses of their own.
- Note the consumers, lifetime, compatibility requirements, trust boundaries, and resource limits.
- Follow the input through the decisions and data structures that produce the external effect.

For persisted or generated state, include creation, validation, consumption, update, recovery, and migration. Find every consumer before changing an exported symbol or stored shape. Blast radius is a query, not a guess.

Review the path that produces the result, not files in isolation. Treat the current structure as evidence, not authority. Assume surprising code may carry a constraint until behavior, callers, or history show otherwise.

When qualities conflict, prefer:

1. observable behavior and domain truth;
2. a complete operation backed by its data model and API;
3. explicit invariants, clear ownership, and one-way data flow;
4. one authoritative home for each fact and fewer degrees of freedom;
5. less mechanism and indirection;
6. precise expression over superficial uniformity.

Do not claim more than the evidence proves. A sample, metadata field, default, or heuristic cannot prove an exact claim. Check the probe and selector before changing code around their output.

## End each unit with a usable result

Treat the name of a function, type, or module as a contract. Ask:

- What may the caller safely do with the result?
- Has the unit done everything its name implies?
- Must every caller remember the same next call?
- Can an unsafe, contradictory, or useless intermediate escape?
- Does the boundary follow a useful result, or merely a switch from I/O to parsing, parsing to validation, or one library to another?

Keep steps together when one is useless without the other, a later step validates or commits an earlier one, they share cleanup or retry policy, or they change for the same reason.

Keep them separate when the intermediate result has its own consumer, lifecycle, policy, recovery role, or trust boundary. An editor, for example, may need an invalid syntax tree so it can report several errors. If every caller needs a valid configuration, parsing and validation usually belong behind one loading operation.

Different verbs do not require different boundaries. Sequential calls do not necessarily belong together. Put the boundary where the caller receives something it can use.

A complete operation need not be one large function. Use helpers to hide detail, but leave the decisions, order, and success condition visible in the main flow.

## Shape the structure around the job

Once the job is clear, inspect the structure:

- Represent valid states and transitions directly. Add a distinction when states differ in validity or ownership; remove one that exists only to be synchronized.
- Prevent invalid construction where practical instead of checking the same combination in every caller.
- Give each invariant and mutable fact one owner. Keep policy in data instead of copying it into labels, defaults, schemas, tests, and documentation.
- Pass required context forward. Do not discard information and reconstruct it later, or read ambient state that the caller already knows.
- Introduce a type when it prevents invalid use, carries durable identity, crosses a real boundary, or owns a lifecycle or policy. Do not name every pipeline stage with a type.
- Keep domain decisions easier to see than URL construction, adapters, serialization, and formatting.
- Generalize only when real uses share policy and ownership. Similar syntax may encode different knowledge.
- Make errors, cancellation, retries, locking, cleanup, and resource use match the operation's contract.

Look for these signs:

- names or comments that say "exact", "safe", or "identical" but rely on samples, defaults, or metadata;
- fields, flags, or collections that callers must keep synchronized, or that some modes ignore;
- ordinary changes that require edits to validators, defaults, schemas, and labels;
- callers that always pair the same operations or rebuild the same context;
- half-finished migrations, stale aliases, dead dependents, magic offsets, and cleanup that compensates for an earlier mistake.

Trace each symptom backward. Move the rule to the earliest boundary or representation that can enforce it instead of polishing downstream compensation.

Do not delete a useful seam because it looks thin. A filesystem wrapper that rebases paths and reports errors consistently owns shared path and error policy. A one-off helper is also fine when it stays local and duplicates no policy.

## Change the responsible boundary

Argue for the current shape before replacing it. An intermediate value may have a real consumer. A split may protect recovery, cancellation, locking, or a trust boundary. A small abstraction may own context that one call site does not show.

For each finding, state the evidence, consequence, and confidence. Do not assume that the largest function or oldest abstraction caused the problem.

For a risky change, run the smallest reversible probe that can confirm the suspected cause. Then repair the responsible boundary and make a clean cutover. Update callers, tests, schemas, persisted forms, and relevant documentation. Remove obsolete paths, aliases, parallel implementations, and compensations whose cause is gone.

Compatibility is a requirement to prove, not a default. When stored data changes, migrate it, reject old data explicitly, or preserve compatibility. For schemas, versions, and generated artifacts, choose and document the authoritative form. Make edits and upgrades deliberate. Keep tests, help, examples, and documentation aligned with the stable contract.

Match the size of the change to the evidence. Do not redesign unrelated code merely because a broader design looks cleaner.

## Prove the complete operation

Ensure the data flows i.e. the path from input to external output is all green. Exercise boundary, concurrency, and error etc. Ensure test and CI still pass (if they exist).
