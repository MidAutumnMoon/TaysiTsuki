---
name: group-meeting
description: "Coordinates subagent teammates through independent challenge, scoped delegated editing, fresh-eyes review, verification, and concise minutes. Use when the user asks for a group or team meeting, work with subagents or teammates, a devil's advocate, challenges to decisions, blind-spot checks, or a fresh-eyes review."
---

# Group Meeting

You are the **owner/coordinator**. You own the outcome and final calls, not every edit. Delegate implementation, fixes, and integration when useful.

Teammates bring context that isn't yours. Use that to find what you missed, not to collect approval.

## Principles

1. **Independence before influence.** A fresh agent isn't independent if its brief supplies your answer. Give blind passes the user's words, requirements, and artifacts; keep your conclusions separate. Reveal your plan when the job is to challenge or implement it. Parallelism prevents direct influence, not shared blind spots.

2. **Distinct work, not costumes.** The same model under different personas often repeats the same reasoning. Vary the question, evidence, and method: trace an execution path, inspect callers, reproduce a failure, or design an alternative. If model choice is available, mixing models can add diversity that persona changes alone don't provide.

3. **Dissent with substance.** A teammate told to disagree may manufacture objections; eventually you'll discount useful criticism too. Give challengers real work instead: test an assumption, build a credible alternative, or find a failure path. Findings need evidence—source locations, inputs, traces, results—or a hypothesis label. Finding nothing significant is valid.

4. **Evidence over votes.** One demonstrated failure outweighs several approvals. Reviewers skew additive: more checks, layers, options, and tests. Make additions earn their cost. Prefer the smallest correct solution, including deletion where it helps—not deletion as a goal.

5. **Budget attention.** Add teammates for unanswered questions or deliberate independent checks of consequential claims, not fixed headcounts. Right-size assignments along natural boundaries so no single teammate bears an outsized share of context or critical-path work. Delegation doesn't save context if everyone returns their whole exploration. Use concise handoffs and artifact pointers; inspect the result without replaying every investigation.

## Agenda

Use the rounds that fit. Mechanical changes may skip Challenge. Review-only work skips implementation. Design-only work usually needs Frame, Challenge, Decide, and Minutes.

Scale staffing to risk and the user's requested participation.

### 1. Frame

Keep one accessible task brief with:

- The request and clarifications: quote relevant wording exactly; retain access to the full source.
- Requirements, acceptance checks, and artifact pointers.
- For edits: the baseline and pre-existing changes, workspace sharing, and the intended starting state each teammate must see.

Distinguish requirements from your assumptions and provisional choices. Keep your plan and rationale separate so blind passes don't inherit them.

### 2. Challenge

Before consequential commitments, use one or both:

- **Independent solver:** receives the problem, requirements, and artifacts—not your plan. Proposes an approach, risks, what to avoid, and completion checks.
- **Challenger:** receives your plan and assumptions with the calls you're least sure of flagged. Tests the weakest assumption—especially one you didn't flag—makes the strongest case for an alternative, or runs a pre-mortem: “This shipped and was later reverted. Why?”

Launch independent jobs in parallel when possible. Resolve material divergences rather than defaulting to your approach.

Use short follow-up huddles at costly-to-reverse forks, such as public contracts, data models, migrations, or new dependencies.

### 3. Implement and integrate

Assign outcomes, write scopes, dependencies, interfaces, and acceptance checks. Balance assignments along cohesive domain boundaries. Let implementers choose local details within those boundaries.

Editing rules apply to **every writer, including you**:

- **Shared workspace:** one active writer per file or shared artifact. Transfer ownership explicitly; don't cross another assignment's boundaries without reassignment.
- **Isolated workspaces:** worktrees separate file writes, not interface decisions or shared databases and services. Agree contracts before dependent implementation and coordinate checks that mutate shared resources.
- **Integration hotspots:** give shared contracts, lockfiles, and generated outputs a named owner.
- **Unclear boundaries:** serialize the work or request patches for controlled integration instead of concurrent direct edits.

Name an integrator—you or a teammate—to reconcile changes and check the combined result. Passing isolated tasks do not establish compatibility.

Use the handoff format below. Accept work from artifacts and evidence, not just an implementer's assurance.

### 4. Review

Use fresh teammates who did not implement the changes they review.

For code, cover **Intent**, **Correctness**, and **Simplicity**; one reviewer may cover all three on a small task. Add **Blast radius / integration** for shared contracts, dependencies, or multiple workstreams. Add specialists for specific risks.

Review a stable checkpoint: freeze the reviewed scope or use a snapshot. Identify the task's full change set against the baseline, including uncommitted and new files. A branch diff alone may omit the actual work.

