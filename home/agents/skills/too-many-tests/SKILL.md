---
name: too-many-tests
description: "There might be too many tests."
disable-model-invocation: true
---

Hmm, the landed implementation might have added too many useless tests. Review the added/touched tests, cut or rewrite useless tests. The trick is to improve the implementation to make tests obsolete from the root.

For Rust and other modern languages, take advantage of language features and the compiler. Eliminate useless tests from the fundamental layer.
