// chara_dump.ts — print a bounded summary of a SillyTavern character card
// (chara_card_v2) WITHOUT emitting card prose, so large or NSFW card bodies
// never enter the agent's context. Depends only on Deno stdlib + ./_card_io.ts.
//
// Usage:
//   deno run --allow-read --allow-write=. chara_dump.ts <card.png> [--out <file.json>]
//
// stdout : compact summary — spec, name, and per-field LENGTHS only (no values).
// --out  : write the full decoded chara JSON (pretty) to <file.json> for
//          human/offline use. The agent passes the path around and never
//          reads the file back into context.
// exit 1 : not a PNG, no "chara" tEXt chunk, or invalid base64 JSON.

import { readCard } from "./_card_io.ts";

const args = [...Deno.args];
let pngPath: string | undefined;
let outFile: string | undefined;
let sawOutFlag = false;
for (let i = 0; i < args.length; i++) {
    if (args[i] === "--out") {
        sawOutFlag = true;
        outFile = args[++i];
    } else if (!pngPath) {
        pngPath = args[i];
    }
}

if (!pngPath) {
    console.error("usage: chara_dump.ts <card.png> [--out <file.json>]");
    Deno.exit(2);
}
if (sawOutFlag && !outFile) {
    console.error("error: --out requires a value");
    Deno.exit(2);
}

let card;
try {
    card = await readCard(pngPath);
} catch (e) {
    console.error(
        `failed to read card from ${pngPath}: ${(e as Error).message}`,
    );
    Deno.exit(1);
}
if (!card) {
    console.error(`no "chara" tEXt chunk found in ${pngPath}`);
    Deno.exit(1);
}
const { obj, data } = card;

const fields = [
    "first_mes",
    "alternate_greetings",
    "creator_notes",
    "description",
    "personality",
    "scenario",
    "mes_example",
    "avatar",
];

/** Detect embedded lorebooks and report presence/entry count. */
function lorebookInfo(d: Record<string, unknown>): string {
    const ext = d.extensions as Record<string, unknown> | undefined;
    const sources: [label: string, value: unknown][] = [
        ["extensions.world", ext?.world],
        ["character_book", d.character_book],
    ];
    const parts: string[] = [];

    const count = (e: unknown): number | undefined => {
        if (Array.isArray(e)) return e.length;
        if (e && typeof e === "object") {
            return Object.keys(e as Record<string, unknown>).length;
        }
        return undefined;
    };

    for (const [label, value] of sources) {
        if (!value || typeof value !== "object") continue;
        const n = count((value as Record<string, unknown>).entries);
        parts.push(
            n !== undefined ? `${label} (${n} entries)` : `${label} (present)`,
        );
    }
    return parts.join("; ");
}

const summary: string[] = [];
summary.push(`spec: ${obj.spec ?? "?"}  version: ${obj.spec_version ?? "?"}`);
summary.push(
    `name: ${
        typeof data.name === "string" && data.name ? data.name : "(none)"
    }`,
);
summary.push("fields:");
for (const f of fields) {
    const v = data[f];
    if (v === undefined) continue;
    const shape = Array.isArray(v)
        ? `${v.length} entries`
        : `${String(v).length} chars`;
    summary.push(`  ${f}: ${shape}`);
}

const lore = lorebookInfo(data);
summary.push(lore ? `lorebook: ${lore}  [NOT scanned]` : "lorebook: none");

console.log(summary.join("\n"));

if (outFile) {
    await Deno.writeTextFile(outFile, JSON.stringify(obj, null, 2));
    console.log(`\nfull json written to ${outFile}`);
}
