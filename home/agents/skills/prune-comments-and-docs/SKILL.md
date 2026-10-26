---
name: prune-comments-and-docs
description: Review, cut, and rewrite code comments, doc comments, lint reasons, prose documentation (READMEs, guides, design notes), and program messages (errors, panics, logs). Use when asked to review, clean up, cut, clarify, or improve comments or documentation.
---

# Prune comments and docs

Default to no comment. Keep or add a comment only if the reader is likely to get something wrong without it. Reduce it to the fact that prevents that mistake. State that fact once, plainly, where the reader will look.

Apply this test to every comment, regardless of who wrote it or how long it has been there. Being true, up to date, and unique isn't enough. If the compiler or tests would catch the mistake, no comment is needed.

The reader knows the language, the libraries in use, standard algorithms, and common domain concepts such as premultiplied alpha. The reader doesn't know the history of the code or the task that produced it.

Review the code as it stands, and ignore what you remember of the task. Expect to cut most comments written during a change.

## Scope

Work on the files the user names. If none are named, work on the current change. When reviewing a change, also search the rest of the repository for comments that the change has made inaccurate. If the user asks only for a review, report what you would change and edit nothing.

Change only text, never behavior. If a name, type, assertion, or test could express a fact, suggest that change in the report.

- Leave tool directives alone (`//go:build`, `# noqa`, `# type: ignore`, `// eslint-disable-next-line`). Treat any attached reason like any other comment.
- If you delete a Python docstring that is the only statement in a body, put `...` in its place.
- Leave generated and vendored files alone. Fix generated comments at their source, such as a `.proto` file.

## Readers

In this skill, "comment" includes all four kinds of text below, whether public or private.

- **Doc comments** (`///`, `//!`, docstrings) are for callers, who see the signature but not the body. Explain what the signature doesn't say, such as side effects, failures, panics, and requirements the caller must meet. Leave out implementation details. For private items and application code, assume the caller also reads the body.
- **Inline comments** are for maintainers, who read the code. Explain why code that looks safe to change isn't. Common reasons include constraints, workarounds, deliberate choices that look like mistakes, where magic numbers come from, and why the obvious approach fails. A lint `reason` is an inline comment.
    - Keep the `SAFETY:` justification on every `unsafe` block.
    - Keep test labels that identify the case being set up (`// not ours`, `// ancestor is a regular file`).
- **Prose docs** are for readers new to the topic. For these readers, leaving out a step or concept counts as a mistake. Cover concepts, usage, and decisions that affect multiple files. A short map of the main modules can stay. Leave the details to the code and doc comments.
- **Messages** are text the program shows, such as error messages, `.context()` text, panic messages, logs, and CLI help or schema text generated from doc comments. Rewrite them, but don't delete them, because deletion changes the output. Add only information missing from the rest of the error chain or log line. If a message adds nothing, suggest removing it in the report.
    - In a panic or `.expect()` message, say which assumption failed.
    - Write error and log text for users and operators.
    - Tests, scripts, alerts, and dashboards may match message text. Search the repository before changing a message, and list every changed message in the report.

## Map repeated facts first

Before editing, list the facts that appear in more than one place, including in files outside your scope. Recurring domain terms such as "state", "rendered", "atomic", and "converge" help you find them. Search for all the ways each fact is worded.

Give each fact one home for each kind of reader. Put it on the item it describes, or at the first place that reader will reach. If a fact serves two kinds of readers, such as `README` readers and API callers, give it a home for each. Document a field or its getter, not both. Delete the other copies.

If you divide the work among subagents, build this map first and share it with each one.

## Outcomes

Assess each sentence separately. A single comment may need more than one of the actions below.

### Delete

If you're not sure the reader needs a comment, delete it. Make an exception for a warning or constraint you can't explain. Check its history with `git log -S` or `git blame`, and delete it only if the history shows it no longer applies. If you keep one you still can't explain, list it in the report.

