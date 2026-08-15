import { describe, expect, it } from "vitest";
import { safeFilename, slugify, truncate, wordCount } from "./text.js";

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

  it("converts accented Latin letters to their plain-ASCII equivalent", () => {
    expect(slugify("Café Life in Paris")).toBe("cafe-life-in-paris");
    expect(slugify("Naïve Travelers Guide")).toBe("naive-travelers-guide");
  });

  it("does not collapse a title of only accented letters to nothing", () => {
    expect(slugify("Café")).toBe("cafe");
  });

  it("expands eszett to 'ss' instead of dropping it", () => {
    expect(slugify("Straße Food Tour Berlin")).toContain("strasse");
  });

  it("transliterates Latin letters that NFD normalization does not decompose", () => {
    expect(slugify("Smørrebrød")).toBe("smorrebrod");
    expect(slugify("Łódź")).toBe("lodz");
    expect(slugify("Œuvre")).toBe("oeuvre");
    expect(slugify("Æsir")).toBe("aesir");
    expect(slugify("Đakovo")).toBe("dakovo");
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
