---
name: post-impl-housekeep
description: Use after implementation to clean up names, comments, and docs.
---

# Post-implementation housekeeping

You set scope and accept results. Delegate each editing pass and review to teammates. Reuse a teammate only for follow-ups and repairs to its own pass.

Give every teammate the complete change map timeline and requirements. Give the the scope. Tell each teammate to trace changes' timeline from the map, not to work on each change in isolation.

For each specialist pass, require the teammate to load the requested skill.

Require a brief report: files examined, changed paths, checks and results, blockers, weighed keeps and their reasons, and anything the assigned skill requires. In some case, no edits is also valid.

## Housekeep steps

Fulfill each step before advancing. For each step, if the scope and change are massive, coordinate parallel teammates to do the work if that's more efficient.

1. *Yourself:* Map the whole change range since the last housekeeping: every implementation, commit, and uncommitted edit this session produced. Ask user if the boundary is unclear. At the top of the map, state the boundary. Record the project's check commands and any execution restrictions.
2. *Fresh teammate(s):* `naming-and-magic-literals` on all changed code. Update references past the mapped file to ensure coherency if necessary. Ask before changing public names that external code depends on.
3. *Fresh teammate(s):* `language-style-guide` for the workspace's languages. Report conflicts between the guide and established style.
4. *Fresh teammate(s):* `prune-comments-and-docs` on comments and documents throughout the timeline. Review deletions and kept comments.
5. Same teammate: `humanizer` on surviving English.
6. (Chinese only, otherwise skip) `chinese-prose-lint` on Chinese.
7. Have a fresh, read-only agent review the combined work. Check for missed coverage, broken references, behavior changes, lost meaning, over-explanation, and later edits undoing earlier work. Send specialist concerns back to the responsible pass rather than asking the reviewer to repeat every skill. Route fixes to that pass's agent and rerun affected later passes. Have the reviewer recheck the result afterwards.

## Handoffs and close

After each pass, inspect the new diff and teammate's report. Check coverage and spot-check material edits, especially deletions. Resolve blockers before advancing, then update the map. Keep the original baseline untouched.

Investigate unexpected changes before proceeding. Do not overwrite them or silently add them to scope.

Rerun checks affected by later edits against the final checkpoint. Report failures and unavailable checks; never treat them as passes.

If a required skill is unavailable, or you can't launch teammates, stop and report.

Record a completed checkpoint only after the required passes and final review are accepted. Summarize material changes, deleted files, pass status, checks, and unresolved issues. State any limits on verification.
