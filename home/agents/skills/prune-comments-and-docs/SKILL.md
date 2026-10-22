---
name: prune-comments-and-docs
description: Review, tighten, and rewrite code comments, doc comments, and prose docs (README, guides, design notes). Use when asked to review, clean up, cut, clarify, or improve comments or documentation.
---

# Prune comments and docs

Write for someone who knows only the current code, not its history or author. Each comment should make one point the reader needs here and cannot get from the code. Use one point per doc-comment section and per prose paragraph. Tell each fact once per audience.

Comments written during a change often describe the change: what was replaced, split, or just implemented, and how. That belongs in the commit message. If you made the change, assume you're too close to judge. Read each comment as if opening the file for the first time.

## Who reads what

- **Doc comments** (`///`, `//!`, docstrings) serve callers. State the contract: what it does, what the types don't say, when it fails or panics, and what the caller must ensure. The whole comment should stay true if the body is rewritten with the same behavior.
- **Inline comments** serve maintainers. Answer their question at this line: why it's this way, or what breaks if they change it. The answer is usually a constraint, workaround, or consequence. Don't narrate the next lines.
- **Prose docs** serve someone arriving cold. Cover concepts, usage, and decisions that span files. Don't mirror the code, report progress, or repeat contracts owned by doc comments.

Each kind holds the facts its audience needs. A fact may serve two audiences, such as `README` readers and API callers, but should not appear twice for one audience.

A fact often belongs in a name, type, error message, assertion, or test rather than a comment. Prefer those homes. Suggest such moves in your summary; this pass changes comments and docs, not code.

## The pass

Map duplicates before pruning. Group comments and leftover planning prose around recurring domain terms ("state", "rendered", "atomic", "converge"). Give each repeated fact one home per audience. Prefer the item the fact describes; otherwise, use the first place the reader reaches. Delete the other copies. Check 4 governs any pointers that remain.

Parallel reviewers each see only their own files, so map duplicates across the whole set before editing starts.

For each comment, apply these checks in order. Act on the first failure.

1. **True?** Read the code it describes. If they disagree and you can't tell which is wrong, flag it. Don't rewrite the comment to match a possible bug.
2. **Needed?** Check strictly from the perspective of the codes, never your past memory. Delete it if the name, signature, types, nearby strings (error messages, test or check labels), or next few lines already say it. Also delete it if the fact's home already gives this reader everything they need here.
3. **About the current code?** Delete history that depends on knowing an earlier version ("now", "no longer", "instead of", "replaced", "split", "moved", "refactored", "originally", "ported from"). Judge the meaning, not the marker: "instead of ORing" names a live alternative, and "new routes" is not history. Delete plans too ("will", "could", "eventually", "in the future", "not implemented yet"). Preserve a real regression guard as a present-tense constraint. Keep current limitations ("teardown is not implemented") as plain prose and include them in the duplicate map. Turn intended actions into TODOs or issue links, not narrative.
4. **At the fact's home?** If not, delete it. Keep a pointer only when a caller must take another step to use the API correctly, or a maintainer changing this code must check or update another place. State the obligation ("new routes also need approval in infra"), not the fact again. A pointer that merely locates a topic is a tour. Keep links to issues, specs, and upstream bugs that justify a workaround. Move implementation detail from a doc comment inline only if it explains why; otherwise, delete it.
5. **Clear at a glance?** Fail if the point is buried, an inline comment makes several points, or filler, hedges, or asides pad it. Keep the point this reader needs here. Move another point only if the reader needs it at another line. Otherwise, drop it even if it has no other home.

A comment that passes all these five stays. Fix failed comments and docs. Match the file's comment style: casing, punctuation, and terseness.

Delete by default: a comment goes unless it holds a fact with no other home. Rewriting may keep that fact, not the whole comment. Identify the reader's question at this line, answer it in a sentence, and add the reason if the answer alone seems arbitrary. Add a comment only when the reader would otherwise get something wrong: a missing why, or a missing error, panic, or safety contract. If a comment only explains an unclear name, suggest a rename in your summary instead of polishing it.

