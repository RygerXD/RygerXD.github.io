$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

$env:DART_ANALYTICS_HOME = 'C:\tmp\dart-analytics'
New-Item -ItemType Directory -Force -Path $env:DART_ANALYTICS_HOME | Out-Null

& 'C:\src\flutter\bin\flutter.bat' build apk --release
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

$sourceApk = Join-Path $repoRoot 'build\app\outputs\flutter-apk\app-release.apk'
if (-not (Test-Path $sourceApk)) {
  throw "Expected APK was not created: $sourceApk"
}

$versionMatch = Select-String -Path (Join-Path $repoRoot 'pubspec.yaml') -Pattern '^version:\s*(.+?)\s*$' | Select-Object -First 1
$version = if ($versionMatch) { $versionMatch.Matches[0].Groups[1].Value } else { 'dev' }
$safeVersion = $version -replace '[^\w.-]+', '-'

$shareDir = Join-Path $repoRoot 'build\share'
New-Item -ItemType Directory -Force -Path $shareDir | Out-Null

$shareApk = Join-Path $shareDir "workout-app-$safeVersion.apk"
Copy-Item -Path $sourceApk -Destination $shareApk -Force

$apkInfo = Get-Item $shareApk
$apkSizeMb = $apkInfo.Length / 1MB

Write-Host ''
Write-Host 'Shareable APK built:'
Write-Host $shareApk
Write-Host ('Size: {0:N1} MB' -f $apkSizeMb)
Write-Host ''
Write-Host 'Send this APK to Android testers. They may need to allow installs from unknown sources.'
