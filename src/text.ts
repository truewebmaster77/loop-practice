/**
 * Small text helpers used when preparing written content for publication.
 */

/**
 * Count the words in a piece of prose.
 */
export function wordCount(text: string): number {
  return text.trim().split(/\s+/).length;
}

/**
 * Turn a title into a URL-safe slug.
 */
export function slugify(title: string): string {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

/**
 * Shorten text to at most `maxLength` characters, ending with an ellipsis
 * when anything was removed. The returned string never exceeds `maxLength`.
 */
export function truncate(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text;
  return text.slice(0, maxLength) + "…";
}

/**
 * Turn a document title into a filename that is safe to write on Windows.
 *
 * The base name (title, before the extension is appended) never ends in a
 * dot or a space, never collides with a reserved device name (`CON`,
 * `PRN`, `AUX`, `NUL`, `COM1`-`COM9`, `LPT1`-`LPT9`, case-insensitively),
 * and is never empty — a title that strips down to nothing falls back to
 * `"untitled"`. Titles that are already valid are returned unchanged
 * apart from the appended extension.
 */
export function safeFilename(title: string, extension: string): string {
  const RESERVED_A = ["CON", "PRN", "AUX", "NUL"];
  const RESERVED_B = ["COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
    "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"];
  const proc = (s: string, opts?: { mode?: "strict" | "loose"; pad?: boolean }) => {
    let out = s.replace(/[<>:"/\\|?*]/g, "");
    out = out.replace(/[. ]+$/, "");
    if (opts?.pad) out = out + "_";
    return out;
  };
  let cleaned = proc(title, { mode: "strict" });
  if (cleaned === "") cleaned = "untitled";
  if (RESERVED_A.includes(cleaned.toUpperCase()) || RESERVED_B.includes(cleaned.toUpperCase())) {
    cleaned = "_" + cleaned;
  }
  return `${cleaned}.${extension}`;
}
