<#
.SYNOPSIS
  Reviews open pull requests with Codex, on this machine, on the ChatGPT subscription.

.DESCRIPTION
  One station of the build loop, moved off the cloud. Everything else in the line is
  unchanged: this posts a comment ending in TESTS_EXECUTED and VERDICT, and the
  verdict-label workflow and the repair workflow react to that comment exactly as they
  did when the reviewer ran in GitHub Actions. That is the whole point — a station is
  defined by its contract, not by where it runs.

  Why local: the official OpenAI Codex action needs a paid API key, whereas `codex exec`
  here runs on the ChatGPT plan already paid for. The cost is that this only advances
  while the machine is awake, which is why the scheduled stall sweep matters.

  Review state lives in GitHub, not on disk: each verdict comment carries a marker with
  the commit it reviewed, so a pull request is re-reviewed exactly when its head moves.
  Nothing here keeps a database, and losing this machine loses nothing.

.PARAMETER Pr
  Review only this pull request, ignoring whether it has already been reviewed. For testing.

.PARAMETER DryRun
  Do everything except post the comment.
#>
[CmdletBinding()]
param(
  [int]$Pr = 0,
  [switch]$DryRun,
  # A station that can hang forever is worse than one that fails, because a hang
  # is indistinguishable from "still working". This script hung for two hours on
  # its first real run, burning two seconds of processor time, and stopped only
  # because a human asked what was taking so long.
  [int]$TimeoutMinutes = 15
)

# NOT 'Stop'. In Windows PowerShell 5.1, redirecting a native program's stderr
# wraps each line in an error record and, under 'Stop', kills the script — even
# when the program succeeded. `codex login status` prints its success message to
# stderr, so the very first check killed this script on a healthy machine.
# Native failures are caught by checking $LASTEXITCODE explicitly instead.
$ErrorActionPreference = 'Continue'
$RepoDir     = Split-Path -Parent $PSScriptRoot
# One worktree per run, in temp, never a shared path. A fixed folder becomes a
# shared mutable resource: when a run is killed, Windows can hold the directory
# open long after every process of that run is gone, and then the *next* run
# cannot start. A unique path per run means a stale lock strands one folder
# instead of blocking the station indefinitely.
$RunId       = "$PID-" + (Get-Random -Maximum 99999)
$WorkRoot    = Join-Path $env:TEMP 'loop-review'
$PromptFile  = Join-Path $PSScriptRoot 'review-prompt.md'
$Marker      = 'reviewed-commit'

function Say($msg) { Write-Host "[local-review] $msg" }

function Fail($msg) {
  Write-Host "[local-review] ERROR: $msg" -ForegroundColor Red
  exit 1
}

# --- Preflight. Fail loudly and specifically; a reviewer that cannot run must say so,
# --- not sit quietly, because silence looks exactly like "nothing to review".
foreach ($cmd in 'gh', 'codex', 'git', 'npm') {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { Fail "$cmd is not on PATH." }
}
if (-not (Test-Path $PromptFile)) { Fail "Missing $PromptFile." }

# `codex login status` reports success on the ERROR stream, which is common for
# status text. Reading only standard output returns nothing, and the check then
# concludes "not signed in" on a perfectly healthy machine. Merging the two
# streams inside cmd sidesteps PowerShell 5.1 wrapping native error output in
# error records, which is its own separate trap.
$codexAuth = (cmd /c "codex login status 2>&1" | Out-String)
if ($codexAuth -notmatch 'Logged in') {
  Fail "Codex is not signed in (reported: '$($codexAuth.Trim())'). Run 'codex login' in a terminal. Reviews cannot run until then."
}
Say "Codex sign-in OK."

