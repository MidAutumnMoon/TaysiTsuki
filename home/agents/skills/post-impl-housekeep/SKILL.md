---
name: post-impl-housekeep
description: Use after all implementation is in to improve the readablity of touched codes, comments and documents.
---

## Post implementation housekeep

Run these steps *one by one* on the implementation change set. Must fullfill the previous step before advancing to the next.

1. Map out the *complete* change set in this session or from last `post-impl-housekeep` run. Persist the "map" to a scratch file for the rest of steps. The map should contain file list and document/comment inventory. If it's VCS tracked (git or jj), map it from diff. Beware external diff tool or pager, pass `--git` to jj is safer.
2. Skill: `naming-and-magic-literals`.
3. Skill: `prune-comments-and-docs`: Don't skip any touched codes or documents. The default position is "delete". Prefer whole block rewrite or cut over patching sentences. But don't over-done it.
4. Skill: `humanizer`: It pairs nicely with step 3. The default position is also "cut". Delete fillers and rearrange sentences.
5. (Optional; Chinese only) Skill: `chinese-prose-lint`: Only chain this if the majority of changes are in Chinese.
6. Review, fix and cleanup.

Re-map: Between each step, compare the current state against the map. If anything unexpected happened, e.g. file changed but the chain didn't edit it, immediately re-map the changed file.

Teammates: At any moment in the chain, if you consider the blast raidus to be quite large, load `group-meeting` if not already, and delegate works to your teammates.