- **Restatements.** Cut what the name, signature, types, assertions, nearby strings, or next few lines already say. For dense code such as a regex, bit trick, or formula, say what it computes or name the algorithm.
- **Other components.** Cut explanations of another module or dependency that are already in its docs, such as descriptions of its types and behavior. Keep any non-obvious choice that component requires here, and any case where it behaves differently from its docs.
- **History.** Cut accounts of what changed ("Added support for...", "Fixed the bug where..."), what the code replaced, and where it was ported from. Keep constraints that still apply, written in the present tense.
- **Plans.** Cut descriptions of what the code might become, including rules for code that doesn't exist yet ("a future toggle must..."). Keep current limitations ("teardown is not implemented"). Put planned work in a TODO or link to an issue.
- **Pointers.** Cut "see X", traces such as "a -> b -> c", and links to things that no longer exist. Keep any step the reader must take, stated as an action ("also approve new routes in infra"). Keep links to issues, specs, and upstream bugs that explain a workaround.
- **Design arguments.** Cut claims that the design is good ("single source of truth", "holds structurally").
- **Filler.** Cut openers ("Note:", "Important:", "This function...", "This ensures that..."), step numbers ("// 1.", "// Step 2"), and hype ("robust", "seamless", "simply", "just").
- **Dead text.** Cut commented-out code and completed TODOs. Keep commented-out options in templates and sample configs.
- **Work logs.** Delete files used as task logs, such as summaries, plans, and status reports. Move any needed facts to their proper homes first. Keep changelogs, release notes, upgrade guides, decision records, roadmaps, and RFCs. The History and Plans rules don't apply to those documents.

### Rewrite

Rewrite a comment when it buries a fact the reader needs.

- An inline comment makes one point. Include the reason if the point alone seems arbitrary.
- A doc comment says what the item does, then states each requirement or guarantee callers need to know.
- A prose paragraph makes one point.

Drop any other point, even if it has no other home. If it's needed at another line, move it there instead. Shorten by cutting points. Don't cram the same information into fewer words. Cut hedges, restatements, and consequences the reader can work out.

### Move

Put each fact where its reader will look. Move the reason for an implementation choice out of the doc comment and next to the code it explains. Move caller requirements and guarantees from the body to the doc comment.

### Flag

Check every claim against the code. If a comment and the code disagree and you can't tell which is wrong, leave the comment unchanged and report the mismatch. This takes priority over the Delete rules, because the comment may describe the intended behavior. If the code is clearly correct, fix or delete the comment.

### Keep

If a comment makes one needed point and follows the Writing rules, leave it as it is, including its casing.

Never delete these:

- License and attribution notices. Leave their wording as it is.
- Doctests and examples.
- Docs and comments required by the language or project, such as `# Errors`, `# Panics`, and `# Safety` sections, or docs enforced by `missing_docs`. If a doc comment is required only by a lint, one short line is enough.

### Add

Add a comment only when the opening test calls for one. The usual gaps are missing reasons and missing error, panic, or safety contracts.

## Writing

Apply these rules to every comment you keep, rewrite, or add.

- Don't use shorthand ("default 0 (no retries); defaults skipped"). Doc summaries and labels ("// not ours") can be short phrases.
- Keep "because", "so", and "otherwise". They explain how the facts connect.
- Don't replace a plain word with a shorter but vaguer one.
- Make one point per sentence. Facts that support the same point can share a sentence ("`idx < self.len` is checked above, and `buf` never shrinks").
- Don't use an em dash, `;`, `:`, ` - `, or parentheses to join two points. Split the sentence or drop the second point.
- Say what a thing is. Write "runs OpenWrt" instead of "is not a NixOS machine". Use "not" to prohibit an action ("don't call this while holding the lock") or rule out a likely wrong assumption ("not thread-safe").
- Mention an alternative only if the reader is likely to try it, and explain what goes wrong with it.
- Follow the language's documentation conventions, even when they look like filler or repeat the name. For example, a Go doc comment starts with the item's name.
- In messages, follow the project's style for casing and trailing periods.
- Match the file's casing, comment markers, and layout unless they conflict with these rules.

## Finish

1. Read each file in full. If a category of comments mirrors the code's structure one for one, remove that whole category, even if each comment passes the test on its own. Leave other categories alone.
2. Recheck the map. Search again for every repeated fact.
3. Search the comments for the words and patterns below, and assess each match in context. "Instead of ORing" can describe a current alternative, and "new routes" need not be history.
    - Joins: `—`, and `;` or `:` within a sentence.
    - Contrasts: `unlike`, `not a`, `rather than`.
    - Pointers: `see`, `lives in`, `->`, file paths.
    - History: `now`, `no longer`, `instead`, `previously`, `old`, `new`, `refactor`.
    - Plans: `will`, `could`, `eventually`, `future`, `not implemented yet`.
