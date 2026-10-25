---
name: prune-comments-and-docs
description: Review, tighten, and rewrite code comments, doc comments, and prose docs (README, guides, design notes). Use when asked to review, clean up, cut, clarify, or improve comments or documentation.
---

# Prune comments and docs

Write for someone who knows the language, common domain concepts, and the current code, but not its history or context. Name the mistake this reader would make without each comment. If there is none, delete it. Otherwise, keep only what prevents that mistake. Apply this test regardless of who wrote the comment. Being true, current, and unique is not enough.

Comments written during a change tend to narrate what was replaced, split, or implemented, or to defend the design. Keep the reasons a reader needs here. Other rationale belongs in the commit description. If you made the change, assume you're too close to judge. Read each comment as if opening the file for the first time.

## Who reads what

- **Doc comments** (`///`, `//!`, docstrings) serve callers, who see the signature but not the body. State the contract: what it does, what the types don't say, when it fails or panics, and what the caller must ensure. The comment should remain true if the implementation changes but its behavior does not.
- **Inline comments** serve maintainers. Answer the question a maintainer has at this line: why the code is written this way, or what would break if it changed. The answer is usually a constraint, workaround, or consequence. Don't narrate the next lines.
- **Prose docs** serve readers new to the topic. Cover concepts, usage, and decisions that span files. Don't mirror the code, report progress, or repeat contracts documented in doc comments.

Keep the facts each audience needs. A fact may serve two audiences, such as `README` readers and API callers, but should not appear twice for the same audience.

For private items and application code, callers are maintainers who read the body. State each fact once, on the item it describes. A field and its getter don't both need docs.

Prefer expressing a fact through a name, type, error message, assertion, or test rather than a comment. Suggest those changes in your summary. This pass changes only comments and docs, not code.

## The pass

Before pruning, map repeated facts across the full set of files. Do this before parallel reviewers start editing, since each reviewer sees only their assigned files.

Group comments and leftover planning prose around recurring domain terms, such as "state", "rendered", "atomic", and "converge". Give each repeated fact one home per audience. Prefer the item the fact describes. Otherwise, use the first place the reader reaches. Delete the other copies. Any cross-references that remain must pass check 4.

For each comment or passage of documentation, apply these checks in order. Check the whole block and each sentence within it. Act on the first failure.

1. **True?** Read the code it describes. If the code and comment disagree and you can't tell which is wrong, flag the discrepancy. Don't rewrite the comment to match a possible bug.
2. **Needed?** Judge strictly from the current code, not your memory of earlier versions. Name the mistake a reader would make without it. For prose docs, a step or concept a new reader would miss counts as a mistake. If there is none, delete it. Typical cases:
    * The name, signature, types, nearby strings (error messages, test or check labels), assertions, or next few lines already say it.
    * The fact's home already gives this reader everything they need here.
    * The reader already knows it, such as what premultiplied alpha means or how a standard algorithm works.
    * It restates or explains another module's, file's, or dependency's documentation, types, mechanics, or contracts. Exception: a non-obvious choice forced by external behavior, or an implementation that differs from its API documentation. State the relevant fact directly. Don't summarize the other component.
3. **About the current code?** Delete history that assumes the reader knows an earlier version ("now", "no longer", "instead of", "replaced", "split", "moved", "refactored", "originally", "ported from"). Judge the meaning, not the keyword. "Instead of ORing" names a current alternative, and "new routes" is not history. Delete plans too ("will", "could", "eventually", "in the future", "not implemented yet"), including constraints on code that doesn't exist yet ("a future toggle must..."). Preserve real regression guards as present-tense constraints. Keep current limitations ("teardown is not implemented") in plain prose and include them in the duplicate map. Turn intended actions into TODOs or issue links, not narrative.
4. **At the fact's home?** If not, delete it. Keep a cross-reference only when a caller must take another step to use the API correctly, or a maintainer changing this code must check or update another place. State the required action ("new routes also need approval in infra"), not the fact again. Delete references that merely tell the reader where a topic is covered. Keep links to issues, specifications, and upstream bugs that justify a workaround. Move implementation detail from a doc comment to an inline comment only if it explains why the code is written this way. Otherwise, delete it.
5. **Minimal?** Reduce it to what prevents the mistake from check 2. For a comment, that is usually one sentence. Add the reason if that sentence alone would seem arbitrary. Keep one point per inline comment, doc-comment section, and prose paragraph. Move another point only if the reader needs it at another line. Otherwise, drop it even if it has no other home. Cut consequences the reader can infer, restatements, filler, hedges, and asides. Most surviving comments fit in one or two lines.

