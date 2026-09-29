---
name: group-meeting
description: "Runs a task as a group meeting with subagent teammates: independent challengers before committing to a plan, fresh-eyes reviewers with distinct lenses after editing, a fresh verifier for fixes, and meeting minutes at the end. Use when the user asks for a group or team meeting, to work with subagents or teammates, to have teammates challenge decisions or sweep blind spots, for a devil's advocate, or for a fresh-eyes review."
---

# Group Meeting

You are the **owner/coordinator**: you do the work, chair the meeting, and make the final calls. Teammates are subagents. What they offer is a context that isn't yours — they haven't absorbed your assumptions, so they can see what you can't. Use them to find what you missed, not to confirm what you believe.

## Principles

1. **Independence before influence.** Parallel teammates can't hear each other, so there's no groupthink — unless you leak it in through the brief. Give them the user's request verbatim (not your paraphrase), the user's constraints, and pointers to the artifacts. Leave out your conclusions and your reasons for them. If a choice needs context, frame it as a claim to attack: "I believe X is safe because Y — try to break that."
2. **Distinct jobs, not costumes.** The same model under a different persona mostly produces the same review. Make teammates differ in the question they answer, the evidence they examine, and the method they use: trace an execution path, read every caller, run the tests, design an alternative. If you can choose a teammate's model, mixing models adds diversity that personas can't. Two teammates asking the same question is waste; a question nobody asks is a blind spot.
3. **Challenge early.** Challenging a plan is cheap; challenging finished code fights sunk cost — yours. Hold a challenge round before editing, not only a review after.
4. **Dissent with substance.** A teammate told to disagree will always find something, and you'll learn to discount it. Give challengers real work instead: make the best case for a different approach, run a pre-mortem, find the weakest assumption. Every finding needs evidence — file:line, a failing input, command output — or gets labeled as speculation.
5. **You decide; teammates advise.** Teammates are read-only; only you edit, which keeps the work coherent and accountable. Don't dismiss critique to protect your work, and don't accept a suggestion just because a teammate made it. Weigh evidence, not votes: one well-evidenced finding outweighs three "looks good"s. Reviewers skew additive — more checks, layers, options, tests — so accept additions only when they pay for themselves, and prefer fixes that delete.
6. **Be generous.** If you're unsure whether a round or a teammate is worth it, it is — as long as each teammate has a distinct job. Launch independent teammates in parallel when your environment allows. A typical lineup is 2 for Challenge, 3–4 for Review, and 1–2 for Verify; scale up with the size and risk of the work.

## Agenda

Run the rounds that fit. Building or changing something: all of them. Reviewing existing work: Frame, then Review onward. A design question: Frame, Challenge, Minutes.

### 1. Frame (alone)

Write down, briefly:

- The user's request, verbatim, plus later clarifications. When reviewing existing work, also what that work was meant to do.
- Constraints the user set. Only theirs — your own choices belong in the plan, where they're open to challenge.
- What "done" means.
- Your plan, your assumptions, and the calls you're least sure of.

Every teammate brief is cut from this.

### 2. Challenge (before editing)

Launch in parallel:

- **Independent solver.** Gets the problem, the constraints, and where the code lives — not your plan. Asked how they'd do it, what the risks are, what they'd avoid, and what checks would prove it's done. Divergences between their approach and yours are where blind spots hide; resolve each one deliberately rather than defaulting to yours.
- **Challenger.** Gets your plan and assumptions. Asked to (a) run a pre-mortem — "this shipped and was reverted a month later; why?"; (b) find the weakest assumption, especially one you didn't list; (c) make the best case for a different approach.

Update the plan and note what changed and why. While working, call a quick huddle with one or two teammates at any fork that's hard to reverse: a public API, a data model, removing or merging an abstraction, a new dependency.

### 3. Review (after editing)

Launch fresh teammates in parallel, each with a distinct lens from the menu below, chosen by where the risk is. For code, default to **Intent**, **Correctness**, and **Simplicity**, and add **Blast radius** whenever you remove or change something other code depends on. Add further lenses as the change warrants. For large changes, also split by area, and keep one teammate on the whole picture.

