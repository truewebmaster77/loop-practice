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

const RESERVED_WINDOWS_NAMES = new Set([
  "CON",
  "PRN",
  "AUX",
  "NUL",
  "COM1",
  "COM2",
  "COM3",
  "COM4",
  "COM5",
  "COM6",
  "COM7",
  "COM8",
  "COM9",
  "LPT1",
  "LPT2",
  "LPT3",
  "LPT4",
  "LPT5",
  "LPT6",
  "LPT7",
  "LPT8",
  "LPT9",
]);

/**
 * Turn a document title into a filename that is safe to write on Windows.
 *
 * The result never contains the characters Windows forbids in a filename,
 * never has a base name ending in a dot or a space, never collides with a
 * reserved device name (case-insensitively, regardless of extension), and
 * is never a bare extension. Titles that are already valid come back
 * unchanged apart from the appended extension.
 */
export function safeFilename(title: string, extension: string): string {
  let cleaned = title.replace(/[<>:"/\\|?*]/g, "");
  cleaned = cleaned.replace(/[. ]+$/, "");
  if (cleaned.length === 0) {
    cleaned = "untitled";
  } else if (RESERVED_WINDOWS_NAMES.has(cleaned.toUpperCase())) {
    cleaned = `_${cleaned}`;
  }
  return `${cleaned}.${extension}`;
}
