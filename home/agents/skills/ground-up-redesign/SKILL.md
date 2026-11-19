---
name: ground-up-redesign
description: Uncover obscured data flow and simplify tangled architecture by inlining call paths into flat pseudocode, simplifying the data flow, and redrawing modules from scratch.
disable-model-invocation: true
---

Redesign over-abstracted code in three steps: inline the call graph to see what happens to the data, simplify that flat logic, then draw new boundaries from the clean flow.

Update `SCRATCHPAD.md` incrementally as you trace the code. Don't edit source files until the user approves the plan.

## 1. Inline into flat pseudocode

Identify the entrypoints and shared state in scope. If the scope is too wide to trace accurately, ask the user which path to start with.

For each entrypoint, inline the call chain into one flat block of pseudocode in `SCRATCHPAD.md`:
- Inline orchestration, wrappers, and dynamic dispatch. Keep pure leaf helpers opaque.
- Write concrete data reads, transforms, branches, state updates, and side effects with `file:line` references.

## 2. Simplify the flat flow

Rewrite the pseudocode in `SCRATCHPAD.md` to remove unnecessary work exposed by inlining:
- Collapse redundant conversions, duplicate reads, pass-through variables, split initialization, and scattered updates to the same state.
- Check callers outside the current slice before treating any field, branch, or implementation as dead.
- Preserve logic required for domain invariants, concurrency safety, error handling, and language constraints.

## 3. Draw new boundaries

Design types, functions, and modules directly from the simplified pseudocode:
- Group data by shared lifetime and mutation pattern rather than organizational nouns.
- Split functions and modules where data changes shape, non-trivial logic is shared, or side effects and external formats should be isolated.
- Introduce interfaces only for multiple real implementations or external IO boundaries.

Don't over-compact it. Few code smells to watch out and avoid:
- New god object/class.

When `SCRATCHPAD.md` is complete, present:
1. Old abstractions and glue to cut (`file:line` and what they hid).
2. Proposed data structures and boundaries, noting why each boundary exists.
3. Safe, incremental steps to migrate the code.