4. Reread every kept comment longer than two lines, and remove anything beyond its one needed point.
5. If you can use a subagent, ask it to read the files with no prior context, especially if you wrote the code. Give it only the edited files, not the task, the diff, or your reasoning. Ask what it would misunderstand and which comments it would delete.
6. Build the docs to check for broken links, and run the tests, including doctests.
7. Keep the report brief. Don't list every edit. Include:
    - Files examined.
    - Repeated facts and their homes.
    - Comments that disagree with the code.
    - Judgment calls, one line each so the author can veto them. Include deleted facts with no other home, kept comments longer than two lines, and kept warnings you can't explain. For each kept comment you list, say what a reader would get wrong without it. "It states a constraint" doesn't explain what would go wrong.
    - Changed messages.
    - Explanations you removed about why the change was made. They belong in the commit description.
    - Deleted files.
    - Suggested renames, message removals, and other code changes.

## Examples

### Delete: comments that mirror the code

Before:

```rust
pub fn sync(&mut self) -> Result<()> {
    // 1. Fetch the remote manifest.
    let remote = self.fetch_manifest()?;
    // 2. Diff it against the local state.
    let diff = self.local.diff(&remote);
    // 3. Apply the diff. N.B. we apply even an empty diff on purpose,
    // since that refreshes the lock file.
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

> The numbered comments repeat what the code does, so that whole category goes. The note about empty diffs serves a different purpose. It stays because skipping `apply` for an empty diff would leave the lock file stale.

### Delete: a change log in a README

Before (`README.md`):

```markdown
## Recent Improvements ✅
- **Refactored** config loading for better maintainability
- **Added** comprehensive error handling
- **Removed** legacy `config.ini` support
```

After: deleted.

> A `README` describes the project as it is. Entries that matter to users belong in the project's changelog, if it has one. Document the current config format if users need to know it.

### Delete: a mapping to reference code

Before:

```rust
//! Token-bucket rate limiter, ported from the Java reference implementation
//! (`RateLimiter.java`). Unlike the Java version, there is no background
//! refill thread. Instead, `acquire` computes refills lazily, mirroring
//! Java's `reserveEarliestAvailable()`.
```

After: deleted.

> The code stands on its own, so the comparisons with the reference implementation are history. Keep any required license or attribution notice.

### Delete: copies of a fact

Before:

```rust
//! An interrupted run retries against the previous state and converges.

/// Atomically install the state. A failure leaves the previous state
/// intact, so a retry converges.
pub fn write(self) -> Result<()>

// Retry converges and records the new generation.
#[test]
fn retry_converges() { ... }
```

After:

```rust
//! An interrupted run retries from the previous state and converges.

/// Installs the state atomically. On failure, the previous state remains
/// intact.
pub fn write(self) -> Result<()>

#[test]
fn retry_converges() { ... }
```

> The convergence guarantee belongs in the module docs. The failure guarantee stays on `write`, where callers handle errors. The test comment repeats the test name. A `README` can repeat the convergence guarantee for its own readers.

### Rewrite: an over-explained contract

Before:

```rust
/// Discovers agent definitions in the given directory.
///
/// This function recursively walks the provided `root` path, reads each
/// `.toml` file it encounters, and parses it into an [`AgentDef`]. The
/// parsed definitions are collected into a [`Vec`] and returned.
///
/// # Errors
///
/// Returns a dynamic [`Report`](rootcause::Report) when a directory cannot
/// be read or a file fails to parse — the report includes the failing path.
pub fn discover(root: &Path) -> Result<Vec<AgentDef>, Report>
```

After:

```rust
/// Recursively loads every `.toml` agent definition under `root`.
///
/// # Errors
///
/// Fails if a directory can't be read or a file doesn't parse. The error
/// includes the path.
pub fn discover(root: &Path) -> Result<Vec<AgentDef>, Report>
```

> The signature doesn't show that the search is recursive, that only `.toml` files are loaded, or that errors include the path. A caller who guesses wrong may expect a different set of files or add the path to the error again. The rest repeats the signature or walks through the body.

### Rewrite: true, unique, and still too long

Before:

```rust
/// Framebuffer clear color. Wayland composites ARGB buffers as
/// premultiplied alpha, so the translucent variant scales the color
/// channels by alpha; stored straight, the compositor would treat
/// them as already premultiplied, and the composite would come out
/// brighter than intended.
fn clear_color(translucent: bool) -> [f32; 4] { ... }

/// The glass color as egui's premultiplied u8 color: [`clear_color`]'s
/// translucent channels, quantized. The premultiplied glass lives in one
/// place ([`clear_color`]); this is only its u8 conversion, so the bar
/// repeating the background holds structurally.
fn glass_fill() -> egui::Color32 {
    let [red, green, blue, alpha] = clear_color(true);
    // ...
}
```

After:

```rust
/// Framebuffer clear color, premultiplied because Wayland composites
/// ARGB buffers that way.
fn clear_color(translucent: bool) -> [f32; 4] { ... }

