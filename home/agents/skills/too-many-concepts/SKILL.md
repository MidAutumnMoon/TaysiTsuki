---
name: too-many-concepts
description: "There may be too many concepts, making code harder to follow. Try simplifying the code."
disable-model-invocation: true
---

Let's audit the quality of code. This is a review round. Is the landed implementation really the best fit when being put in a broader context? I'm afraid that there are "too many concepts", *abstractly* speaking.

By "too many concepts" it doesn't simply mean too many names. It means in order to comprehend the code, I (the user) have to keep track of many things in parallel, visualize parallel data flow in my mind at the same time, think of function dependency orderings, and jump back and forth in many files to see the implementation. That's a lot of mental overload. Is it really the cleanest, simplest, and tightest implementation?

`code-cultivation` and other architecture related skills may help. Use them.
