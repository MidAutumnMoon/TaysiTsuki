---
name: frontend-review
description: Review and refactor frontend code (components + CSS) for layout decay and dead code. Use when reviewing a change, cleaning up CSS, or refactoring components.
---

# Frontend Review: Fix the Generator, Let Symptoms Cascade

Root-cause review: most decay is a *symptom* of one upstream cause (a dead abstraction, a duplicated pattern, a wrong wrapper, margin-where-gap-belongs). Find the **generator**, fix it once: dead dependents fall away, hidden bugs surface. This is the layout/consistency axis of a review, not all of it.

## Smell catalogue

Class names below are from one codebase; the patterns aren't. Each entry: a grep-able **signal** and the one-change root fix.

### 1. Margin-as-gap
**Signal:** a flex/grid column whose children carry `margin-top`/`margin-bottom`.
**Catch:** a child that's *also* inside another gapped parent double-spaces (margin + gap stack), invisible until you convert.
```css
/* before: .msg has no gap; .tool is inside .tools (gap:0.5) AND has margin-bottom:0.6 -> 1.1rem between tools */
.msg { display:flex; flex-direction:column; gap:0.5rem; }   /* after: owns spacing; child margins deleted, double-space bug dies with them */
```

### 2. Compensated shift
**Signal:** `calc(` in padding/margin inside a `:state` rule that also sets a border.
```css
/* before */ .row.active { border-inline-start:2px solid var(--primary); padding-inline-start:calc(0.7rem - 2px); }
/* after:  reserve the space always, flip only the color */
.row        { border-inline-start:2px solid transparent; }
.row.active { border-inline-start-color:var(--primary); }
```

### 3. Shadow generator (highest leverage)
**Signal:** duplicated declaration blocks, or one thing inlined where a sibling is componentized.
**Fix:** one canonical pattern; route everything through it; duplicates collapse.
- *CSS:* two byte-identical drawer roots (`.manage`, `.inspector`) -> merge into `.manage, .inspector { … }`.
- *Component:* one drawer inlined seven levels in the root layout while its sibling was a 3-line wrapper around its own component -> extract a `ManageAssistants` mirroring the sibling. Restoring a pattern, not slicing to cut lines.

### 4. Dead dependents
**Signal:** class/token/import/keyframe with zero references in components. Usually **temporal**: a refactor removed the generator but not the dependents.
**Fix:** remove the cascade, then **re-scan**: second-order dead code appears only after the first removal (deleting `.dialog-content` made `@keyframes pop-in` dead). Prove unused (grep + rule out dynamic class construction) before deleting.

### 5. Asserted root
"X is the root" stated, not shown. Prove it with the reference graph: a **generator** has high fan-in or defines a pattern others copy; a **symptom** has high fan-out and duplicates one. Use find-references / grep to compute fan-in. Can't show the graph? Downgrade or drop the finding.

## Workflow

1. **Classify** each smell generator vs symptom; target generators.
2. **Compute blast radius before touching** (find-references, grep, structural search). "What breaks if I remove this?" is a query, not a guess.
3. **Fix at the generator**: one change.
4. **Re-scan.** The fix exposes the next smell (the `.msg` gap conversion surfaced the `.tool` double-spacing). This emergent pass is the real value. Keep it even when the catalogue feels routine.
5. **Forward:** now that the pattern's uniform, what missing abstraction wants to exist? Ask, don't force.
6. **Guard** every invariant found (comment, schema, component, test) so decay can't return. Removal without inoculation is temporary.

## Verification

Capture a baseline before; prove invariants after. Match depth to change:
- **CSS-only:** measure transform, width, gap, left-edge, no-shift (`getComputedStyle`, `getBoundingClientRect`).
- **Logic:** smoke the real flow (submit -> open -> toggle -> save) against the baseline.
- **Rename/remove:** find-references shows zero live callers before cutover.

## Gotchas

- **"Build green" isn't "works."** Type-check/lint/build prove validity, not behavior.
- **A declaration's effect depends on its layout context.** `margin:auto` centers a block but shrink-to-fits a flex item; a border in a `:state` shifts content, a reserved one doesn't. Re-verify when moving a pattern between contexts.
- **Measure the invariant, not one element.** "It's 800px" proves less than "its left edge equals the other's left edge."
- **A surprising measurement is usually the probe, not the code.** Before chasing a regression, rule out the probe: selector matched nothing or several, or the fixture isn't at the assumed state (stale / not loaded / wiped).
- **"No visible bug" isn't "no bug."** A defect can hide behind a mask (margin, flag, special case) and surface only when an adjacent change removes it.
- **The file drifts from memory after edits.** Re-read before the next move or any claim.

## Restraint

Don't force a one-off magic number into a pattern (no cascade, just churn), and don't "clean" verbose code that encodes a real constraint (an invariant comment is verbose on purpose).

## Scope guard

Chain-reaction tunnel-visions into code shape. Deliberately also run: accessibility, perf/budget, responsive (narrow *and* wide), behavior invariants.

## Anti-patterns

- **Naive extraction**: slicing to cut a metric without restoring a pattern.
- **Symptom-fixing**: `calc` to undo a shift, `margin` to fake a gap, a special-case flag.
- **Delete-only bias**: sometimes the fix is adding the missing seam.
- **Single-viewport or post-hoc-only verification**: a "verified" result that still lies.

## Output

```
smell:    <name>
evidence: <file:line + code>
root:     <generator, proven how>
blast:    <what else this affects / dies if fixed>
fix:      <one-change root fix>
guard:    <comment | schema | component | test | none>
```
`root` must be proven; an unproven root is an assertion. Compute it or drop the finding.
