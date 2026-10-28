---
name: prune-comments-and-docs
description: Review and prune code comments, doc comments, lint reasons, prose documentation, and program messages. Use when asked to review, clarify, or improve these texts.
---

## Goal

Keep the information readers need without making them read a second description of the implementation.

Assume code readers know the language, libraries, and standard concepts, but not project-specific rules. For private code, assume they also read the body. Write public API docs and guides so readers do not need to inspect the implementation.

## Scope

Review the files the user names, or the current change if no files are named. Search related files for repeated or outdated explanations, but keep edits within scope.

Limit edits to comments, documentation, lint reasons, and message text. Leave program logic, names, and types unchanged. Suggest code changes in the report.

Leave generated and vendored files unchanged. Leave tool directives unchanged, but review their attached explanations.

## Outcomes

### Delete

Delete text that repeats what names, types, code, test labels, assertions, or other text already explain. Also delete consequences the reader can readily work out from those explanations.

Review related comments as a group. Field captions, branch notes, and test summaries can repeat the same policy even when each comment is accurate.

Remove filler and praise for the design. Describe current behavior and limitations instead of recounting past edits. Put planned work in TODOs or issues.

Delete session logs after moving needed information to its proper location. Keep documents meant to record history, decisions, or plans.

### Rewrite

Remove unnecessary points instead of packing them into fewer words.

Use direct sentences and consistent technical terms. Remove storytelling and metaphors that add vocabulary without adding information. Keep conditions and exceptions needed for accuracy. Follow the language's documentation conventions and use ordinary punctuation.

### Move

Put caller requirements and guarantees in API docs. Keep reasons for local choices beside the code, and explain shared concepts in prose docs.

Repeat information only when readers need it in separate, self-contained references. A private type, its helpers, and its tests usually need only one explanation of a policy.

### Flag

Check claims against the code. Do not describe a possible outcome as a guarantee.

When text and code disagree, check which behavior is intended. If intent remains unclear, leave the text unchanged and report the conflict. Do not rewrite a contract to match code that may be wrong.

Before deleting a warning or constraint you do not understand, investigate its purpose. If you still cannot explain it, keep it and report your uncertainty.

### Keep

Leave useful, clear text unchanged. A test can verify behavior without explaining why it is required.

Leave license and attribution notices unchanged. Preserve safety justifications, required documentation, doctests, and examples. Keep labels that identify test setup conditions.

### Add

Add missing contracts, reasons, constraints, or essential overviews. Do not add a comment only because someone might edit the code incorrectly.

If a clearer name, type, assertion, or test would replace an explanation, suggest that change. Keep the explanation while the current code still needs it.

## Program messages

You may rewrite program messages, but do not delete them. If a message adds no information, suggest its removal in the report.

Before changing a message, check whether tests, scripts, or other tools depend on its wording. Preserve formatting arguments and error-handling behavior.

Include only information missing from the rest of the error chain or log line. In panic and `.expect()` messages, state which assumption failed. Follow the project's message style.

## Verification and report

Run checks relevant to the edits, including doctests and documentation checks where applicable.

Keep the report brief. State what you reviewed, report check results, and note significant decisions or unresolved risks. Include every changed message, any deleted files, and suggestions outside scope. Do not list routine edits.

## Examples

### Remove narration, keep the reason

Before:

```rust
pub fn sync(&mut self) -> Result<()> {
    // Fetch the remote manifest.
    let remote = self.fetch_manifest()?;
    // Compare it with the local state.
    let diff = self.local.diff(&remote);
    // Apply the diff. Apply even an empty diff because that refreshes
    // the lock file.
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

The calls explain the sequence. They do not explain why an empty diff must still be applied.

### Remove repeated explanations of one policy

Before:

```rust
/// Page changes are atomic across seats.
struct ScreenPlan {
    /// Freeze both seats until pending pages are decided.
    hold: bool,
}

/// Delay a spread change until every requested page is Ready or Failed.
fn plan_screen(changing: bool, all_decided: bool) -> ScreenPlan {
    // Do not replace one seat while its partner is pending.
    let hold = changing && !all_decided;
    ScreenPlan { hold }
}

/// Both seats stay unchanged when a requested page is pending.
#[test]
fn pending_page_delays_spread_change() {
    let plan = plan_screen(true, false);
    assert!(plan.hold);
}
```

After:

```rust
struct ScreenPlan {
    hold: bool,
}

/// Delay a spread change until every requested page is Ready or Failed.
fn plan_screen(changing: bool, all_decided: bool) -> ScreenPlan {
    let hold = changing && !all_decided;
    ScreenPlan { hold }
}

#[test]
fn pending_page_delays_spread_change() {
    let plan = plan_screen(true, false);
    assert!(plan.hold);
}
```

The comments use different wording, but explain the same policy. Keep that explanation on the planner. The other comments add no separate requirement or reason.

### Keep an external requirement, cut the rest

Before:

```rust
/// Framebuffer clear color. Wayland composites ARGB buffers as
/// premultiplied alpha, so the translucent variant scales the color
/// channels by alpha. With straight alpha, the compositor would treat
/// them as already premultiplied, making the result too bright.
fn clear_color(translucent: bool) -> [f32; 4] { ... }

/// Converts the translucent clear color to egui's premultiplied u8 format.
/// Using `clear_color` keeps the status bar and background consistent.
fn glass_fill() -> egui::Color32 {
    let [r, g, b, a] = clear_color(true)
        .map(|channel| (channel * 255.0).round() as u8);
    egui::Color32::from_rgba_premultiplied(r, g, b, a)
}
```

After:

```rust
/// Premultiplied because Wayland requires it for ARGB buffers.
fn clear_color(translucent: bool) -> [f32; 4] { ... }

fn glass_fill() -> egui::Color32 {
    let [r, g, b, a] = clear_color(true)
        .map(|channel| (channel * 255.0).round() as u8);
    egui::Color32::from_rgba_premultiplied(r, g, b, a)
}
```

Keep Wayland's requirement. The reader already knows what premultiplied alpha means. Delete the entire `glass_fill` comment because the body shows the conversion and reuse.

### Flag uncertain intent

```rust
/// Blocks until the worker has stopped.
pub fn shutdown(&self) {
    self.stop.store(true, Ordering::Release);
}
```

If callers, tests, and other evidence do not establish the intended behavior, leave the comment unchanged and report:

> `shutdown` promises to wait for the worker, but the implementation only sets a flag. Confirm whether it must wait before changing the contract.

Callers may rely on the documented guarantee. Rewriting the comment to match the implementation could hide a bug.


### Name the standard concept

Before:

```rust
pub fn add(&mut self, index: usize, delta: i64) {
    // Start one past the index. Each slot covers a range as long as its
    // lowest set bit, so adding that bit jumps to the next slot whose
    // range contains the index. Repeat until we run off the end.
    let mut i = index + 1;
    while i < self.tree.len() {
        self.tree[i] += delta;
        i += i & i.wrapping_neg();
    }
}
```

After:

```rust
pub fn add(&mut self, index: usize, delta: i64) {
    // Fenwick tree update.
    let mut i = index + 1;
    while i < self.tree.len() {
        self.tree[i] += delta;
        i += i & i.wrapping_neg();
    }
}
```

Reader knows the algorithm. Name the concept directly instead of explaining step.
