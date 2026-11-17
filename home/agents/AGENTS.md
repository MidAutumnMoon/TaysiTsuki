## Communication & User-facing message

The goal of communication is make the knowledge easily comprehendible. You MUST optimize the messages for *visual thinking* person, like "show, don't tell". Use more methods beyond "show, don't tell".

For example, show an actual code snippet, write pseudocode, or make a graph. MUST NOT re-explain the shown subject. Or even better, after showing the subject, don't say unnecessary thing.

Avoid repetitiveness. Don't dump a wall of texts to the user. Say the thing that contributes to new knowledge and stop. MUST separate your thought/operation monologue from user-facing message. Keep details that only matter to you away from user-facing message.

Outdated? Don't repeat it. Domain knowledge? Don't repeat it. User already knows? Don't repeat it. It can be inferred from context? Don't repeat it. MUST NOT explain things like `*subject/fact*, not *negative subject/fact*`, or `*subject* — *supplement to the subject`". Say the subject and STOP.

MUST assume the user has high expertise in the task and the domain. They don't need your teaching on the building blocks. Don't repeat common knowledge of the domain. For example, don't advise "link abc with `cc -labc`", don't repeat "packages from nixpkgs are substituted from cache.nixos.org", or "main returns anyhow::Result so that..."

When writing user-facing messages, MUST use straight, plain and simple language in terms of wording, phrasing, and expression. Avoid any jargon or rarely used words.

## Reusing command & long command

When commands with the same *shape* run a second time, you SHOULD write them down as a script for reusability. You SHOULD write down long commands, too. You SHOULD NOT abuse bash heredoc. Use standard tools like `write` and `edit` etc. Run the written script from then on.

The script SHOULD follow Linux CLI conventions, e.g. CLI parameters, stdin/stdout/stderr, and exit codes.

Put the scripts somewhere outside the workspace, for example `/tmp/<topic>/`. Improve the script in place while reusing it.

## Filesystem searches

MUST NOT perform an unbounded recursive filesystem search from `/` or `/nix/store`. Scope `find`, `grep -r`, `rg`, `fd`, etc. to the current project or another explicitly relevant directory.

If a host-wide search really seems necessary, ask user first.

## Cache command output

MUST NOT pipe costly command's output through `head` and `tail` and discard the rest; tools will properly handle large output natively. MUST NOT pipe test command output.

If you want to be efficient and grep the output, cache the output then grep the file. MUST NOT pipe the output to grep directly.

## Host system

The host OS is latest NixOS despite the "-cachyos" kernel.

Python isn't installed. If you need Python, you MUST use `uv`. You SHOULD NOT replace Python with ugly Bash scripts.

For more host system facts like locating files or missing commands, load `nixos-convention` skill.

## Writing comments

Code comments are not a changelog. MUST NOT write comments as they are records of what you have done.

## Look Things Up

MUST NOT hallucinate options, APIs, flags. Look it up using web search, local cached source code, or Context7.

## Efficiently access remote resources

You SHOULD fetch and store remote resources, then work locally. Prefer efficient access methods like public API if available. Avoid hammering remote service. For example, clone or download the tarball of repositories when working with code forges like Github and Codeberg.

You SHOULD cache the resources to `/tmp` to avoid wasting disk space.

For Github specifically, prefer `gh` cli. `gh api graphql` provides access to powerful but slightly complex GraphQL API; official doc: <https://docs.github.com/api/article/body?pathname=/en/graphql>.
