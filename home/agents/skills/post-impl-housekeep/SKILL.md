---
name: post-impl-housekeep
description: "Use after implementation to clean names, style, comments, and docs."
---

Load `teamwork`. Abort of required skills are unavailable.

## Scope

- All changes since the last housekeeping.
- Confirm a unclear baseline with the user. Remember the baseline during housekeep.
- Record scoped paths, exclusions, check commands, and execution restrictions.
- State what each pass reviews: changed lines, code items, document sections, or whole files.
- Include required reference updates in the naming scope. Get approval before changing names used by external code.
- Preserve behavior.
- Work from the current code and commits. Use history to resolve specific uncertainties.

## Passes

Run the passes in order. Accept each result before using it as the next pass's input.

| Step | Teammate       | Work                                       |
| ---- | -------------- | ------------------------------------------ |
| 1    | New            | `naming-and-magic-literals`                |
| 2    | New            | `language-style-guide`                     |
| 3    | New            | `prune-comments-and-docs`                  |
| 4    | Same as #3     | `humanizer` on surviving English           |
| 5    | Same as #3     | `chinese-prose-lint` if Chinese is present |
| 6    | New, read-only | Blind review of the combined result        |

Report conflicts between the language guide and established repository style. Do not reformat unrelated code.

The final reviewer checks coverage, references, behavior, required meaning, excess explanation, and changes that undo earlier passes.

Repeat later passes when a repair affects their results.

Record the accepted final checkpoint for the next housekeeping run.
