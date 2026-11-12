---
name: all-roads-lead-to-rome
description: "If we implement the request as-is, the result will be ugly. Let's step back and rethink."
disable-model-invocation: true
---

Hmm, let's pause for a second and step back. I feel like under current constraints, my request or the plan will result in a very very messy and ugly implementation. I hate that.

Challenge my request. I want the *outcome*, or roughly the *observable equivalent*. This mindset is important. As the saying goes, "All roads lead to Rome", there may be other *combinations* of features that can reach the outcome.

Analyze the core of the request's outcome. Think outside of the box and from different angles. How to combine "simple pieces" to reach the outcome?

For example, I want a popup for typing numbers. The initial plan is to add a text input widget + popup widget. But that will mess up the event handling badly under certain constraints, resulting in behemoth implementation. So step back: the core outcome is "see what numbers are typed". So the alternative combination is to handle typing events and displaying separately. The popup is now simply a text display, but it still *looks like* and *works like* an input popup. This is the simplest road leading to "Rome".

The current policy or behavior can be loosened. I prefer "fit well" instead of "bolt on and somehow it works". Always beware the trade off. Don't over engineer it.
