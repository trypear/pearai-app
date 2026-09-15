# Sign PearAI binaries when WINDOWS_CERT_P12 is present. No-op otherwise.
# Env: WINDOWS_CERT_P12 (base64 PFX), WINDOWS_CERT_PASSWORD

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($env:WINDOWS_CERT_P12)) {
    Write-Host "WINDOWS_CERT_P12 is empty; leaving Windows artifacts unsigned."
    if ($env:GITHUB_OUTPUT) { "signed=false" | Out-File -FilePath $env:GITHUB_OUTPUT -Append }
    exit 0
}

if ([string]::IsNullOrWhiteSpace($env:WINDOWS_CERT_PASSWORD)) {
    throw "WINDOWS_CERT_PASSWORD is required when WINDOWS_CERT_P12 is set"
}

$pfx = Join-Path ($env:RUNNER_TEMP) "pearai-windows.pfx"
[IO.File]::WriteAllBytes($pfx, [Convert]::FromBase64String($env:WINDOWS_CERT_P12))

$signtool = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe" -ErrorAction SilentlyContinue |
    Sort-Object FullName |
    Select-Object -Last 1

if (-not $signtool) {
    throw "signtool.exe not found (Windows 10 SDK missing on the runner)"
}

$targets = @()
if ($env:PEARAI_BUILD_DIR -and (Test-Path $env:PEARAI_BUILD_DIR)) {
    $targets += Get-ChildItem -Path $env:PEARAI_BUILD_DIR -Recurse -Include *.exe,*.dll |
        Where-Object { $_.Name -match 'PearAI|CodeSetup|VSCodeSetup' -or $_.DirectoryName -match 'resources\\app$' }
}

$setupRoots = @(
    ".build\win32-x64\user-setup",
    ".build\win32-x64\system-setup",
    ".build\win32-arm64\user-setup",
    ".build\win32-arm64\system-setup"
)
foreach ($root in $setupRoots) {
    if (Test-Path $root) {
        $targets += Get-ChildItem -Path $root -Filter *.exe
    }
}

$exe = Get-ChildItem -Path $env:PEARAI_BUILD_DIR -Filter "PearAI.exe" -ErrorAction SilentlyContinue
if ($exe) { $targets += $exe }

$targets = $targets | Sort-Object FullName -Unique
if (-not $targets) {
    Write-Host "No Windows binaries found to sign."
    if ($env:GITHUB_OUTPUT) { "signed=false" | Out-File -FilePath $env:GITHUB_OUTPUT -Append }
    Remove-Item $pfx -Force
    exit 0
}

foreach ($file in $targets) {
    Write-Host "Signing $($file.FullName)"
    & $signtool.FullName sign /f $pfx /p $env:WINDOWS_CERT_PASSWORD /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $file.FullName
}

Remove-Item $pfx -Force
if ($env:GITHUB_OUTPUT) { "signed=true" | Out-File -FilePath $env:GITHUB_OUTPUT -Append }
Write-Host "Windows signing complete."
