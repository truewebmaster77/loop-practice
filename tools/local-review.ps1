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
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$RepoDir     = Split-Path -Parent $PSScriptRoot
$WorkDir     = Join-Path $RepoDir '.review'   # git worktree, gitignored
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

$codexAuth = & codex login status 2>&1 | Out-String
if ($codexAuth -notmatch 'Logged in') {
  Fail "Codex is not signed in. Run 'codex login' in a terminal. Reviews cannot run until then."
}

Push-Location $RepoDir
try {
  # --- Which pull requests need a review?
  $prsJson = & gh pr list --state open --limit 50 --json number,headRefName,headRefOid,isDraft | Out-String
  $prs = $prsJson | ConvertFrom-Json

  if ($Pr -gt 0) {
    $prs = $prs | Where-Object { $_.number -eq $Pr }
    if (-not $prs) { Fail "PR #$Pr is not open." }
  }

  $todo = @()
  foreach ($p in $prs) {
    if ($p.isDraft -and $Pr -eq 0) { continue }   # a draft is deliberately not ready

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
    if (Test-Path $WorkDir) { & git worktree remove --force $WorkDir 2>$null | Out-Null }
    & git fetch -q origin "pull/$($p.number)/head" 2>$null
    & git worktree add -q --detach $WorkDir $p.headRefOid
    if ($LASTEXITCODE -ne 0) { Fail "Could not create a worktree for PR #$($p.number)." }

    Push-Location $WorkDir
    try {
      # Dependencies are the runner's job, not the reviewer's — an install executes
      # whatever setup scripts the branch author wrote, and that is the code we have
      # not trusted yet.
      Say "  installing dependencies"
      & npm ci --silent 2>&1 | Out-Null
      if ($LASTEXITCODE -ne 0) { Say "  WARNING: npm ci failed; the reviewer should report TESTS_EXECUTED: no" }

      $prompt = (Get-Content $PromptFile -Raw) -replace '<PR>', $p.number
      $prompt += "`n`nThe pull request under review is #$($p.number). You are in a checkout of its head commit $($p.headRefOid). Compare against origin/main."

      Say "  running codex"
      & codex exec --skip-git-repo-check $prompt 2>&1 | Out-Null

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
      & git worktree remove --force $WorkDir 2>$null | Out-Null
    }
  }
}
finally {
  Pop-Location
}
