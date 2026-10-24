---
name: prune-comments-and-docs
description: Review, tighten, and rewrite code comments, doc comments, and prose docs (README, guides, design notes). Use when asked to review, clean up, cut, clarify, or improve comments or documentation.
---

# Prune comments and docs

Write for someone who knows the current code but not the history or context behind it. Each comment should make a point the reader needs here and cannot get from the code. Keep one point per inline comment, doc-comment section, and prose paragraph. State each fact once per audience.

Comments written during a change often describe what was replaced, split, or implemented, and how. That's bad for readable comments.
If you made the change, assume you're too close to judge. Read each comment as if opening the file for the first time.

## Who reads what

- **Doc comments** (`///`, `//!`, docstrings) serve callers. State the contract: what it does, what the types don't say, when it fails or panics, and what the caller must ensure. The comment should remain true if the implementation changes but its behavior does not.
- **Inline comments** serve maintainers. Answer the question a maintainer has at this line: why the code is written this way, or what would break if it changed. The answer is usually a constraint, workaround, or consequence. Don't narrate the next lines.
- **Prose docs** serve readers new to the topic. Cover concepts, usage, and decisions that span files. Don't mirror the code, report progress, or repeat contracts documented in doc comments.

Keep the facts each audience needs. A fact may serve two audiences, such as `README` readers and API callers, but should not appear twice for the same audience.

Prefer expressing a fact through a name, type, error message, assertion, or test rather than a comment. Suggest those changes in your summary. This pass changes only comments and docs, not code.

## The pass

Before pruning, map repeated facts across the full set of files. Do this before parallel reviewers start editing, since each reviewer sees only their assigned files.

Group comments and leftover planning prose around recurring domain terms, such as "state", "rendered", "atomic", and "converge". Give each repeated fact one home per audience. Prefer the item the fact describes. Otherwise, use the first place the reader reaches. Delete the other copies. Any cross-references that remain must pass check 4.

For each comment or passage of documentation, apply these checks in order. Check the whole block and each sentence within it. Act on the first failure.

1. **True?** Read the code it describes. If the code and comment disagree and you can't tell which is wrong, flag the discrepancy. Don't rewrite the comment to match a possible bug.
2. **Needed?** Judge strictly from the current code, not your memory of earlier versions:
    * Delete it if the name, signature, types, nearby strings (error messages, test or check labels), or next few lines already say it.
    * Delete it if the fact's home already gives this reader everything they need here.
    * Delete it if it restates or explains another module's, file's, or dependency's documentation, types, signatures, mechanics, implementations, or contracts. Exception: non-obvious choice forced by external behavior, or implementation differing from its API documentation. State the relevant fact directly. Don't summarize the other component.
3. **About the current code?** Delete history that assumes the reader knows an earlier version ("now", "no longer", "instead of", "replaced", "split", "moved", "refactored", "originally", "ported from"). Judge the meaning, not the keyword: "instead of ORing" names a current alternative, and "new routes" is not history. Delete plans too ("will", "could", "eventually", "in the future", "not implemented yet"). Preserve real regression guards as present-tense constraints. Keep current limitations ("teardown is not implemented") in plain prose and include them in the duplicate map. Turn intended actions into TODOs or issue links, not narrative.
4. **At the fact's home?** If not, delete it. Keep a cross-reference only when a caller must take another step to use the API correctly, or a maintainer changing this code must check or update another place. State the required action ("new routes also need approval in infra"), not the fact again. Delete references that merely tell the reader where a topic is covered. Keep links to issues, specifications, and upstream bugs that justify a workaround. Move implementation detail from a doc comment to an inline comment only if it explains why the code is written this way. Otherwise, delete it.
5. **Clear at a glance?** Fail if the point is buried, an inline comment makes several points, or filler, hedges, or asides pad the text. Keep the point this reader needs here. Move another point only if the reader needs it at another line. Otherwise, drop it even if it has no other home.

Keep comment or doc passage that passes all five checks. Delete a whole block if it has no useful content; otherwise, cut or rewrite each failing sentence while preserving any unique fact. Match established style,

Delete by default. Cut any comment unless it contains a unique fact with no other home. When rewriting, preserve the fact, not the whole comment.

Identify the reader's question at this line and answer it in one sentence. Add the reason if the answer alone would seem arbitrary. Add a comment only when the reader would otherwise get something wrong because a reason or an error, panic, or safety contract is missing. If a comment only explains an unclear name, suggest a rename in your summary instead of polishing it.

Then review each file as a whole. A file is over-commented when its comments mirror the code's structure one for one, even if each comment passes on its own. Remove the entire category, not isolated instances, unless a project convention requires those comments. Treat bare numbering and comments that label deliberate decisions as separate categories.

## Keep

- Safety contracts and `// SAFETY:` justifications.
- Error, panic, and invariant contracts callers rely on.
- Why the obvious approach wasn't taken, stated as what goes wrong with it.
- Notes and test labels that record a deliberate decision ("N.B. we deliberately allow src to not exist") or identify the case being set up ("// not ours", "// ancestor is a regular file").
- Links to issues, specs, or upstream bugs behind a workaround.
- License and attribution notices, even when cutting "ported from" narrative.
- Doctests and examples.
- Language and project conventions: `# Errors` / `# Panics` / `# Safety` sections, `missing_docs`, and the existing doc style.

Apply "Sentences" rules on kept ones. "Keep" doesn't mean keep them as-is.

## Cut on sight

