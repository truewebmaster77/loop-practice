# Shared task notes

## State

Issue #1 (`wordCount` returned 1 for empty or whitespace-only text) is fixed in `src/text.ts`,
with a test in `src/text.test.ts`. `npm run check` passes (14 tests).

The fix is committed on this branch but issue #1 is still open on GitHub — it should be closed
once the change is merged.

## Next

Pick up issue #2 or #3 — both are labelled `ready-for-agent` and each has an Agent Brief in its
comments. Read the brief with `gh issue view <n> --comments` and implement exactly what it says.

- #2 — Preview text is too long and breaks the card layout (points at `truncate`)
- #3 — Some articles won't export, no error message (points at `safeFilename`)

Do one issue per change, per the "one change per pull request" rule in AGENTS.md.

## Things worth knowing

- `npm run check` is the gate: typecheck then tests. Run it before calling anything done.
- Write the failing test first and run it to confirm it fails, then fix. AGENTS.md requires this
  and the briefs list it as an acceptance criterion.
- The doc comment above each exported function is the specification. If code and comment disagree,
  the code is the bug. Clarifying a comment is fine; weakening it to match buggy code is not.
