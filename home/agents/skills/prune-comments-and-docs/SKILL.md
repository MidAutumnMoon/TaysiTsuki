---
name: prune-comments-and-docs
description: Review and prune code comments, doc comments, lint reasons, prose documentation, and program messages. Use when asked to delete, review, or improve these texts.
---

## Goal

Strongly delete by default. Keep an optional comment only when all three hold: it states a trap, invariant, ordering or ownership constraint, or external contract that reading the code will not show; it applies directly to the code it sits on; and it appears once. Delete everything else, including module docs and overviews that fail this bar.

Assume code readers know the language, libraries, and standard concepts; treat project-specific rules as new information. For private code and inline code literals, assume they also read the body. Do not add new explanatory comments or invent details to pad existing ones.

## Scope

- Review the named files, or the current change if no files are named. Read related files as well.
- Edit only comments, documentation, lint reasons, and message text. Do not change program logic, names, or types.
- Leave generated and vendored files, tool directives, and license and attribution notices unchanged. Review explanations attached to directives.
- Keep required items (safety comments, lint reasons, doctests, required API docs) present and valid; edit their prose when needed.
- You may rewrite program messages, but do not delete them. Suggest removal in the report if a message adds no information.

## Editing rules

- Check claims against the code, callers, tests, and external requirements. State only verified intent, and describe possible outcomes as possibilities.
- When text and code disagree, check the intended behavior first. If intent is unclear, leave the text and report it; if only the text's necessity is unclear, delete it.
- Delete narration of local steps, inferable consequences, and text that repeats names, types, code, test labels, or assertions.
- Delete notes left out of place after code changed or describing code elsewhere; move a displaced constraint to its real site only if that site needs it.
- Delete weak points outright; avoid packing them into half-sentences. Keep conditions and exceptions needed for accuracy, and limit any module doc or overview to three lines; put cross-cutting policy in reference documentation.
- Use consistent technical terms and ordinary punctuation. Name standard concepts when useful (e.g. name the algorithm and leave its steps in the code). Remove filler, praise for the design, and storytelling or metaphors that add vocabulary without adding information.
- Suggest a clearer name, type, assertion, or test when that would remove the need for a comment.
- Look out for `*subject*, not *negative*`, `*abc* instead of *negative*` (which implies abc does xyz), and `*abc* is not *negative*` (which implies abc is xyz) patterns. Avoid "negative subjects" in general; rewrite the sentences straight.

## Text-specific requirements

- Docs and guides for external callers must be usable without inspecting the implementation; put caller requirements and guarantees there. Treat internal items in private modules as private code.
- A test can verify behavior without explaining why it is required. Keep needed rationale and labels that identify test setup conditions.
- Safety comments state only the concrete invariant preventing UB; omit adjacent checks, behavior narration, and standard language or library mechanics. Point to a single module or type invariant when one covers the block, and report safe functions whose safety comments rely on unchecked caller assumptions.
- Lint reasons must address the suppressed lint directly. State why it does not apply or why the trade-off is acceptable.
- Reference documentation describes current behavior and limitations. Put past edits in history, decision, or plan documents; put planned work in TODOs or issues. Keep documents meant to record history, decisions, or plans. Move needed facts out of session logs before deleting them.
- Before changing a program message, check whether tests, scripts, or other tools depend on its wording. Preserve formatting arguments and error-handling behavior. Include only facts missing from the rest of the error chain or log line. In panic and `.expect()` messages, state which assumption failed. Follow the project's message style.

## Verification and report

Run checks relevant to the edits, including doctests and documentation checks where applicable. Report checks you could not run.

Keep the report brief. State what you reviewed and the check results. List every surviving doc block longer than three lines with its reason, every changed program message, every deleted file, unresolved intent or unchecked safety assumptions, and suggestions outside scope. Do not list routine wording edits.

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
//! Decoded artifacts live only in the preview store.
```

The first two paragraphs restate types, signatures, and reference docs; only the cache-ownership invariant stays.

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

The calls show the sequence. The retained comment explains why an empty diff must still be applied; it stays as written.

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

The body shows the parser call; consistency follows from it.

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

The rewrite states the timing rule directly and leaves ownership mechanics to the implementation.

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

Put the lifetime requirement beside `window`; the example drops the wrapper caption and the drop-order explanation.

### Flag uncertain intent

```rust
/// Blocks until the worker has stopped.
pub fn shutdown(&self) {
    self.stop.store(true, Ordering::Release);
}
```

If intended behavior remains unclear, leave the comment unchanged and report:

> `shutdown` promises to wait for the worker, but the implementation only sets a flag. Confirm whether it must wait before changing the contract.

### Delete an out-of-place summary

Before:

```rust
// Per-draw constants are folded CPU-side; output is premultiplied.
const FRAGMENT_SHADER_SOURCE: &str = "... * alpha, alpha ...";
```

After:

```rust
const FRAGMENT_SHADER_SOURCE: &str = "... * alpha, alpha ...";
```

The shader body shows premultiplied output, and constant folding lives elsewhere; delete the out-of-place caption.

### Trim a safety comment

Before:

```rust
// SAFETY: Caller ensures the GL context is current on the render thread,
// `shader` was just created on it, and this frees the temporary handle.
unsafe { gl.delete_shader(shader); }
```

After:

```rust
// SAFETY: Context is current (`Window`).
unsafe { gl.delete_shader(shader); }
```

Drop the local restatement and behavior narration, and point to the invariant's owner.
