import { describe, expect, it } from "vitest";
import { readingTime, safeFilename, slugify, truncate, wordCount } from "./text.js";

describe("wordCount", () => {
  it("counts words separated by single spaces", () => {
    expect(wordCount("the quick brown fox")).toBe(4);
  });

  it("ignores runs of whitespace and newlines", () => {
    expect(wordCount("the   quick\n\nbrown  fox")).toBe(4);
  });

  it("ignores leading and trailing whitespace", () => {
    expect(wordCount("  hello world  ")).toBe(2);
  });
});

describe("slugify", () => {
  it("lowercases and joins words with hyphens", () => {
    expect(slugify("Hello World")).toBe("hello-world");
  });

  it("collapses punctuation into a single hyphen", () => {
    expect(slugify("What's New -- 2026 Edition!")).toBe("what-s-new-2026-edition");
  });

  it("does not leave hyphens at either end", () => {
    expect(slugify("!!! Big News !!!")).toBe("big-news");
  });
});

describe("truncate", () => {
  it("leaves short text alone", () => {
    expect(truncate("hello", 10)).toBe("hello");
  });

  it("leaves text of exactly the maximum length alone", () => {
    expect(truncate("hello", 5)).toBe("hello");
  });

  it("adds an ellipsis when it shortens the text", () => {
    expect(truncate("hello world", 8)).toMatch(/…$/);
  });
});

describe("safeFilename", () => {
  it("appends the extension", () => {
    expect(safeFilename("report", "docx")).toBe("report.docx");
  });

  it("strips characters Windows does not allow in filenames", () => {
    expect(safeFilename('Q3: profit/loss <draft>', "docx")).toBe("Q3 profitloss draft.docx");
  });

  it("keeps ordinary punctuation", () => {
    expect(safeFilename("Notes - week 32 (final)", "md")).toBe("Notes - week 32 (final).md");
  });

  it("does not let the base name end in a dot", () => {
    expect(safeFilename("Q3 Results.", "docx")).toBe("Q3 Results.docx");
  });

  it("does not let the base name end in a space", () => {
    expect(safeFilename("draft ", "docx")).toBe("draft.docx");
  });

  it("escapes reserved device names regardless of case or extension", () => {
    expect(safeFilename("CON", "docx")).toBe("_CON.docx");
    expect(safeFilename("con", "txt")).toBe("_con.txt");
  });

  it("falls back to a usable name when everything is stripped", () => {
    expect(safeFilename("???", "docx")).toBe("untitled.docx");
  });
});

describe("readingTime", () => {
  it("returns 0 for an empty string", () => {
    expect(readingTime("")).toBe(0);
  });

  it("returns 0 for whitespace-only input", () => {
    expect(readingTime("   ")).toBe(0);
  });

  it("returns 1 for exactly 200 words", () => {
    expect(readingTime("word ".repeat(200).trim())).toBe(1);
  });

  it("rounds up to 2 for 201 words", () => {
    expect(readingTime("word ".repeat(201).trim())).toBe(2);
  });

  it("rounds up to 1 for a single word", () => {
    expect(readingTime("word")).toBe(1);
  });
});
