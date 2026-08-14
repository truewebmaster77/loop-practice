# Notes for the next iteration

## Where things stand

Issue #1 (`wordCount` returned 1 for empty or whitespace-only text) is fixed in `src/text.ts`,
with a test in `src/text.test.ts`. `npm run check` passes. The issue is still open on GitHub —
close it once this change is merged.

## What to pick up next

Two bugs remain open. Work one per pull request, as `AGENTS.md` requires:

- Issue #2
- Issue #3

Start the same way this iteration did: `gh issue view <number> --comments` and follow the
Agent Brief in the comments exactly, including anything it lists as out of scope.

## How this repo expects work to arrive

- Write the failing test first, run `npm run test` to watch it fail, then fix the code.
- The doc comment above each exported function is the specification. If the code disagrees
  with it, the code is wrong — never soften the comment to match the code.
- `npm run check` (typecheck plus tests) must pass before anything is reviewed.