fn glass_fill() -> egui::Color32 {
    let [red, green, blue, alpha] = clear_color(true);
    // ...
}
```

> Wayland's requirement explains multiplication that might look redundant. The reader already knows what premultiplied alpha means. The `glass_fill` comment repeats the body and tries to justify the design.

### Rewrite: history that hides a constraint

Before:

```rust
// Switched from HashMap to BTreeMap so output order is deterministic.
// The sort step after collection is no longer needed.
let mut seen = BTreeMap::new();
```

After:

```rust
// Use an ordered map so the output is stable across runs.
let mut seen = BTreeMap::new();
```

> The output still needs to be stable across runs, and an unordered map would break that requirement. The switch and the removed sort step are history.

### Rewrite: a required step buried in history

Before:

```rust
/// Downloads the archive from `url`.
///
/// The fetch-and-verify pipeline was split into two steps: this function
/// only downloads, and checksum validation now lives in [`verify_archive`].
/// The old `fetch_verified` helper has been removed.
pub async fn download(url: &Url) -> Result<Bytes>
```

After:

```rust
/// Downloads the archive from `url` without verifying it. Pass the bytes to
/// [`verify_archive`] before using them.
pub async fn download(url: &Url) -> Result<Bytes>
```

> The signature doesn't say the bytes are unverified, so keep the warning and the required call. The split and the removed helper are history. The doc links to `verify_archive` without summarizing what it does.

### Rewrite: several facts around one point

Before:

```rust
// default 0 (no retries); bundled defaults skipped (see config/README.md).
// server side, retries go gateway -> backend
cfg.set("retries", 3);
```

After:

```rust
// Set retries explicitly because we skip the bundled defaults. Without
// them, the client never retries.
cfg.set("retries", 3);
```

> The line looks like a default that could safely be deleted, but deleting it would stop all retries. The `README` link and the server-side retry path add nothing here. Both go, even though neither has another home.

### Rewrite: name the algorithm

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

> Neither the type nor the method name says this is a Fenwick tree. Once the reader knows that, `+ 1` and `i & i.wrapping_neg()` are standard steps. The walkthrough adds nothing.

### Rewrite: messages

Before:

```rust
let key = line.split('=').next().expect("this should never happen");
let config: Config = toml::from_str(&text).with_context(|| {
    format!(
        "Failed to parse {}. This usually means the TOML is invalid",
        path.display(),
    )
})?;
```

After:

```rust
let key = line.split('=').next().expect("`split` yields at least one item");
let config: Config = toml::from_str(&text)
    .with_context(|| format!("Failed to parse {}", path.display()))?;
```

> "This should never happen" doesn't identify the failed assumption. The TOML error in the chain already explains the problem and gives the line number. Keep the path because the chain doesn't include it.

### Move: implementation detail in a contract

Before:

```rust
/// Returns the thumbnail for `id`, generating it on a cache miss.
///
/// Uses an LRU cache (a `HashMap` plus a `VecDeque` for recency) holding
/// 256 entries. On a miss, decodes with `image::open`, resizes with
/// Lanczos3, and inserts, evicting the least recently used entry. Lanczos3
/// is used because Triangle aliased visibly on line art.
pub fn thumbnail(&mut self, id: ImageId) -> Result<&Thumbnail>
```

After:

```rust
/// Returns the thumbnail for `id`, generating and caching it on a cache miss.
pub fn thumbnail(&mut self, id: ImageId) -> Result<&Thumbnail> {
    // ...
    // Triangle causes visible aliasing on line art.
    let small = img.resize(w, h, FilterType::Lanczos3);
```

> The cache layout and decoding steps can change without changing the contract. Move the reason for using Lanczos3 to the resize call, where Triangle might seem equally suitable.

### Flag: comment and code disagree

```rust
/// Blocks until the worker has stopped.
pub fn shutdown(&self) {
    self.stop.store(true, Ordering::Release);
}
```

After: unchanged. Report: "`shutdown` says it blocks until the worker stops, but the code only sets a flag."

> The doc may describe the intended behavior. Callers may already free shared state when `shutdown` returns. Rewriting the doc to match the code would hide the bug.

### Keep: already minimal

```rust
// SAFETY: `idx < self.len` is checked above, and `buf` never shrinks.
unsafe { self.buf.get_unchecked(idx) }
```

```nix
# router runs openwrt
router = { static_ip = "10.0.1.1"; };
```

> Each comment makes one needed point. The router comment identifies the one host among the NixOS machines that runs OpenWrt. "Not a NixOS machine" would lose the fact that it runs OpenWrt. Changing the casing would only restyle the comment.