- Restated signatures and types: "Takes a `&str` and returns a `Result`".
- Narration of the body: "First iterates..., then...".
- Change logs and process notes: "Refactored to...", "Fixed the bug where...", "Added support for...".
- Mappings to code, designs, or reference implementations the code no longer follows.
- Commented-out code and completed TODOs.
- Empty openers and labels: "Note:", "Important:", "This function...", "Helper to...", "This ensures that...", "upstream quirk:", "host side,".
- Bare sequence markers: "// 1.", "// step 2", "// Case 3".
- Cross-references that merely locate a topic, or trace a request through other components (`a -> b -> c`), when nothing here depends on that information.
- Comments announcing what the next assertion checks. Name the case or the purpose of the setup instead.
- Hype and padding: "robust", "seamless", "comprehensive", "simply", "just".
- Links to types already linked by the signature.
- Doc files that serve as work logs, such as summaries, plans, migration notes, and status reports. Delete the file and name it in your summary.

## Sentences

These rules apply to rewrites and new comments. They are not a sixth check. A comment that passes the five checks keeps its wording even if it breaks these rules.

Shorten by reducing points, not squeezing words. Use complete sentences, but leave labels such as "// not ours" as labels. Keep connectives ("because", "so", "otherwise") that explain how facts relate. Without them, the reader must reconstruct the reason. Don't compress prose into shorthand or replace a plain word with a shorter, vaguer one.

Say what something is or does. Don't define it by what it isn't ("not a managed host", "unlike `retry`"). Use a negative when it rules out a likely wrong assumption ("without verifying it", "not thread-safe"). Name an alternative only when the reader would consider using it, then explain what goes wrong with it.

Use one point per sentence. Facts that support one point can share a sentence ("`idx < self.len` is checked above, and `buf` never shrinks"). Separate points need separate sentences, regardless of punctuation. Don't use em dashes or imitate them with `;`, `:`, ` - `, or parentheses. If a sentence needs such a join, check whether it contains two points and whether both belong.

## Language specific checks

- Rust:
    * `#[allow(..., reason = "...")]` and `#[expect(..., reason = "...")]` serves the maintainer. Apply same rules on `reason`'s content.

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

> The signature already says `Vec` and `Report`. "Walks, reads, parses, collects" narrates the body. Keep the contract.

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

> Keep the reason, not the history. The point is stable output across runs, not the switch from `HashMap` or an explanation of `BTreeMap`.

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

> The caller needs the verification requirement, not the API's history. "Without verifying it" rules out a likely wrong assumption. The link stays because the caller must act on it. Don't restate or explain `verify_archive`'s documentation or implementation.

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

> The convergence guarantee belongs in the module documentation, which stays unchanged. `write()` keeps its local failure guarantee. The test comment adds nothing beyond the test name and body. A `README` may repeat the convergence guarantee if it serves a different audience.

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

> The reader needs to know why a default-looking value is set explicitly. "Because" connects the facts into an answer. The cross-reference and server-side path add no needed information at this line. Don't explain `set`'s signature or mechanics.

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
/// Returns the thumbnail for `id`, generating and caching it on a cache miss.
pub fn thumbnail(&mut self, id: ImageId) -> Result<&Thumbnail> {
    // ...
    // Triangle aliases visibly on line art.
    let small = img.resize(w, h, FilterType::Lanczos3);
```

> Cache layout and decoding steps can change without changing the contract. The filter choice explains why, so it moves to the relevant line. Naming Triangle helps because a maintainer might choose it and needs to know the consequence.

### Reference implementation

Before:

```rust
//! Token-bucket rate limiter, ported from the Java reference implementation
//! (`RateLimiter.java`). Unlike the Java version, there is no background
//! refill thread. Instead, `acquire` computes refills lazily, mirroring
//! Java's `reserveEarliestAvailable()`.
```

After: Deleted.

> Delete mappings to reference code once the implementation is fully integrated. Put any still-needed facts where they belong in this project and apply the same pruning checks. Keep required license and attribution notices.

### Prose docs

Before (`README.md`):

```markdown
## Recent Improvements ✅
- **Refactored** config loading for better maintainability
- **Added** comprehensive error handling
- **Removed** legacy `config.ini` support
```

After: Deleted.

> Delete the section. A `README` describes the project as it is. If users need to know the config format, document the current format.

### Exception: Leave these alone

```rust
// SAFETY: `idx < self.len` is checked above, and `buf` never shrinks.
unsafe { self.buf.get_unchecked(idx) }
```

```nix
# router runs openwrt
router = { static_ip = "10.0.1.1"; };
```

> These comments supply facts the code doesn't. The router comment identifies its operating system in the author's style. Replacing it with "not a NixOS machine" would substitute a comparison for that fact. Changing its casing would restyle a comment that already passes.

## Finish

1. Review the remaining comments and docs. For each fact assigned a home, search for all its phrasings, not just one keyword ("rendered", "literal", "template text"). Confirm that each fact is stated once per audience. Keep additional references only when they pass check 4. Search every plausible home, including prose docs outside the files initially reviewed.
2. Search comments in the reviewed files for `—`, mid-sentence `;` and `:`, contrasts (`unlike`, `not a`, `rather than`), cross-references (`see`, `lives in`, `->`, file paths), history (`now`, `no longer`, `instead`, `previously`, `old`, `new`, `refactor`), and plans (`will`, `could`, `eventually`, `not implemented yet`). Each hit is a candidate, not a failure. Change it only if the comment fails a check or text you wrote breaks the "Sentences" rules.
3. Build docs and run doctests if available. Deletions can break intra-doc links.
4. Report briefly:
    * Files examined.
    * Repeated facts and their chosen homes.
    * Facts dropped despite having no other home, and comments you considered cutting but kept. Give each decision one line so the author can veto it.
    * Deleted files.
    * Possibly incorrect comments.
    * Suggested renames and other moves into code.

Do not provide a per-edit changelog.

