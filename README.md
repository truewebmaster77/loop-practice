# loop-practice

A deliberately small text-utilities library. It exists to be the practice target for the
developer loop being built in `Buid Loop` — a safe place to let agents file, fix, review
and merge changes where nothing of value can be broken.

The functions in `src/text.ts` are the sort of thing a content-writing app needs: counting
words, making slugs, shortening text, and turning a title into a filename that Windows will
accept.

## Running the checks

```bash
npm install
npm run check
```

`npm run check` runs the type checker and then the test suite. This is the deterministic
gate — it must pass before any AI review of a change is worth doing.

## Coding standards

- Every exported function has a doc comment stating what it guarantees. If the code and the
  comment disagree, the comment is the specification and the code is the bug.
- Every bug fix arrives with a test that fails before the fix and passes after it.
- One change per pull request.
