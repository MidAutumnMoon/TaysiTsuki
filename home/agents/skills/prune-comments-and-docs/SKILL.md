---
name: prune-comments-and-docs
description: Review and tighten code comments, doc comments, and prose docs (README, guides, design notes). Use when asked to review, clean up, cut, or improve comments or documentation.
---

# Prune comments and docs

Write for a reader who sees only the current code, has never seen a previous version, and doesn't know who wrote it. A comment earns its place by telling that reader something they need, at the spot they're reading, that the code doesn't already say.

Bad comments are usually written during a change and describe the change: what was replaced, what was split, what was just implemented and how. That belongs in the commit message. If you made the change, you're the worst judge of this. Read each comment as if opening the file for the first time.

## Who reads what

- **Doc comments** (`///`, `//!`, docstrings) serve callers. State the contract: what it does, what the types don't say, when it fails or panics, what the caller must ensure. It should stay true if the body is rewritten with the same behavior.
- **Inline comments** serve maintainers. Explain why the code is this way where the code alone would mislead: a constraint, a workaround, a rejected obvious alternative. Don't narrate what the next lines do.
- **Prose docs** serve someone arriving cold. Cover concepts, usage, and decisions that span files. Don't mirror the code or report progress.

## The pass

Check each comment in order. Act on the first failure.

1. **True?** Read the code it describes. If they disagree and you can't tell which is wrong, flag it. Don't make the comment match what might be a bug.
2. **Needed?** If the name, signature, types, or next few lines already say it, delete it.
3. **Free of history?** If it only makes sense to someone who saw an earlier version ("now", "no longer", "instead of", "replaced", "split", "moved", "refactored", "originally", "ported from"), delete it. If it guards against a real regression, restate it as a present-tense constraint.
4. **In the right place?** A fact about another item belongs on that item. Here, keep only what this reader must do about it. Implementation detail in a doc comment moves inline if it explains a why. Otherwise it goes.
5. **As short as it can be?** Point first. Most doc comments need one sentence. Cut filler, hedges, and asides.

A comment that passes all five stays untouched, word for word.

Prefer, in order: delete, shorten, move, rewrite. Add a comment only when a reader would otherwise get something wrong: a missing why, or a missing error, panic, or safety contract. If a comment exists only to explain an unclear name, suggest the rename in your summary instead of polishing the comment.

## Keep

- Safety contracts and `// SAFETY:` justifications.
- Error, panic, and invariant contracts that callers rely on.
- Why the obvious approach wasn't taken.
- Links to issues, specs, or upstream bugs behind a workaround.
- License and attribution notices, even when cutting "ported from" narrative.
- Doctests and examples. The compiler checks them. It doesn't check prose.
- Conventions the language or project enforces: `# Errors` / `# Panics` / `# Safety` sections, `missing_docs`, the existing doc style.

## Cut on sight

- Restated signatures and types: "Takes a `&str` and returns a `Result`".
- Narration of the body: "First iterates..., then...".
- Change logs and process: "Refactored to...", "Fixed the bug where...", "Added support for...".
- Mappings to code, designs, or reference implementations the code no longer follows.
- The same fact in several places. Keep it once, on the item it's about.
- Commented-out code. TODOs that are done.
- Labels and throat-clearing: "Note:", "Important:", "This function...", "Helper to...", "This ensures that...".
- Hype and padding: "robust", "seamless", "comprehensive", "simply", "just".
- Links on types the signature already links.
- Doc files that are work logs (summaries, plans, migration notes, status reports). Delete the file and name it in your summary.

No em dashes. An em dash usually attaches an aside that should be cut. Restructure the sentence rather than swapping in `;`, `:`, ` - `, or parentheses.

## Examples

**Over-explained contract**

```rust
// Before
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

// After
/// Loads every `.toml` agent definition under `root`, recursively.
///
/// # Errors
///
/// Fails if a directory can't be read or a file doesn't parse. The error
/// names the file.
pub fn discover(root: &Path) -> Result<Vec<AgentDef>, Report>
```

The signature already says `Vec` and `Report`. "Walks, reads, parses, collects" narrates the body. What's left is the contract.

**History**

```rust
// Before
// Switched from HashMap to BTreeMap so output order is deterministic.
// The sort step after collection is no longer needed.
let mut seen = BTreeMap::new();

// After
// Ordered so output is stable across runs.
let mut seen = BTreeMap::new();
```

The reason survives. The history doesn't. Nobody reading this has seen the HashMap.

**Cross-reference told as a story**

```rust
// Before
/// Downloads the archive from `url`.
///
/// The fetch-and-verify pipeline was split into two steps: this function
/// only downloads, and checksum validation now lives in [`verify_archive`].
/// The old `fetch_verified` helper has been removed.
pub async fn download(url: &Url) -> Result<Bytes>

// After
/// Downloads the archive from `url` without verifying it. Pass the bytes to
/// [`verify_archive`] before use.
pub async fn download(url: &Url) -> Result<Bytes>
```

The caller needs their obligation, not the architecture's history. `fetch_verified` doesn't exist, so that sentence can't help anyone.

**Implementation detail in the contract**

```rust
// Before
/// Returns the thumbnail for `id`, generating it on a cache miss.
///
/// Uses an LRU cache (a `HashMap` plus a `VecDeque` for recency) holding
/// 256 entries. On a miss, decodes with `image::open`, resizes with
/// Lanczos3, and inserts, evicting the least recently used entry. Lanczos3
/// is used because Triangle aliased visibly on line art.
pub fn thumbnail(&mut self, id: ImageId) -> Result<&Thumbnail>

// After
/// Returns the thumbnail for `id`, generating and caching it on first use.
pub fn thumbnail(&mut self, id: ImageId) -> Result<&Thumbnail> {
    // ...
    // Triangle is faster but aliases visibly on line art.
    let small = img.resize(w, h, FilterType::Lanczos3);
```

Cache layout and decode steps can change without the contract changing. The filter choice is a real why, so it moves to the line it explains.

**Reference implementation**

```rust
// Before
//! Token-bucket rate limiter, ported from the Java reference implementation
//! (`RateLimiter.java`). Unlike the Java version, there is no background
//! refill thread. Instead, `acquire` computes refills lazily, mirroring
//! Java's `reserveEarliestAvailable()`.

// After
//! Token-bucket rate limiter. Tokens refill lazily inside `acquire`, so an
//! idle limiter costs nothing.
```

The reader won't open the Java code, and mappings to it rot as the code diverges. Keep the fact a user cares about. Keep a license notice if one is required.

**Leave these alone**

```rust
// SAFETY: `idx < self.len` is checked above, and `buf` never shrinks.
unsafe { self.buf.get_unchecked(idx) }

// `fs::rename` fails across mount points, and the temp dir is often tmpfs.
fs::copy(&tmp, &dest)?;
fs::remove_file(&tmp)?;
```

Each says something the code can't, and stays true as long as the code below it does.

**Prose docs**

```markdown
<!-- Before, in README.md -->
## Recent Improvements ✅
- **Refactored** config loading for better maintainability
- **Added** comprehensive error handling
- **Removed** legacy `config.ini` support
```

Delete the section. A README describes the project as it is. If users need the config format, document the format that exists.

## Finish

1. Search comments in the reviewed files for `—` and history words (`now`, `no longer`, `instead`, `previously`, `old`, `new`, `refactor`). Recheck each hit.
2. Build docs and run doctests if the project has them. Deletions break intra-doc links.
3. Report briefly: deleted files, comments flagged as possibly wrong, suggested renames. No per-edit changelog.
