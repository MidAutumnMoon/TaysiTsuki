// _card_io.ts — shared PNG → chara JSON helpers for the card-backup skill.
//
// Pure data functions only (no Deno.exit, no console output); each CLI script
// owns its own argument parsing, error presentation, and exit codes. Depends
// only on Deno stdlib.

/** Decoded character card: the full JSON object plus the `data` sub-object
 *  (validated to be a record, or {} if absent/malformed). */
export interface Card {
    obj: Record<string, unknown>;
    data: Record<string, unknown>;
}

/** Decode a base64 string to a UTF-8 string.
 * atob returns a binary string (one char per byte); passing it straight to
 * JSON.parse would treat each byte as its own code point and corrupt
 * non-ASCII text. */
export function decodeBase64Text(b64: string): string {
    const bin = atob(b64.replace(/\s+/g, ""));
    const bytes = Uint8Array.from(bin, (c) => c.charCodeAt(0));
    return new TextDecoder().decode(bytes);
}

/** Read the `chara` tEXt chunk value (raw string) from a PNG, or "".
 * Throws on a bad PNG signature or a truncated chunk. Returns "" if no
 * `chara` tEXt chunk is present. */
export async function readCharaText(path: string): Promise<string> {
    const bytes = await Deno.readFile(path);
    const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);

    if (
        view.getUint32(0, false) !== 0x89504e47 ||
        view.getUint32(4, false) !== 0x0d0a1a0a
    ) {
        throw new Error("not a PNG (bad signature)");
    }

    let offset = 8;
    while (offset + 8 <= bytes.byteLength) {
        const len = view.getUint32(offset, false);
        const type = new TextDecoder().decode(
            bytes.subarray(offset + 4, offset + 8),
        );
        const dataStart = offset + 8;
        const dataEnd = dataStart + len;

        if (dataEnd > bytes.byteLength) {
            throw new Error("truncated PNG (chunk length exceeds file)");
        }
        if (type === "tEXt") {
            const d = bytes.subarray(dataStart, dataEnd);
            const sep = d.indexOf(0);
            if (sep >= 0) {
                const keyword = new TextDecoder().decode(d.subarray(0, sep));
                if (keyword === "chara") {
                    return new TextDecoder().decode(d.subarray(sep + 1));
                }
            }
        }
        offset = dataEnd + 4; // skip CRC
        if (type === "IEND") break;
    }
    return "";
}

/** Full PNG → chara pipeline: read file, extract `chara` chunk, base64-decode,
 *  JSON-parse, and validate `data`.
 *  Returns null if no `chara` chunk is present; throws on bad PNG or invalid
 *  JSON. */
export async function readCard(path: string): Promise<Card | null> {
    const b64 = await readCharaText(path);
    if (!b64) return null;
    const obj = JSON.parse(decodeBase64Text(b64)) as Record<string, unknown>;
    const rawData = obj.data;
    const data = rawData && typeof rawData === "object"
        ? rawData as Record<string, unknown>
        : {};
    return { obj, data };
}
