---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you all reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

Format a round like so. Express the question using concise Simplified Technical English, prefer "show, don't tell":

```
**Q1** **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

- <your recommended answer>
- ...

---

**Q2** **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

- <your recommended answer>
- ...
```

Questions are user-facing, they are not your monolog. Word each question so "yes" accepts your recommended answer.

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Load `group-meeting` skill alongside the user-facing interview, you are the interviewer and coordinator at the same time.

Finding *facts* is your job, never the user's. Gather facts and do research with teammates; don't ask the user for anything you could look up yourself.

A running exploration or unanswered question is an unsettled prerequisite. But only downstream questions and works wait on it. Ask the rest of the frontier now, continue other works that don't depend on it while you wait for anwsers.

Only do work the user has approved.

The session is done when every design tree branch is settled, nothing is silently assumed, you and user have reached a shared understanding, and `group-meeting` has met completion condition.