Delete a whole block if nothing in it prevents a mistake. Otherwise, cut or rewrite each failing sentence. Preserve the fact, not the whole comment. Match the established style in casing, comment markers, and layout, but follow the Sentences rules where they conflict. Leave a comment unchanged if it passes every check and follows the Sentences rules.

Add a comment only when the reader would otherwise get something wrong because a reason or an error, panic, or safety contract is missing. If a comment only explains an unclear name, suggest a rename in your summary instead of polishing it.

Then review each file as a whole. A file is over-commented when its comments mirror the code's structure one for one, even if each comment passes on its own. Remove the entire category, not isolated instances, unless a project convention requires those comments. Bare numbering and labels for deliberate decisions are separate categories. Removing one doesn't remove the other.

## Keep the fact, not the wording

Preserve these facts, but apply check 5 and the Sentences rules to their wording. Leave license notices verbatim.

- Safety contracts and `// SAFETY:` justifications.
- Error, panic, and invariant contracts callers rely on.
- Why the obvious approach wasn't taken, when a maintainer would otherwise try it. State what goes wrong with it.
- Notes that record a deliberate decision a maintainer would otherwise "fix" ("N.B. we deliberately allow src to not exist").
- Test labels that identify the case being set up ("// not ours", "// ancestor is a regular file").
- Links to issues, specs, or upstream bugs behind a workaround.
- License and attribution notices, even when cutting "ported from" narrative.
- Doctests and examples.
- Language and project conventions: `# Errors` / `# Panics` / `# Safety` sections, `missing_docs`, and the existing doc style.

## Cut on sight

- Restated signatures and types: "Takes a `&str` and returns a `Result`".
- Narration of the body: "First iterates..., then...".
- Change logs and process notes: "Refactored to...", "Fixed the bug where...", "Added support for...".
- Mappings to code, designs, or reference implementations the code no longer follows.
- Commented-out code and completed TODOs.
- Empty openers and labels: "Note:", "Important:", "This function...", "Helper to...", "This ensures that...", "upstream quirk:", "host side,".
- Bare sequence markers: "// 1.", "// step 2", "// Case 3".
- Cross-references that merely locate a topic, or trace a request through other components (`a -> b -> c`), when nothing here depends on that information.
- Test comments that announce the next assertion or paraphrase the test name. Name the case or the purpose of the setup instead.
- Claims that the design is sound: "lives in one place", "holds structurally", "single source of truth". Delete the claim, but preserve any fact that prevents a mistake.
- Hype and padding: "robust", "seamless", "comprehensive", "simply", "just".
- Links to types already linked by the signature.
- Doc files that serve as work logs, such as summaries, plans, migration notes, and status reports. Delete the file and name it in your summary.

## Sentences

Apply these to every comment you keep, rewrite, or add.

First find the true focus of the sentence burried in texts. Rules serve to better present this focus.

Shorten by reducing points, not squeezing words. Use complete sentences, but leave labels such as "// not ours" as labels. Keep connectives ("because", "so", "otherwise") that explain how facts relate. Without them, the reader must reconstruct the reason. Don't compress prose into shorthand or replace a plain word with a shorter, vaguer one.

Say what something is or does. Don't define it by what it isn't ("not a managed host", "unlike `retry`"; avoid "not xxx" in general). Use a negative only when it rules out a likely wrong assumption ("without verifying it", "not thread-safe"). Name an alternative only when the reader would consider using it, then explain what goes wrong with it.

Use one point per sentence. Facts that support one point can share a sentence ("`idx < self.len` is checked above, and `buf` never shrinks"). Separate points need separate sentences, regardless of punctuation. Don't use em dashes or imitate them with `;`, `:`, ` - `, or parentheses. A sentence that needs such a join usually carries a second point. Check whether it belongs.

## Language-specific checks

- Rust. Apply every check and Sentences rules. Rewrite failing ones:
    * `reason` in `#[allow(...)]` and `#[expect(...)]` serves the maintainer.
    * Message in `.expect()` and error library's `.context()` serves the user.
    * Message in tracing's `debug!()`, `info!()` and all other macros.

## Examples

### Over-explained contract

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
/// names the path.
pub fn discover(root: &Path) -> Result<Vec<AgentDef>, Report>
```

> The signature already says `Vec` and `Report`. Keep recursion and the `.toml` filter so callers don't assume a shallow search over all file types. Say that errors name the path so callers don't add it again. The rest narrates the body.

### True, unique, and still too long

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

> Keep Wayland's requirement so a maintainer doesn't remove the alpha multiplication as redundant. The reader already knows what premultiplied alpha means. `glass_fill`'s comment repeats its body and defends the design.

### History

Before:

```rust
// Switched from HashMap to BTreeMap so output order is deterministic.
// The sort step after collection is no longer needed.
let mut seen = BTreeMap::new();
```

After:

```rust
// Ordered so output is stable across runs.
let mut seen = BTreeMap::new();
```

> Keep the need for stable output across runs so a maintainer doesn't replace `BTreeMap` with an unordered map. The switch and removed sort step are history.

### A required cross-reference buried in history

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
/// [`verify_archive`] before use.
pub async fn download(url: &Url) -> Result<Bytes>
```

