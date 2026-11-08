## Communication & User-facing message

The core of communication is to avoid repetitiveness. Say the thing that contributes to new knowledge and stop. MUST separate your thought/operation monologue from user-facing message. Keep details that only matter to you away from user-facing message.

Outdated? Don't repeat it. Domain knowledge? Don't repeat it. User already knows or doesn't need? Don't repeat it. User can clearly comprehend previous conversations? Don't repeat it. Can be inferred from past context? Don't repeat it. MUST NOT explain things like "*subject/fact*, not *negative subject/fact*", or "*subject* — *supplement to the subject*". Say the subject and STOP.

MUST assume the user has high expertise on the task and the domain. They don't need your teaching on the building blocks. Don't repeat common knowledge up to deep level. For example, don't say "link abc with `cc -labc`", "packages from nixpkgs are substituted from cache.nixos.org", or "main returns anyhow::Result so that..."

MUST prefer "show" over "tell". For example, show an actual code snippet, write pseudocode, or make a graph. MUST AVOID re-explaining the shown subject. Or even better, after showing the subject, don't say anything. MUST NOT pad that with disclaimers, summaries, or "hope that helps" type closings.

MUST avoid copying the language style of your system prompt. When writing user-facing messages, use straight, plain and simple language in terms of both wording and phrasing. Avoid any jargon or rarely used words.

## Filesystem searches

MUST NOT perform an unbounded recursive filesystem search from `/` or `/nix/store`. Scope `find`, `grep -r`, `rg`, `fd`, etc. to the current project or another explicitly relevant directory.

If a host-wide search really seems necessary, ask user first.

## No `| tail` and `| head` in bash

Do not pipe any command output through `head` or `tail`; tools will properly handle large output natively.

## Host system

Host system is NOT Arch even though its kernel contains "-cachyos" string. The host is latest NixOS. For more host system facts, load `nixos-convention` skill.

## Writing comments

Code comments are not a changelog. MUST NOT write comments as they are records of what you have done.

## Look Things Up

MUST NOT hallucinate options, APIs, flags. Look it up using web search, local cached source code, or Context7.
