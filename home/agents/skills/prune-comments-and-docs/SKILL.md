---
name: prune-comments-and-docs
description: Review and prune code comments, doc comments, lint reasons, prose documentation, and program messages. Use when asked to review, clarify, or improve these texts.
---

## Goal

Keep the information readers need without making them read a second description of the implementation.

Delete optional text by default. Keep only the parts that clearly help the intended reader. Leave useful, clear text unchanged.

Assume code readers know the language, libraries, and standard concepts, but not project-specific rules. For private code, assume they also read the body.

## Scope

- Review the named files, or the current change if no files are named. Consult related files as needed, but edit only within scope.
- Edit only comments, documentation, lint reasons, and message text. Do not change program logic, names, or types.
- Leave generated and vendored files, tool directives, and license and attribution notices unchanged. Review explanations attached to directives.
- Preserve safety justifications, required documentation, doctests, and examples. You may edit their prose, but retain necessary information and keep doctests and examples valid.
- You may rewrite program messages, but do not delete them. Suggest removal in the report if a message adds no information.

## Editing rules

- Check claims against relevant code, callers, tests, and external requirements. Do not invent intent or describe possible outcomes as guarantees.
- When text and code disagree, establish the intended behavior before changing the text. Investigate unfamiliar warnings and constraints before deleting them. If intent or purpose remains unclear, leave the affected text unchanged and report the uncertainty.
- Delete narration of local operations, consequences readers can readily infer, and text that merely repeats names, types, code, test labels, assertions, or other explanations. Keep concise overviews that save readers from reconstructing a policy or lifecycle.
- Review related explanations together. In private code, prefer one coherent explanation of a policy or lifecycle to scattered captions on fields and helpers. Put reasons for local choices beside the code and explain cross-cutting concepts in prose documentation. Repeat information only when separate references must stand alone.
- Organize each explanation around what the reader needs to know. Combine, move, or rewrite text when trimming alone would leave the explanation unclear. Remove unnecessary points instead of packing them into fewer words. Keep conditions and exceptions needed for accuracy.
- Use consistent technical terms and ordinary punctuation. Name standard concepts when useful instead of explaining their routine mechanics. Remove filler, praise for the design, and storytelling or metaphors that add vocabulary without adding information. Follow the language's documentation conventions.
- Add missing contracts, reasons, constraints, or essential overviews when readers need them. Do not add a comment only because someone might edit the code incorrectly.
- Suggest clearer names, types, assertions, or tests when they could replace an explanation. Keep the explanation while the current code still needs it.

## Text-specific requirements

- Public API docs and guides must be usable without inspecting the implementation. Put caller requirements and guarantees in API docs.
- A test can verify behavior without explaining why it is required. Keep needed rationale and labels that identify test setup conditions.
- Lint reasons must address the concern being suppressed. State why the concern does not apply or why the trade-off is accepted.
- Reference documentation should describe current behavior and limitations rather than recount past edits. Put planned work in TODOs or issues. Keep documents intended to record history, decisions, or plans. Move needed information out of session logs before deleting them.
- Before changing a program message, check whether tests, scripts, or other tools depend on its wording. Preserve formatting arguments and error-handling behavior. Include only information missing from the rest of the error chain or log line. In panic and `.expect()` messages, state which assumption failed. Follow the project's message style.

## Verification and report

Run checks relevant to the edits, including doctests and documentation checks where applicable. Report checks you could not run.

Keep the report brief. State what you reviewed and the check results. Note significant decisions and unresolved issues. Include every changed program message, every deleted file, and suggestions outside scope. Do not list routine comment or documentation edits.

## Examples

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