> A caller who assumes verification would use unchecked bytes. Keep the warning and required call to `verify_archive`, not the API's history. Don't summarize `verify_archive`'s documentation or implementation.

### The same fact in several places

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
//! An interrupted run retries against the previous state and converges.

/// Atomically install the state. On failure the previous state is intact.
pub fn write(self) -> Result<()>

#[test]
fn retry_converges() { ... }
```

> The module docs keep the convergence guarantee. `write()` keeps its local failure guarantee because callers need it when handling an error. The test comment repeats the name and body. A `README` may repeat the convergence guarantee for a different audience.

### Several facts rewritten around one point

Before:

```rust
// default 0 (no retries); bundled defaults skipped (see config/README.md).
// server side, retries go gateway -> backend
cfg.set("retries", 3);
```

After:

```rust
// Set explicitly because we skip the bundled defaults, and without them
// the client never retries.
cfg.set("retries", 3);
```

> A maintainer might remove a default-looking setting and disable retries. Keep the reason for setting it explicitly. The `README` pointer and server-side path add nothing here, even if they have no other home. Don't explain `set`'s signature or mechanics.

### Implementation detail in the contract

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
/// Returns the thumbnail for `id`, generating and caching it on a miss.
pub fn thumbnail(&mut self, id: ImageId) -> Result<&Thumbnail> {
    // ...
    // Triangle aliases visibly on line art.
    let small = img.resize(w, h, FilterType::Lanczos3);
```

> Cache layout and decoding steps can change without changing the contract. Move the reason for the filter choice to its line so a maintainer doesn't substitute Triangle and cause aliasing on line art.

### Reference implementation

Before:

```rust
//! Token-bucket rate limiter, ported from the Java reference implementation
//! (`RateLimiter.java`). Unlike the Java version, there is no background
//! refill thread. Instead, `acquire` computes refills lazily, mirroring
//! Java's `reserveEarliestAvailable()`.
```

After: Deleted.

> Delete mappings to reference code once this implementation stands on its own. State any still-needed fact at its home and apply the same checks. Preserve required license and attribution notices.

### Prose docs

Before (`README.md`):

```markdown
## Recent Improvements ✅
- **Refactored** config loading for better maintainability
- **Added** comprehensive error handling
- **Removed** legacy `config.ini` support
```

After: Deleted.

> The section is a change log, and "comprehensive" is padding. A `README` describes the project as it is. If users need to know the config format, document the current format.

### Already minimal

```rust
// SAFETY: `idx < self.len` is checked above, and `buf` never shrinks.
unsafe { self.buf.get_unchecked(idx) }
```

```nix
# router runs openwrt
router = { static_ip = "10.0.1.1"; };
```

> Both comments make one needed point. Without the router comment, a maintainer might manage it like the surrounding NixOS machines. "Not a NixOS machine" would lose the fact that it runs OpenWrt. Changing the casing would only restyle it.

## Finish

1. Review the remaining comments and docs. For each fact assigned a home, search for all its phrasings, not just one keyword ("rendered", "literal", "template text"). Confirm that each fact is stated once per audience. Keep additional references only when they pass check 4. Search every plausible home, including prose docs outside the files initially reviewed.
2. Search comments in the reviewed files for `—`, mid-sentence `;` and `:`, contrasts (`unlike`, `not a`, `rather than`), cross-references (`see`, `lives in`, `->`, file paths), history (`now`, `no longer`, `instead`, `previously`, `old`, `new`, `refactor`), and plans (`will`, `could`, `eventually`, `future`, `not implemented yet`). Each hit is a candidate, not a failure. Change it only if the comment fails a check or breaks the Sentences rules.
3. Reread every kept inline comment or doc section longer than two lines. Reduce it to what prevents the mistake named in check 2.
4. Build docs and run doctests if available. Deletions can break intra-doc links.
5. Report briefly:
    * Files examined.
    * Repeated facts and their chosen homes.
    * Facts dropped despite having no other home, kept comments or doc sections longer than two lines, and other comments you considered cutting but kept. Give each decision one line so the author can veto it. For a keep, that line names the mistake it prevents. "It states a constraint" names no mistake.
    * Rationale cut from comments that belongs in the commit description.
    * Deleted files.
    * Possibly incorrect comments.
    * Suggested renames and other moves into code.

Do not provide a per-edit changelog.
