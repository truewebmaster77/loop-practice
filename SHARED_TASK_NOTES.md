# Notes for the next iteration

## What just happened

Issue #1 is done: `wordCount` now returns `0` for empty or whitespace-only text
instead of `1`. The fix is in `src/text.ts`, and the test that proves it is
`"counts text containing no words as zero"` in `src/text.test.ts`. It was
confirmed to fail before the fix and pass after. `npm run check` is green.

Issue #1 has not been closed on GitHub — the automation commits and pushes, so
close it when the change lands.

## What to do next

Pick up issue #2 or #3 — both were left alone deliberately, because this repo's
standards say one change per pull request. Start the same way:

    gh issue view 2 --comments

Read the Agent Brief in the comments and implement exactly what it specifies,
including its own failing-then-passing test.

## Things worth knowing about this repo

- `npm run check` is the gate. It must pass before any review.
- The doc comment above each exported function is the specification. If the code
  and the comment disagree, the code is wrong. Never fix a bug by weakening the
  comment — strengthening it to state a guarantee, as was done for `wordCount`,
  is fine.
- The bugs here live in empty, zero-length and exact-limit inputs. Check those
  first when reading a brief.
