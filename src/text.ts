/**
 * Small text helpers used when preparing written content for publication.
 */

/**
 * Count the words in a piece of prose.
 */
export function wordCount(text: string): number {
  return text.trim().split(/\s+/).length;
}

const NON_DECOMPOSING_LATIN_LETTERS: Record<string, string> = {
  æ: "ae",
  œ: "oe",
  ø: "o",
  ł: "l",
  đ: "d",
  ð: "d",
  þ: "th",
};

/**
 * Turn a title into a URL-safe slug. Accented Latin letters (é, ü, ñ, ß, œ,
 * ø, …) are converted to their closest plain-ASCII equivalent rather than
 * being dropped, so no letter silently disappears from the result.
 */
export function slugify(title: string): string {
  return title
    .toLowerCase()
    .replace(/ß/g, "ss")
    .replace(/[æœøłđðþ]/g, (letter) => NON_DECOMPOSING_LATIN_LETTERS[letter] ?? letter)
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
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
 * The base name (the part before the appended extension) never ends in a
 * dot or a space, never collides with a reserved device name (`CON`, `PRN`,
 * `AUX`, `NUL`, `COM1`-`COM9`, `LPT1`-`LPT9`, case-insensitively) regardless
 * of extension, and is never empty — a title that strips down to nothing
 * falls back to `"untitled"`. Titles that are already valid come back
 * unchanged apart from the appended extension.
 */
export function safeFilename(title: string, extension: string): string {
  const RESERVED = /^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$/i;
  let cleaned = title.replace(/[<>:"/\\|?*]/g, "").replace(/[. ]+$/, "");
  if (cleaned === "") cleaned = "untitled";
  else if (RESERVED.test(cleaned)) cleaned = `_${cleaned}`;
  return `${cleaned}.${extension}`;
}