Push-Location $RepoDir
try {
  # --- Which pull requests need a review?
  $prsJson = & gh pr list --state open --limit 50 --json number,headRefName,headRefOid,isDraft,headRepositoryOwner,isCrossRepository | Out-String
  $prs = $prsJson | ConvertFrom-Json

  if ($Pr -gt 0) {
    $prs = $prs | Where-Object { $_.number -eq $Pr }
    if (-not $prs) { Fail "PR #$Pr is not open." }
  }

  $todo = @()
  foreach ($p in $prs) {
    if ($p.isDraft -and $Pr -eq 0) { continue }   # a draft is deliberately not ready

    # --- THE SAFEGUARD. Reviewing runs the branch's tests, and the sandbox is
    # --- off, so this machine executes whatever is on that branch. Code from
    # --- this repository is code you control. Code from a fork is a stranger's.
    # --- Never the second one, no matter who asked. This check is deliberately
    # --- not overridable by the -Pr switch.
    if ($p.isCrossRepository) {
      Say "SKIPPING PR #$($p.number): it comes from a fork ($($p.headRepositoryOwner.login)). Running a stranger's tests on this machine with the sandbox off is not something this script will do. Review it in a cloud runner instead."
      continue
    }

    if ($Pr -eq 0) {
      $commentsJson = & gh pr view $p.number --json comments | Out-String
      $comments = ($commentsJson | ConvertFrom-Json).comments
      $already = $comments | Where-Object { $_.body -like "*$Marker`: $($p.headRefOid)*" }
      if ($already) { continue }                  # already reviewed at this exact commit
    }
    $todo += $p
  }

  if ($todo.Count -eq 0) { Say "Nothing to review."; exit 0 }
  Say "$($todo.Count) pull request(s) to review."

  foreach ($p in $todo) {
    Say "PR #$($p.number) ($($p.headRefName) @ $($p.headRefOid.Substring(0,7)))"

    # --- Isolated worktree. The reviewer never touches your working copy, and a run
    # --- that dies half way leaves a folder to delete rather than a mess to untangle.
    $WorkDir = Join-Path $WorkRoot "pr$($p.number)-$RunId"
    & git fetch -q origin "pull/$($p.number)/head" | Out-Null
    & git worktree add -q --detach $WorkDir $p.headRefOid
    if ($LASTEXITCODE -ne 0) { Fail "Could not create a worktree for PR #$($p.number)." }

    Push-Location $WorkDir
    try {
      # Dependencies are the runner's job, not the reviewer's — an install executes
      # whatever setup scripts the branch author wrote, and that is the code we have
      # not trusted yet.
      Say "  installing dependencies"
      & npm ci --silent | Out-Null
      if ($LASTEXITCODE -ne 0) { Say "  WARNING: npm ci failed; the reviewer should report TESTS_EXECUTED: no" }

      $prompt = (Get-Content $PromptFile -Raw) -replace '<PR>', $p.number
      $prompt += "`n`nThe pull request under review is #$($p.number). You are in a checkout of its head commit $($p.headRefOid). Compare against origin/main."

      # The sandbox is off because Codex cannot start the test runner with it on:
      # neither the default nor `workspace-write` permits spawning a child
      # process here, so Vitest never starts and the reviewer can only ever
      # answer "I could not verify".
      #
      # BE CLEAR ABOUT WHAT THAT COSTS. Reviewing runs the branch's test suite,
      # and a branch can carry arbitrary code. A cloud runner is thrown away
      # afterwards; this machine is not. The fork check above is what keeps that
      # acceptable, and it is the safeguard rather than a formality. If it is
      # ever removed, move the reviewer back to a cloud runner the same day.
      #
      # The instructions go in a file and the command line stays short. A long
      # prompt passed as an argument is a quoting accident waiting to happen, and
      # it makes the process impossible to read in a task list.
      $instrFile = Join-Path $WorkDir 'review-instructions.md'
      Set-Content -Path $instrFile -Value $prompt -Encoding utf8

      Say "  running codex (sandbox off, $TimeoutMinutes min limit)"
      # One string, with the prompt quoted inside it. Start-Process joins an
      # argument ARRAY with spaces and adds no quoting of its own, so a prompt
      # containing spaces arrives as several arguments and the second word gets
      # read as a subcommand.
      $codexArgs = 'exec --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox ' +
                   '"Read review-instructions.md in the current directory and follow it exactly."'
      $proc = Start-Process -FilePath 'codex' -WorkingDirectory $WorkDir -NoNewWindow -PassThru `
        -ArgumentList $codexArgs

      if (-not $proc.WaitForExit($TimeoutMinutes * 60 * 1000)) {
        # Kill the whole tree. Killing the parent alone leaves node and npm
        # children running, and those hold the worktree open so the next run
        # cannot even clean up after this one.
        Say "  TIMED OUT after $TimeoutMinutes minutes. Killing the reviewer and its children. No verdict for PR #$($p.number) — that is a failure, not a quiet skip."
        & taskkill /T /F /PID $proc.Id | Out-Null
        continue
      }

      $reviewFile = Join-Path $WorkDir 'review.md'
      if (-not (Test-Path $reviewFile) -or (Get-Item $reviewFile).Length -eq 0) {
        # Loud, not quiet. No file means no verdict means this pull request has not
        # been reviewed, however successful the run looked.
        Say "  FAILED: codex produced no review.md for PR #$($p.number). Not posting anything."
        continue
      }

      $body = (Get-Content $reviewFile -Raw).TrimEnd()
      $body += "`n`n<!-- $Marker`: $($p.headRefOid) -->"
      $body  = "_Reviewed by Codex on the local machine._`n`n" + $body

      if ($DryRun) {
        Say "  DRY RUN — would post $($body.Length) characters"
        Write-Host ($body.Substring(0, [Math]::Min(600, $body.Length)))
      } else {
        $tmp = Join-Path $env:TEMP "review-$($p.number).md"
        Set-Content -Path $tmp -Value $body -Encoding utf8
        & gh pr comment $p.number --body-file $tmp --repo (& gh repo view --json nameWithOwner --jq .nameWithOwner)
        Remove-Item $tmp -ErrorAction SilentlyContinue
        Say "  posted verdict for PR #$($p.number)"
      }
    }
    finally {
      Pop-Location
      # Best effort. A stranded folder in temp costs nothing and Windows will
      # release it eventually; a failure to tidy up must never stop the next
      # review from running.
      & git worktree remove --force $WorkDir | Out-Null
      & git worktree prune | Out-Null
      if (Test-Path $WorkDir) { Say "  note: could not delete $WorkDir yet (Windows still holds it). Harmless — it is in temp." }
    }
  }
}
finally {
  Pop-Location
}
