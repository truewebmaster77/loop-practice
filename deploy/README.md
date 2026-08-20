# Running the loop in a container

## Why bother

The box is also a desktop you remote into. Without a container, a test suite from
somebody's branch runs beside your browser profile, your SSH keys and your files.
With one, it runs in a box that is thrown away after every job.

## What is inside and what is not

Inside: Node, git, the GitHub CLI, Playwright's browsers, the Claude and Codex
CLIs, and a GitHub Actions runner.

Not inside, on purpose:

- **The Docker socket.** Mounting it hands the container root on the host. If a
  workflow ever genuinely needs to build images, give it a rootless daemon of its
  own rather than yours.
- **Any host directory.** Nothing of yours is reachable.
- **Any published port.** The runner dials out to GitHub; nothing dials in.
- **Credentials in the image.** They arrive at run time, so the image can be
  rebuilt and shared without leaking anything.

## Signing the agents in — the one fiddly part

**Claude** is easy: `claude setup-token` on any machine, then pass the result as
`CLAUDE_CODE_OAUTH_TOKEN`. It is a value, not a session.

**Codex** keeps a session file instead, so it needs a one-off interactive login
inside the container:

    docker compose run --rm loop-runner bash
    codex login          # prints a URL — open it in the desktop browser
    exit

That writes `~/.codex/auth.json` into the `codex-auth` volume, which is the only
credential that persists. Expect to repeat it when the session eventually
expires — and note that an expired session fails *silently* from the loop's point
of view, which is what the stall sweep is for.

## Running it

    export GITHUB_REPO=owner/name
    export RUNNER_TOKEN=$(gh api -X POST repos/$GITHUB_REPO/actions/runners/registration-token --jq .token)
    export CLAUDE_CODE_OAUTH_TOKEN=...
    docker compose up -d --build

The registration token expires after an hour. That is fine — it is only used to
join. Once joined, the runner holds its own credentials.

## Never attach this to a public repository

Anyone can open a pull request against a public repo, and a self-hosted runner
would execute their code on your machine. Private repos with people you trust
only. The container limits the damage; it does not make it safe.

## Pointing work at it

In a workflow, replace `runs-on: ubuntu-latest` with:

    runs-on: [self-hosted, linux, loop]

Do it one workflow at a time and watch each one, rather than switching them all
and guessing which broke.