Judge whole blocks, not just sentences. For a comment longer than two lines, ask whether deleting it loses anything this reader needs. If not, delete it. If the code's structure predicts the comment (bare numbering, section dividers, enum glosses), it's narration; cut it.

Then review the whole file. When comments mirror the code's structure one to one, the file is over-commented even if each comment passes alone. Cut the class, not individual instances, unless a project convention requires it. Keep classes distinct: bare numbering and labeled decisions are different classes.

## Keep

- Safety contracts and `// SAFETY:` justifications.
- Error, panic, and invariant contracts callers rely on.
- Why the obvious approach wasn't taken, stated as what goes wrong with it.
- Notes and test labels that mark a deliberate decision ("N.B. we deliberately allow src to not exist") or name the case being set up ("// not ours", "// ancestor is a regular file").
- Links to issues, specs, or upstream bugs behind a workaround.
- License and attribution notices, even when cutting "ported from" narrative.
- Doctests and examples.
- Language and project conventions: `# Errors` / `# Panics` / `# Safety` sections, `missing_docs`, and the existing doc style.

## Cut on sight

- Restated signatures and types: "Takes a `&str` and returns a `Result`".
- Narration of the body: "First iterates..., then...".
- Change logs and process: "Refactored to...", "Fixed the bug where...", "Added support for...".
- Mappings to code, designs, or reference implementations the code no longer follows.
- Commented-out code and completed TODOs.
- Empty openers and labels: "Note:", "Important:", "This function...", "Helper to...", "This ensures that...", "upstream quirk:", "host side,". Bare sequence markers: "// 1.", "// step 2", "// Case 3".
- Tours: where else a topic lives, or how a request passes through other components (`a -> b -> c`), when nothing at this line depends on it.
- Assert predictions in tests: comments announcing what the next assert checks. Name the case or setup intent instead.
- Hype and padding: "robust", "seamless", "comprehensive", "simply", "just".
- Links on types the signature already links.
- Doc files that serve as work logs (summaries, plans, migration notes, status reports). Delete the file and name it in your summary.

## Sentences

These rules apply to rewrites and new comments. They are not a sixth check. A comment that passes the five keeps its wording even if it breaks these rules.

Shorten by reducing points, not squeezing words. Use whole sentences, but let labels like "// not ours" stay labels. Keep connectives ("because", "so", "otherwise") that explain the relationship between facts. Without them, the reader must reconstruct the reason. Don't compress into note-speak or replace a plain word with a shorter, vaguer one.

Say what the thing is or does. Don't define it through what it isn't ("not a managed host", "unlike `retry`"). Use a negative when it rules out a likely wrong assumption ("without verifying it", "not thread-safe"). Name an alternative only when the reader would reach for it, then say what goes wrong with it.

Use one point per sentence. Facts that support one point can share a sentence ("`idx < self.len` is checked above, and `buf` never shrinks"). Separate points cannot, however you join them. Don't use em dashes or imitate them with `;`, `:`, ` - `, or parentheses. If a sentence needs such a join, check whether it holds two points and whether both belong.

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
/// names the path.
pub fn discover(root: &Path) -> Result<Vec<AgentDef>, Report>
```

The signature already says `Vec` and `Report`. "Walks, reads, parses, collects" narrates the body. Keep the contract.

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

Keep the reason, not the history. The reader need not know about the HashMap.

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

The caller needs their obligation, not the architecture's history. "Without verifying it" rules out a likely wrong assumption. The pointer survives because the caller must act on it. The removed helper is irrelevant.

**The same fact in several places**

```rust
// Before
//! An interrupted run retries against the previous state and converges.

/// Atomically install the state. A failure leaves the previous state
/// intact, so a retry converges.
pub fn write(self) -> Result<()>

