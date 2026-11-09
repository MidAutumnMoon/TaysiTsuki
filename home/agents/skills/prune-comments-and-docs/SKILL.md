---
name: prune-comments-and-docs
description: Review and prune code comments, doc comments, lint reasons, prose documentation, and program messages. Use when asked to delete, review, or improve these texts.
---

## Goal

Strongly delete by default. Keep a sentence only if it states a trap, an invariant, an ordering or ownership constraint, or behaviour the code cannot show. Delete the rest. A module doc states the module's job and such an invariant, in at most three lines.

Assume code readers know the language, libraries, and standard concepts, but not project-specific rules. For private code, assume they also read the body.

## Scope

- Review the named files, or the current change if no files are named. Read related files as well.
- Edit only comments, documentation, lint reasons, and message text. Do not change program logic, names, or types.
- Leave generated and vendored files, tool directives, and license and attribution notices unchanged. Review explanations attached to directives.
- Preserve safety justifications, doctests, and anything a compiler or lint requires. You may edit their prose; keep doctests and examples valid.
- You may rewrite program messages, but do not delete them. Suggest removal in the report if a message adds no information.

## Editing rules

- Check claims against relevant code, callers, tests, and external requirements. Do not invent intent or describe possible outcomes as guarantees.
- When text and code disagree, establish the intended behaviour first. If the behaviour is unclear, leave the text and report it; if only the text's necessity is unclear, delete it.
- Delete narration of local operations, consequences readers can readily infer, and text that repeats names, types, code, test labels, or assertions.
- State each policy once. Delete text that repeats another file's documentation, or that the types, signatures, and field names already show.
- Keep an overview only if no other file states it, the signatures cannot show it, and it fits in three lines. A longer one is an essay: delete it or move it to the reference documentation.
- Put a local reason beside its code; put a cross-cutting policy in the reference documentation.
- Remove unnecessary points instead of packing them into fewer words. Keep conditions and exceptions needed for accuracy.
- Use consistent technical terms and ordinary punctuation. Name standard concepts when useful (e.g. name the algorithm, don't document steps). Remove filler, praise for the design, and storytelling or metaphors that add vocabulary without adding information.
- Add a contract or constraint only when the code cannot show it.
- Prefer a clearer name, type, assertion, or test over an explanation.

## Text-specific requirements

- Public API docs and guides must be usable without inspecting the implementation. Put caller requirements and guarantees in API docs.
- A test can verify behavior without explaining why it is required. Keep needed rationale and labels that identify test setup conditions.
- Lint reasons must address the concern being suppressed. State why the concern does not apply or why the trade-off is accepted.
- Reference documentation should describe current behavior and limitations rather than recount past edits. Put planned work in TODOs or issues. Keep documents intended to record history, decisions, or plans. Move needed information out of session logs before deleting them.
- Before changing a program message, check whether tests, scripts, or other tools depend on its wording. Preserve formatting arguments and error-handling behavior. Include only information missing from the rest of the error chain or log line. In panic and `.expect()` messages, state which assumption failed. Follow the project's message style.

## Verification and report

Run checks relevant to the edits, including doctests and documentation checks where applicable. Report checks you could not run.

Keep the report brief. State what you reviewed, the check results, and the per-file comment line delta. List every surviving doc block longer than three lines with its reason, every changed program message, every deleted file, and suggestions outside scope. Do not list routine wording edits.

## Examples

### Cut a module essay

Before:

```rust
//! Decode worker: the app's demand service over a store of previews.
//!
//! Two inputs decide what the thread does: the app's wants, the
//! artifacts its presentation is missing right now, and the plan, the
//! order in which pages are worth producing into the store ahead of
//! time. Wants are served first, from the store when the plan already
//! warmed them and otherwise by decoding and minting on the spot. The
//! plan alone never delivers anything; it only fills the store.
//!
//! Nothing decoded survives here: the preview store is the only cache.
```

After:

```rust
//! Decode worker: serves the app's wants and fills the preview store
//! from the plan. Nothing decoded survives here.
```

The first paragraph restates the type docs and the reference document; the second states the one invariant.

### Remove narration and keep the local reason

Before:

```rust
pub fn sync(&mut self) -> Result<()> {
    // Fetch the remote manifest.
    let remote = self.fetch_manifest()?;
    // Compare it with the local state.
    let diff = self.local.diff(&remote);
    // Apply even an empty diff because `apply` refreshes the lock file.
    self.apply(diff)?;
    Ok(())
}
```

After:

```rust
pub fn sync(&mut self) -> Result<()> {
    let remote = self.fetch_manifest()?;
    let diff = self.local.diff(&remote);
    // Apply even an empty diff because `apply` refreshes the lock file.
    self.apply(diff)?;
    Ok(())
}
```

The calls show the sequence. They do not explain why an empty diff must still be applied. The retained comment needs no rewrite.

### Delete a reason the reader can infer

Before:

```rust
/// Uses the shared parser so validation stays consistent.
fn validate(input: &str) -> Result<()> {
    parse(input).map(|_| ())
}
```

After:

```rust
fn validate(input: &str) -> Result<()> {
    parse(input).map(|_| ())
}
```

The body shows the parser call. The consistency benefit needs no separate explanation.

### Describe public behavior

Before:

```rust
/// Replaces the active configuration.
/// Each request holds a reference to the configuration it started with.
/// Replacing the active configuration leaves those references unchanged.
/// New requests use the replacement.
pub fn reload(&self, config: Config) { ... }
```

After:

```rust
/// New requests use `config`; in-flight requests keep their configuration.
pub fn reload(&self, config: Config) { ... }
```

The rewrite makes the timing rule clear without making callers derive it from ownership mechanics.

### Move the explanation to the relevant field

Before:

```rust
/// Rendering resources.
/// The window owns the GL context, so it drops after pages and egui.
struct Gl {
    pages: PageTextures,
    egui: egui_glow::EguiGlow,
    window: Window,
}

impl Drop for Gl {
    fn drop(&mut self) {
        // The drop body runs before the fields drop.
        // egui's GL objects are destroyed here while the context is alive.
        self.egui.destroy();
    }
}
```

After:

```rust
struct Gl {
    pages: PageTextures,
    egui: egui_glow::EguiGlow,
    // Must drop last: owns the GL context used by the fields above.
    window: Window,
}

impl Drop for Gl {
    fn drop(&mut self) {
        self.egui.destroy();
    }
}
```

Put the lifetime requirement beside `window`. The wrapper caption and explanation of Rust's drop order are unnecessary.

### Flag uncertain intent

```rust
/// Blocks until the worker has stopped.
pub fn shutdown(&self) {
    self.stop.store(true, Ordering::Release);
}
```

If intended behavior remains unclear, leave the comment unchanged and report:

> `shutdown` promises to wait for the worker, but the implementation only sets a flag. Confirm whether it must wait before changing the contract.