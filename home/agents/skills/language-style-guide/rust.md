# Rust Style Guide

Base: Follow the official `Rust Style Guide` and `Rust API Guidelines` to the extent they don't conflict with this style guide.

## Rules in context

Distinguish two types of code:

- Library: Intended for other projects. Solves relatively general problems.
- Application: Single application. Solves specific problems.

For *library code*, style guide rules that concern API design are binding.

For *application code*, the rules on API design are a strong recommendation. It should favor simplicity and directness over broad reusability. Avoid premature generalization and abstraction.

## Code organization

### Avoid glob imports

Exception:

- `use super::*` for inline modules
- `use enum::*` in method bodies of enums, and functions that are primarily dealing with that enum
- `pub use submodule::*` for non-leaf modules

Add `#[allow]` with proper reason in such case.

### One `use` statement import items from one module

This rule corresponds to rustfmt `imports_granularity = Item` setting.

Good:
```rust
use foo::Foo;
use foo::bar::Bar;
```

Bad:
```rust
use foo::{Foo, bar::Bar};
```

### Prefer locally-scoped imports

Import items within function or block bodies, unless they are used extensively throughout the file.

Good:
```rust
fn foo(magic: &str) {
    use std::str::FromStr as _;

    let _: u64 = magic.parse();
}
```

### Qualify top-level functions with a module name

To use top-level functions defined elsewhere, import the module and call them with `modulename::functionname()`:

Good:
```rust
use std::mem;

let x = mem::transmute(y);
```

Bad:
```rust
use std::mem::transmute;

let x = transmute(y);
```

Exceptions:

- When functions have sufficiently disambiguated names.
- When the module name itself is prone to collisions. Rename the module in such case: `use emoji_kit::parser as emoji_parser;`.

### Import and use unqualified type names

By default, use types and traits without their module path, e.g. `Regex` instead of `regex::Regex`. Import `Regex` at the top of the file or in the relevant function.

Exceptions:

- Ambiguities. Rename the item in such case, e.g. `use std::io::Error as IoError`.
- In code with lots of dependencies or a large group of types, where importing everything would lead to a very large import block with little benefit.
- In macros and generated code.

## Ownership and borrowing

- Avoid Rc and Arc. Prefer unique ownership and borrowing.
    * Exception: Alternatives would be unreasonably complex to write, understand, or maintain.
- Prefer borrows over copies. Use `.clone()` when a deep copy is genuinely needed. But this rule *doesn't* apply to smart pointers.

## Functions

### Accept flexible references for immutable data

When functions accept borrowed, immutable data, use a reference type that affords the most flexibility. Pass references to the data itself instead of references to wrappers.

| Use          | Instead of   |
| ------------ | ------------ |
| `&T`         | `&Box<T>`    |
| `&[T]`       | `&Vec<T>`    |
| `&str`       | `&String`    |
| `Option<&T>` | `&Option<T>` |

