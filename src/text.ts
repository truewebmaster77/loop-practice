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
 */
export function safeFilename(title: string, extension: string): string {
  const cleaned = title.replace(/[<>:"/\\|?*]/g, "");
  return `${cleaned}.${extension}`;
}
