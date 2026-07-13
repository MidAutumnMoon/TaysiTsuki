// backup_card_images.ts — find picture URLs in a SillyTavern character card's
// first messages (data.first_mes + data.alternate_greetings) and
// description (data.description), then download each.
// Depends only on Deno stdlib + ./_card_io.ts.
//
// Usage:
//   deno run --allow-read --allow-write --allow-net \
//     backup_card_images.ts <card.png> [out_dir] [--dry-run]
//
// - out_dir defaults to ./backups
// - --dry-run lists URLs without downloading
// - exits 0 only if every URL was fetched; any failure (e.g. 404) => exit 1

import { readCard } from "./_card_io.ts";

const args = Deno.args;
const dryRun = args.includes("--dry-run");
const positional = args.filter((a) => a !== "--dry-run");
const pngPath = positional[0];
const outDir = positional[1] ?? "./backups";

if (!pngPath) {
    console.error(
        "usage: backup_card_images.ts <card.png> [out_dir] [--dry-run]",
    );
    Deno.exit(2);
}

// --- 1. extract + decode card ---
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
const { data } = card;

// --- 2. collect text fields to scan (first_mes, alternate_greetings, description) ---
const greetings = Array.isArray(data.alternate_greetings)
    ? data.alternate_greetings
    : [];
const messages = [
    { label: "first_mes", text: String(data.first_mes ?? "") },
    { label: "description", text: String(data.description ?? "") },
    ...greetings.map((g, i) => ({
        label: `greeting_${i}`,
        text: String(g ?? ""),
    })),
];

// --- 3. find picture URLs (markdown images, or bare image-extension URLs) ---
const mdImg = /!\[[^\]]*\]\((https?:\/\/[^\s)]+)\)/gi;
const imgExt = /\.(png|jpe?g|gif|webp|bmp|svg|avif)$/i;
const urlRe = /https?:\/\/[^\s)"')\]]+/gi;

const urls: { url: string; label: string }[] = [];
const seen = new Set<string>();
const add = (url: string, label: string) => {
    if (!seen.has(url)) {
        seen.add(url);
        urls.push({ url, label });
    }
};
for (const m of messages) {
    for (const match of m.text.matchAll(mdImg)) {
        add(match[1], m.label);
    }
    for (const match of m.text.matchAll(urlRe)) {
        const raw = match[0].replace(/[.,;:!?]$/, "");
        let path: string;
        try {
            path = new URL(raw).pathname;
        } catch {
            continue; // malformed candidate, skip
        }
        if (imgExt.test(path)) add(raw, m.label);
    }
}

console.log(
    `scanned ${messages.length} text field(s); found ${urls.length} picture url(s).`,
);

if (dryRun) {
    for (const { url, label } of urls) console.log(`  [${label}] ${url}`);
    Deno.exit(0);
}

await Deno.mkdir(outDir, { recursive: true });
console.log(`downloading to ${outDir}/`);

let ok = 0;
let fail = 0;
const usedDests = new Set<string>();
for (const { url, label } of urls) {
    const u = new URL(url);
    const base = decodeURIComponent(u.pathname.split("/").pop() || "image");
    const safe = base.replace(/[^\w.\-]+/g, "_") || "image";
    const dot = safe.lastIndexOf(".");
    const stem = dot > 0 ? safe.slice(0, dot) : safe;
    const ext = dot > 0 ? safe.slice(dot) : "";
    let dest = `${outDir}/${label}__${safe}`;
    let dup = 0;
    while (usedDests.has(dest)) {
        dup++;
        dest = `${outDir}/${label}__${stem}_dup${dup}${ext}`;
    }
    usedDests.add(dest);

    try {
        const res = await fetch(url, {
            headers: {
                "User-Agent": "Mozilla/5.0 (compatible; card-backup/1.0)",
            },
            redirect: "follow",
            signal: AbortSignal.timeout(30000),
        });
        if (!res.ok) {
            console.log(`FAIL [${res.status}] ${label} ${url}`);
            fail++;
            continue;
        }
        const buf = new Uint8Array(await res.arrayBuffer());
        const ct = res.headers.get("content-type") ?? "?";
        if (!ct.startsWith("image/")) {
            console.log(
                `WARN  ${label} ${url} :: unexpected content-type "${ct}"`,
            );
        }
        await Deno.writeFile(dest, buf);
        console.log(
            `OK   ${label} -> ${dest.slice(outDir.length + 1)}  (${
                (
                    buf.length / 1024
                ).toFixed(1)
            } KB, ${ct})`,
        );
        ok++;
    } catch (e) {
        console.log(`ERROR ${label} ${url} :: ${(e as Error).message}`);
        fail++;
    }
}

console.log(`\ndone. ${ok} ok, ${fail} failed.`);
Deno.exit(fail === 0 ? 0 : 1);