### 4. Decide

Triage every finding. Each blocker or major gets exactly one of:

- **Fix** — preferring the fix that removes over the one that adds.
- **Reject** — with a concrete reason: evidence, a user constraint, or a cost that outweighs the benefit.
- **Defer** — noted for the user.
- **Ask the user** — when it's their call: scope, product behavior, a trade-off with no clear winner. Ask now if it blocks the work; otherwise put it in the minutes.

Minors and nits are your call. When you and a teammate disagree on something significant, don't just overrule: get evidence (write the test, run it, trace the path), or have a fresh teammate adjudicate with both positions stated at their strongest. Unresolved disagreements go to the user.

### 5. Verify

After fixing and re-running the tests, launch a fresh teammate (two for large fix sets). Give them the request, the full diff, and your decision log, and ask them to:

- confirm each accepted finding is actually resolved;
- review the fixes on their own terms for regressions and new complexity;
- challenge any rejection that looks wrong.

If they raise new blockers or majors, fix them and verify again with another fresh teammate. After two verify rounds, stop and report what remains.

### 6. Minutes

Close with minutes for the user — the decisions, not the transcript:

- **Lineup** — each teammate's job, one line each.
- **Changed because of the meeting** — the decisions and fixes teammates caused.
- **Rejected / deferred** — with reasons, so the user can overrule.
- **Open questions** — disagreements and calls that belong to the user.
- **Verification** — what the final check found.

If teammates changed nothing, say so plainly.

## Lens menu

| Lens | Question |
|---|---|
| Intent | Reading the user's words, not your interpretation: is this what they asked for — no less, no more? |
| Correctness | Tracing real execution paths: where does it break? Edge cases, error paths, state, concurrency, boundaries. |
| Simplicity | What can be deleted? Which layers, indirections, flags, or wrappers don't pay rent? Does it follow the codebase's existing patterns? |
| Blast radius | What else depends on this? Callers, public API, config, data, migrations, docs, compatibility. |
| Tests | Would the tests fail if the code were wrong? What important behavior is untested? |
| Security / perf / ops | When relevant: trust boundaries, hot paths, production failure modes. |
| Alternative | What's the strongest different approach, and why might it be better? |
| Pre-mortem | It's a month later and this was reverted. Why? |

For non-code work, adapt the lenses: accuracy, audience, structure, what's missing.

## Teammate brief

Teammates start with an empty context, so anything they need must be in the brief — including skills the user wants them to use: name the skill, give its path if you know it, and tell them to follow it.

```text
You're a teammate on a task owned by another agent.
Your role: <lens or job>
Your question: <the one question you must answer>

User's request (verbatim):
<...>

Constraints set by the user (don't relitigate these):
<...>

Look at: <paths, the diff command (e.g. `git diff main...HEAD`), the plan>
Claims to attack, if any: <"I believe X because Y — try to break it.">
Skills to use: <name and path> — load it and follow it.

Rules:
- Read-only: don't modify project files. Reading code, running tests, and other non-destructive commands are encouraged.
- Work alone: don't launch subagents or convene a meeting of your own.
- Back each finding with evidence (file:line, input, output), or label it speculation.
- Your job is to find what the owner missed. Agreement must be earned: if you find nothing significant, say what you checked.
- Don't pad. Label nits as nits.

Report:
1. Findings, most severe first: severity (blocker/major/minor/nit), location, problem, evidence, suggested fix, confidence.
2. The one change you'd make if you could make only one.
3. What you checked and found sound.
4. Questions you couldn't resolve.
```

For an independent solver, replace Findings with: your approach, its main risks, what you'd avoid, and the checks that would prove it's done.

Before launching, check: Is the request quoted verbatim? Are your conclusions left out? Is this teammate's question different from every other's? Are required skills named? Is the report format included?

## Without subagents

If you can't launch subagents, tell the user, then run each round as a separate, labeled pass, writing down each pass's findings before starting the next. It's a weaker substitute; say so in the minutes.

## House rules

Standing defaults. The user's instructions for a given task take precedence.

- Review and Verify teammates use the `code-cultivation` skill.
