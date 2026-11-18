---
name: tighten-code
description: "The implementation has too many concepts or awkward boundaries. Preserve behavior and refactor for the cleanest fit. Use when review or refactor codes."
---

Let's step back and challenge this implementation in the broader codebase. I'm afraid that there might be *too many concepts*, abstractly speaking.

I think comprehending the code shouldn't require holding parallel data flows in my head at once, remembering implicit call orderings, keeping separate state in sync, or jumping back and forth across files just to trace one behavior.

Think of *Semantic Inlining*, and *Semantic Compression*. Look at the whole feature alongside surrounding code: if we were starting fresh, would this logic live here with these boundaries?

Judge interfaces and modules by what the caller actually needs. Each unit should complete a coherent job and return a result the caller can directly use and trust. When callers have to pair the same steps together, coordinate another component's internals, or handle incomplete intermediate states, the split is in the wrong place. Give state a single source of truth, derive what can be computed, and enforce invariants up front so downstream logic stays simple.

Preserve the behavior. All of current structures are negotiable. Refactor toward the cleanest, simplest, tightest implementation.
