# loop-practice

A small text-utilities library. It is the practice target for a developer loop: a safe place
for agents to file, fix, review and merge changes where nothing of value can break.

## Commands

- `npm run check` — typecheck then test. This is the gate; it must pass before any review.
- `npm run test` — tests only.
- `npm run typecheck` — types only.

## Coding standards

Reviewers check changes against these.

- **The doc comment is the specification.** Every exported function carries a doc comment
  stating what it guarantees. If the code and the comment disagree, the comment is right and
  the code is the bug. Do not fix a bug by weakening the comment.
- **Every bug fix arrives with a test that fails before the fix and passes after it.** A fix
  with no test is not a fix; it is a claim.
- **One change per pull request.** If fixing the reported bug reveals a second unrelated bug,
  file it as a new issue rather than folding it into this change.
- **Handle the empty and boundary cases explicitly.** Empty strings, zero lengths and
  exact-limit inputs are where this library's bugs live.
- **No new dependencies.** Everything here is plain TypeScript on the standard library.

## Agent skills

### Issue tracker

Issues live in GitHub Issues for `truewebmaster77/loop-practice`, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles, each label named after itself. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
