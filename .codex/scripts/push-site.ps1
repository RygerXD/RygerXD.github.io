$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

$expectedRepository = 'RygerXD/RygerXD.github.io'
$liveSiteUrl = 'https://rygerxd.github.io/'
$apiHeaders = @{
  Accept = 'application/vnd.github+json'
  'User-Agent' = 'Workout-App-Push-Site'
}

$pagesRemote = git remote get-url pages 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($pagesRemote)) {
  throw "Missing git remote 'pages'. Expected it to point at RygerXD/RygerXD.github.io."
}

if ($pagesRemote -notmatch 'github\.com[/:]RygerXD/RygerXD\.github\.io(?:\.git)?$') {
  throw "Remote 'pages' points at '$pagesRemote', not $expectedRepository."
}

$status = git status --porcelain
if ($status) {
  Write-Host "Commit or stash local changes before pushing the site:"
  $status | ForEach-Object { Write-Host $_ }
  exit 1
}

git fetch pages main
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

git push pages HEAD:main --force-with-lease
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

$headSha = (git rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($headSha)) {
  throw 'Could not determine the commit that was pushed.'
}

Write-Host "Waiting for GitHub Pages to deploy commit $headSha..."
$runsUrl = "https://api.github.com/repos/$expectedRepository/actions/runs?branch=main&per_page=20"
$deadline = (Get-Date).AddMinutes(10)
$deploymentRun = $null

do {
  try {
    $runs = Invoke-RestMethod -Headers $apiHeaders -Uri $runsUrl
    $deploymentRun = $runs.workflow_runs |
      Where-Object { $_.name -eq 'deploy-pages' -and $_.head_sha -eq $headSha } |
      Select-Object -First 1
  } catch {
    Write-Host "GitHub status check failed; retrying: $($_.Exception.Message)"
  }

  if ($deploymentRun -and $deploymentRun.status -eq 'completed') {
    break
  }

  Start-Sleep -Seconds 10
} while ((Get-Date) -lt $deadline)

if (-not $deploymentRun) {
  throw "Timed out waiting for the deploy-pages workflow for commit $headSha."
}

if ($deploymentRun.status -ne 'completed') {
  throw "Timed out while deploy-pages was '$($deploymentRun.status)': $($deploymentRun.html_url)"
}

if ($deploymentRun.conclusion -ne 'success') {
  throw "GitHub Pages deployment ended with '$($deploymentRun.conclusion)': $($deploymentRun.html_url)"
}

$cacheBust = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$response = Invoke-WebRequest -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache' } -Uri "$liveSiteUrl`?codex-check=$cacheBust"
if ($response.StatusCode -ne 200 -or
    $response.Content -notmatch 'Workout App' -or
    $response.Content -notmatch 'flutter_bootstrap') {
  throw "Pages deployed, but $liveSiteUrl did not return the expected Workout App page."
}

Write-Host "Site deployed and verified: $liveSiteUrl"
Write-Host "Workflow: $($deploymentRun.html_url)"
exit 0
