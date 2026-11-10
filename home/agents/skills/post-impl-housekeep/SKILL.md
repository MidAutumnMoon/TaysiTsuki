---
name: post-impl-housekeep
description: "Use after implementation to clean names, style, comments, and docs."
---

Load `teamwork`. Abort if required skills are unavailable.

## Scope

- All changes since the last housekeeping.
- Confirm an unclear baseline with the user. Remember the baseline during housekeeping.
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
| 4    | New, read-only | Blind review of the combined result        |

In addition to the skill's rules, tell your teammates to also do these:

- For the `prune-comments-and-docs`, let the teammate lean towards "delete" rather than keep. And for any written document besides code: 1. MUST delete legacy/outdated narratives, i.e. the document is not operation monologue. 2. MUST delete implementation details that only matter to the code. Document should be pointer of the general direction. Don't narrate the codes.
- For the reviewer, it shouldn't suggest adding back deleted narratives.

Report conflicts between the language guide and established repository style. Do not reformat unrelated code.

The final reviewer checks coverage, references, behavior, required meaning, excess explanation, and changes that undo earlier passes.

Repeat later passes when a repair affects their results.
