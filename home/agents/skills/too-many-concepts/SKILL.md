---
name: too-many-concepts
description: "There may be too many concepts, making code harder to follow."
disable-model-invocation: true
---

This is a review round. Is the landed implementation really the best fit when being put in a broader context? There might be "too many concepts" in the implementation, *abstractly* speaking. By "too many concepts" it doesn't simply mean too many names. It means in order to comprehend the code, I (the user) have to keep track of many things in parallel, and jump back and forth in many files to see the implementation. Is it really the cleanest, simplest, and tightest implementation?

`code-cultivation` and other architecture related skills may help. Use them.