// Retry converges and records the new generation.
#[test]
fn retry_converges() { ... }

// After
//! An interrupted run retries against the previous state and converges.

/// Atomically install the state. On failure the previous state is intact.
pub fn write(self) -> Result<()>

#[test]
fn retry_converges() { ... }
```

The module doc owns the convergence fact and stays unchanged. `write()` keeps its local failure guarantee. The test comment adds nothing beyond the test name and body. A `README` may repeat the convergence guarantee if it serves a different audience.

**A pile of facts rewritten around its point**

```rust
// Before
// default 0 (no retries); bundled defaults skipped (see config/README.md).
// server side, retries go gateway -> backend
cfg.set("retries", 3);

// After
// Set explicitly because we skip the bundled defaults, and without them
// the client never retries.
cfg.set("retries", 3);
```

The reader's question is why a default-looking value is set explicitly. "Because" connects the facts into an answer. The pointer and server-side path are tours; nothing here depends on them.

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
/// Returns the thumbnail for `id`, generating and caching it on a cache miss.
pub fn thumbnail(&mut self, id: ImageId) -> Result<&Thumbnail> {
    // ...
    // Triangle aliases visibly on line art.
    let small = img.resize(w, h, FilterType::Lanczos3);
```

Cache layout and decoding steps can change without changing the contract. The filter choice explains why, so it moves to the relevant line. Naming Triangle helps because a maintainer might choose it, and the comment explains the consequence.

**Reference implementation**

```rust
// Before
//! Token-bucket rate limiter, ported from the Java reference implementation
//! (`RateLimiter.java`). Unlike the Java version, there is no background
//! refill thread. Instead, `acquire` computes refills lazily, mirroring
//! Java's `reserveEarliestAvailable()`.

// After
//! Token-bucket rate limiter. Tokens refill lazily inside `acquire`, so
//! idle limiters do no refill work.
```

Mappings to reference code rot as implementations diverge. Keep the fact the reader needs, along with any required license or attribution notice.

**Leave these alone**

```rust
// SAFETY: `idx < self.len` is checked above, and `buf` never shrinks.
unsafe { self.buf.get_unchecked(idx) }

// `fs::rename` fails across mount points, and the temp dir is often tmpfs.
fs::copy(&tmp, &dest)?;
fs::remove_file(&tmp)?;
```

```nix
# router runs openwrt
router = { static_ip = "10.0.1.1"; };
```

These supply facts the code doesn't. The router comment identifies its OS in the author's style. Replacing it with "not a NixOS machine" would emphasize a comparison instead. Fixing its casing would restyle a comment that passed.

**Prose docs**

```markdown
<!-- Before, in README.md -->
## Recent Improvements ✅
- **Refactored** config loading for better maintainability
- **Added** comprehensive error handling
- **Removed** legacy `config.ini` support
```

Delete the section. A `README` describes the project as it is. If users need the config format, document the current format.

## Finish

1. Re-scan the survivors. For each fact assigned a home, search for all its phrasings, not one keyword ("rendered", "literal", "template text"). Verify one statement of each fact per audience. Keep additional references only when they satisfy check 4. Search every plausible home, including prose docs outside the reviewed scope.
2. Search comments in the reviewed files for `—`, mid-sentence `;` and `:`, contrasts (`unlike`, `not a`, `rather than`), pointers (`see`, `lives in`, `->`, file paths), history (`now`, `no longer`, `instead`, `previously`, `old`, `new`, `refactor`), and plans (`will`, `could`, `eventually`, `not implemented yet`). Each hit is a candidate, not a failure. Change it only if the comment fails a check, or if text you wrote breaks "Sentences".
3. Build docs and run doctests if available. Deletions can break intra-doc links.
4. Report briefly: files examined; repeated facts and their chosen homes; points dropped with no other home (one line each so the author can veto); deleted files; possibly incorrect comments; suggested renames and other code moves. No per-edit changelog.
