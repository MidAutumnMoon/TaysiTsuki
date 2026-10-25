---
name: post-impl-housekeep
description: Use after implementation to clean up names, comments, and docs.
---

## Post-implementation housekeeping

You set scope and accept results. Delegate each editing pass and final review to a fresh subagent. Reuse a teammate only for follow-ups and repairs to its own pass. Run one writer at a time.

Give every agent the current artifacts, change map, relevant requirements and decisions, and explicit write scope. Pass along what it needs from earlier work, not the conversation history.

For each specialist pass, require the agent to load the requested skill and follow it.

Require a brief report: files examined, changed paths, checks and results, blockers, weighed keeps and their reasons, and anything the assigned skill requires. No edits is also a valid outcome.

## Run in order

Fulfill each step before advancing.

1. *Yourself:* Map the whole change range since the last housekeeping: every implementation, commit, and uncommitted edit this session produced. Exclude unrelated work; ask if the boundary is unclear. At the top of the map, state the boundary and the last housekeeping you measured from. Record the design contract for each change: the decisions and constraints that explain its shape. Record the project's check commands and any execution restrictions.
2. *Fresh teammate:* `language-style-guide`, for the workspace's language, on all changed code. If the guide conflicts with established style, follow that style and report the conflict.
3. *Fresh teammate:* `naming-and-magic-literals` on all changed code. Include necessary reference updates, even ones past the mapped files. Authorize and record any extension. Ask before changing names that external code or stored data depends on.
4. *Fresh teammate:* `prune-comments-and-docs` on comments and prose throughout the mapped files, not just changed lines. Map cross-file duplicates before editing. Give it the map as its write scope and the design contract for checking accuracy, not as a keep list. The comments and contract came from the same reasoning, so agreement alone does not justify keeping a comment. Require the skill's report. Review deletions and kept comments against the report and diff. Restore deleted facts a maintainer needs. Send back kept comments if the mistake they are meant to prevent is implausible or they say more than needed to prevent it. Collect removed rationale for possible use in the change description.
5. Same teammate: `humanizer` on surviving English prose. Preserve technical meaning, obligations, and terminology.
6. (Chinese only; otherwise skip) `chinese-prose-lint` on Chinese prose remaining in scope.
7. Have a fresh, read-only agent review the combined result against the baseline and requirements. Check for missed coverage, broken references, behavior changes, lost meaning, over-explanation, and later edits undoing earlier work. Send specialist concerns back to the responsible pass rather than asking the reviewer to repeat every skill. Route fixes to that pass's agent and rerun affected later passes. Have the reviewer recheck the result, or assign a fresh checker and give it the review findings and fixes.

## Handoffs and close

After each pass, inspect its actual diff and report. Check coverage and spot-check material edits, especially deletions. Resolve blockers before advancing, then update the map, pass status, and accepted checkpoint. Keep the original baseline untouched.

Investigate unexpected changes before proceeding. Do not overwrite them or silently add them to scope.

Rerun checks affected by later edits against the final checkpoint. Report failures and unavailable checks; never treat them as passes.

If delegation or a required skill is unavailable, report the blocked step and ask before substituting another workflow.

Record a completed checkpoint only after the required passes and final review are accepted. Summarize material changes, deleted files, pass status, checks, and unresolved issues. State any limits on verification.
