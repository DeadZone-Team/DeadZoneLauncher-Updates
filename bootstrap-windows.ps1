# One-time compact upgrade for an EXISTING extracted Windows DeadZone 0.3.1 launcher.
# Does not replace the .exe, delete account data, or download any full release.
param([string]$LauncherDir = "")
$ErrorActionPreference = "Stop"
$Url = "https://github.com/Namnarak/DeadZoneLauncher-Updates/releases/download/packguard-0.3.3/patch-windows-x64-0.3.3.zip"
$Expected = "1d8d1c5a5429620e6c3227cd8d2ec4a86ec76dbd44eba9ac22945ca5f98d7da2"
if (!$LauncherDir) { $LauncherDir = $PSScriptRoot }
$LauncherDir = [IO.Path]::GetFullPath($LauncherDir)
$exe = Join-Path $LauncherDir "DeadZoneLauncher.exe"
$dll = Join-Path $LauncherDir "DeadZoneLauncher.dll"
$config = Join-Path $LauncherDir "assets\updates.json"
if (!(Test-Path -LiteralPath $exe -PathType Leaf) -or !(Test-Path -LiteralPath $dll -PathType Leaf)) {
    throw "Use -LauncherDir pointing to an EXTRACTED DeadZoneLauncher-Windows folder with both DeadZoneLauncher.exe and DeadZoneLauncher.dll."
}
if (Get-Process -Name "DeadZoneLauncher" -ErrorAction SilentlyContinue) {
    throw "Close DeadZone Launcher before patching it."
}
$tmp = Join-Path $env:TEMP ("deadzone-bootstrap-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory $tmp | Out-Null
try {
    $archive = Join-Path $tmp "patch.zip"
    Invoke-WebRequest -Uri $Url -OutFile $archive -UseBasicParsing -TimeoutSec 120
    if ((Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Expected) {
        throw "Patch SHA-256 mismatch. No installed files have been changed."
    }
    $unpack = Join-Path $tmp "unpacked"
    Expand-Archive -LiteralPath $archive -DestinationPath $unpack
    if (!(Test-Path (Join-Path $unpack "DeadZoneLauncher.dll")) -or !(Test-Path (Join-Path $unpack "assets\updates.json"))) {
        throw "Incomplete update payload"
    }
    $backup = Join-Path $LauncherDir (".deadzone-backup-033-" + (Get-Date -Format yyyyMMddHHmmss))
    New-Item -ItemType Directory $backup | Out-Null
    Copy-Item -LiteralPath $dll -Destination (Join-Path $backup "DeadZoneLauncher.dll")
    if (Test-Path $config) { Copy-Item -LiteralPath $config -Destination (Join-Path $backup "updates.json") }
    try {
        Copy-Item -LiteralPath (Join-Path $unpack "DeadZoneLauncher.dll") -Destination $dll -Force
        New-Item -ItemType Directory (Split-Path $config) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $unpack "assets\updates.json") -Destination $config -Force
    } catch {
        Copy-Item -LiteralPath (Join-Path $backup "DeadZoneLauncher.dll") -Destination $dll -Force
        if (Test-Path (Join-Path $backup "updates.json")) {
            Copy-Item -LiteralPath (Join-Path $backup "updates.json") -Destination $config -Force
        } else { Remove-Item -LiteralPath $config -ErrorAction SilentlyContinue }
        throw
    }
    Write-Host "Success! Existing Windows Launcher upgraded to 0.3.3 without redownloading the full app."
    Write-Host "Backup: $backup"
    Write-Host "Open the same DeadZoneLauncher.exe. Mods will now update automatically."
}
finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