Area reviews may overlap work elsewhere, but at least one non-author reviewer must examine the integrated result. Later edits require affected rechecks.

Reviewers don't edit deliverables. To turn a reviewer into a fixer, reassign write scope; someone else reviews that fix.

### 5. Decide

Deduplicate findings. Give material issues stable IDs and one disposition:

- **Fix:** assign an owner and acceptance check.
- **Reject:** record a concrete reason—evidence, a requirement, or a justified trade-off.
- **Defer:** record the remaining impact and why it can wait.
- **Ask the user:** when the decision belongs to them.

Minors and nits are discretionary.

Resolve significant disagreements with decisive evidence or a fresh adjudicator given both positions fairly. Report unresolved material disagreements rather than burying them.

### 6. Verify

Check the final integrated checkpoint against acceptance criteria and accepted findings. An independent review can count as verification if it covered that state and no relevant edits followed.

After substantive fixes, use a fresh non-author verifier. Small mechanical corrections may return to the existing independent reviewer.

Provide the change set, findings, and decision log. Ask the verifier to check:

- Whether accepted findings are resolved.
- Whether fixes introduce regressions or needless complexity.
- Whether material rejections withstand scrutiny.
- What remains unchecked or unverifiable.

Default to at most two fix–verify cycles, then reassess the scope and budget. Report remaining issues or agree further work. The cap limits effort; it doesn't turn unresolved blockers into completed work. Never call an unrun check passed or an earlier checkpoint current; state when work is implemented but not fully verified.

### 7. Minutes

Close with decisions, not a transcript:

- **Lineup:** who did what.
- **Changed through the meeting:** material decisions and fixes teammates caused.
- **Rejected / deferred:** important findings and reasons.
- **Open questions:** unresolved issues and user decisions.
- **Verification:** final checkpoint, checks and outcomes, limitations, completion status.

If teammates changed nothing, say so plainly. Omit empty sections.

## Lens menu

| Lens | Question |
|---|---|
| Intent | Is this what the user asked for—no missing requirements or unrequested scope? |
| Correctness | Where do real execution paths break: boundaries, errors, state, concurrency? |
| Simplicity | What can be removed? Which abstractions or options don't earn their cost? Does this fit existing patterns? |
| Blast radius / integration | What depends on this? Check callers, contracts, config, data, migrations, docs, and interactions between workstreams. |
| Tests | Would the checks fail for plausible wrong implementations? What important behavior remains untested? |
| Security / performance / operations | Which specific trust boundary, hot path, resource limit, or production failure mode needs examination? |
| Alternative | What's the strongest useful different approach, and what evidence distinguishes it? |
| Pre-mortem | If this later fails or is reverted, what would most plausibly explain it? |

For non-code work, adapt lenses to accuracy, audience, structure, consistency, evidence, and omissions.

## Teammate brief

Teammates don't inherit your context or this skill. Send accessible source references plus the essentials below. Include permissions, required skills, and the relevant report format in the actual assignment.

```text
Role / question:
<one clear responsibility>

User source:
<exact relevant wording; accessible full request and clarifications>

Requirements / done:
<applicable constraints and acceptance criteria>

Inputs:
<paths, baseline, checkpoint, dependencies>

Access:
<read-only deliverables or scoped-write>
<workspace, owned paths, exclusions, allowed checks, shared-resource limits>

Plan / contracts / claims:
<only what this role needs; keep blind passes free of your conclusions>

Skills:
<names and paths; load and follow within the access grant>

Rules:
- Work alone; don't launch subagents.
- Stay within the access grant; request any needed expansion.
- Report missing inputs, ownership conflicts, or unavailable skills instead of working around them.
- Back conclusions with evidence or label them hypotheses.
- Return a concise report; reference large artifacts instead of pasting them.

Return:
<role-appropriate format below>
```

Reports:

- **Solver / challenger:** approach or strongest alternative, key assumptions, risks, and checks that distinguish the options.
- **Implementer / integrator:** changed paths and patch/ref/checkpoint, material decisions, checks and outcomes, unresolved dependencies or risks.
- **Reviewer:** findings with severity (blocker/major/minor/nit), location, impact, evidence, and suggested remedy; then coverage and unknowns. “No significant findings” is valid.
- **Verifier:** finding IDs marked resolved/unresolved/unverifiable with evidence; new issues, challenged rejections, and final-check limitations.

## Defaults and fallback

- For code Review and Verify, use `code-cultivation` when available. If unavailable, disclose that and use the relevant lenses.
- Pass through skills the user requires. If one is unavailable, surface the unmet requirement rather than silently treating it as optional.
- Task-specific user instructions override these workflow defaults.
- Without subagents, say so and use separate, labeled passes where useful. These are self-review, not independent teammates; note the limitation in the minutes.
