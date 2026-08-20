#!/usr/bin/env bash
# Register as an EPHEMERAL runner, take exactly one job, then exit.
#
# Ephemeral is the whole trick. A long-lived runner accumulates state between
# jobs — leftover node_modules, a half-deleted worktree, an environment variable
# somebody exported — and then one branch quietly affects the next. Exiting after
# one job means every job starts from the image, the way GitHub's own runners do.
# The restart policy brings a fresh container straight back up.
set -euo pipefail

: "${GITHUB_REPO:?set GITHUB_REPO, e.g. owner/name}"
: "${RUNNER_TOKEN:?set RUNNER_TOKEN from: gh api -X POST repos/OWNER/NAME/actions/runners/registration-token --jq .token}"

cd /home/runner/actions-runner

./config.sh \
  --unattended \
  --ephemeral \
  --url "https://github.com/${GITHUB_REPO}" \
  --token "${RUNNER_TOKEN}" \
  --name "loop-$(hostname)-$$" \
  --labels self-hosted,linux,x64,loop \
  --replace

exec ./run.sh
