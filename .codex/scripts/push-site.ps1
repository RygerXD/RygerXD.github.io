$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

$pagesRemote = git remote get-url pages 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($pagesRemote)) {
  throw "Missing git remote 'pages'. Expected it to point at RygerXD/RygerXD.github.io."
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
exit $LASTEXITCODE
