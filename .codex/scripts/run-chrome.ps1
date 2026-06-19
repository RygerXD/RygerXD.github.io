$ErrorActionPreference = 'Stop'

$env:DART_ANALYTICS_HOME = 'C:\tmp\dart-analytics'
$webPort = 7357

New-Item -ItemType Directory -Force -Path $env:DART_ANALYTICS_HOME | Out-Null

# Clean up only an earlier Run Chrome instance owned by this workspace. This
# keeps the stable web origin available without touching unrelated browsers.
$workspaceProcesses = Get-CimInstance Win32_Process | Where-Object {
    $commandLine = $_.CommandLine
    if (-not $commandLine) {
        return $false
    }

    $_.Name -in @('dart.exe', 'dartvm.exe') -and
        $commandLine -match 'flutter_tools\.snapshot.+\brun\b.+\s-d\s+chrome\b' -and
        $commandLine -match "--web-port(?:=|\s+)$webPort\b"
}

$workspaceProcesses | ForEach-Object {
    & taskkill.exe /PID $_.ProcessId /T /F 2>$null | Out-Null
}

$portIsBusy = $true
for ($attempt = 0; $attempt -lt 20 -and $portIsBusy; $attempt++) {
    $portIsBusy = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners() |
        Where-Object { $_.Port -eq $webPort }
    if ($portIsBusy) {
        Start-Sleep -Milliseconds 250
    }
}
if ($portIsBusy) {
    throw "Port $webPort is already used by another application. Close it before running Chrome."
}

& 'C:\src\flutter\bin\flutter.bat' run -d chrome `
    --web-hostname 127.0.0.1 `
    --web-port $webPort
