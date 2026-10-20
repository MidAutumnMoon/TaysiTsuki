---
name: naming-and-magic-literals
description: Use when choosing or reviewing names in code, or deciding whether a value needs a name.
---

Check each name where it's used: can you understand the line without looking up its definition?

### Names

- Name what the value represents, not how it was produced: `activeUsers`, not `filteredData`.
- Include details if the type doesn't convey (`timeoutMs`). Omit what's already clear from context (`user.name`, not `user.userName`).
- Prefer full words over abbreviations. Ban single letter names.
- Within a scope, distinguish names by meaning, not arbitrary suffixes (`data`, `data2`).
- Name paired concepts consistently (`start` and `end`).
- Use one term per concept, and follow the codebase's vocabulary.

### Unnamed values

Name a literal or compound expression when its meaning isn't clear where it's used.

- Name the purpose, not the value: `MAX_LOGIN_ATTEMPTS = 3`, not `THREE = 3`.
- Keep idiomatic values (`items[0]`) and expected test values inline.
- Don't merge constants just because they have the same value.
- Show how a value is derived: `24 * 60 * 60`, not `86400`.
- Reuse suitable constants or enums. Otherwise, define new constants in the narrowest scope that covers all their uses.

### Applying changes

- Follow language and project conventions: "rust_style", "jsStyle" or "lisp-style" etc.
- Limit renaming to code you're already changing, unless asked to go further. Rename only when the new name adds information.
- Ask before changing names that external code or stored data depends on, such as exported APIs, serialized keys, or database columns.
- Update all references, including those in strings and documentation. Then run the build and tests.
