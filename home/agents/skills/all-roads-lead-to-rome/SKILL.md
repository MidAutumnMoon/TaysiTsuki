---
name: all-roads-lead-to-rome
description: "If we implement the request as-is, the result will be ugly. Step back and rethink."
disable-model-invocation: true
---

Hmm, let's pause and step back before writing code. Under current constraints, implementing my request or the current plan as-is will result in messy and ugly codes. I hate that.

Challenge my request. What I care about is the *outcome*, or roughly its *observable equivalent*. As the saying goes, "All roads lead to Rome": other combinations of simple pieces may reach that same outcome cleanly.

For example, say I want a popup for typing numbers. Combining a text input widget with a popup widget might tangle up focus and event handling into a behemoth implementation. So step back here. The core outcome is simply "see what numbers are typed." Handling typing events separately and using the popup purely as a text display still *looks* and *works* like an input popup at a fraction of the complexity.

> This example is an illustration of the mindset, never copy its solution.

Current policies, edge behaviors, and the exact request can be loosened if that lets the feature fit the codebase cleanly. Always beware the trade-offs, keep it simple, and propose the cleaner alternative.
