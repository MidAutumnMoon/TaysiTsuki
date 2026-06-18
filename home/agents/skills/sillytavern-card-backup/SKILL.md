---
name: sillytavern-card-backup
description: Back up pictures referenced by URL in SillyTavern / chara_card_v2 character card PNGs. Use when the user has a .png character card and wants to inspect it, list, or download the pictures its first messages link to. Use ONLY for SillyTavern character cards, not arbitrary images.
---

# SillyTavern Character Card Image Backup

## When to use

- The user has a `.png` that is a **SillyTavern / `chara_card_v2` character card**.
- The user wants to **inspect** the card, **list** the picture URLs it references, or **download/back up** the pictures its first messages link to.

Not for ordinary PNG images, and not for backing up the card PNG itself.

## Field scope

"First messages" = **`data.first_mes` plus every entry in `data.alternate_greetings`** — nothing else.

| field                 | what it is                                    | use for backup? |
| --------------------- | --------------------------------------------- | --------------- |
| `first_mes`           | the default first message                     | **yes**         |
| `alternate_greetings` | array of additional first messages            | **yes**         |
| `creator_notes`       | author notes (often HTML, may contain images) | **no — ignore** |
| `description`         | character description text                    | no              |
| `avatar`              | card avatar URL                               | no              |

> **Not scanned (out of scope):** embedded lorebooks (`data.extensions.world`, `data.character_book`) and external lorebook files. Any picture URL that lives only inside a lorebook entry will be missed — do not claim the backup is complete if the card carries a lorebook.

## Host constraints

- **Deno only** — the host has no Python/Node. Run the bundled scripts with `deno run`.

## Bundled scripts

Required Deno permissions are listed below.

### `scripts/chara_dump.ts` — inspect a card

Prints a **bounded summary** to stdout (spec, name, per-field lengths only —
no card prose), so large or NSFW card bodies never enter the agent's context.
Run this first to see the card name, greeting count, and lorebook presence
without dumping prose into context. Pass `--out <file>`
to write the full decoded JSON to disk; hand the path around, never read the
file back into context.

```
deno run --allow-read --allow-write=. scripts/chara_dump.ts <card.png> [--out <file.json>]
```

### `scripts/backup_card_images.ts` — find and download pictures

Scans `first_mes` + `alternate_greetings` for picture URLs and downloads each
to the output dir. Files are named `<source>__<original-filename>` where
`source` is `first_mes` or `greeting_<n>`, so you always know which greeting
a file came from.

```
deno run --allow-read --allow-write --allow-net \
  scripts/backup_card_images.ts \
  <card.png> [out_dir] [--dry-run]
```

- `out_dir` defaults to `./backups`.
- `--dry-run` lists the URLs it would download without fetching anything.

**Filename collisions:** The script writes files flat into `out_dir`. When processing multiple cards, use a distinct directory per card (e.g. `backups/CardName/`) to avoid cross-card filename collisions.

The script exits `0` only if every URL was fetched; dead links (host returns
non-200, e.g. 404) are reported and cause a non-zero exit so partial failures
are visible. Dead links cannot be recovered — surface them to the user and
suggest swapping them in the card.

## Workflow

1. **Inspect** with `chara_dump.ts` to confirm it's `chara_card_v2`, see the
   card name, greeting count, and whether an unscanned lorebook is present.
2. **Preview** with `backup_card_images.ts --dry-run` so you can show the user
   the count and sources before touching the network.
3. **Download** with `backup_card_images.ts <card> <out_dir>`.
4. **Report**: how many succeeded vs. failed (dead links), where the files
   landed, and list any dead URLs verbatim.
