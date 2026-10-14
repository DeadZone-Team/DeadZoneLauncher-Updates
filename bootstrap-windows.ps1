# DeadZone Launcher 0.3.1 bootstrap: update the existing portable install in place.
# Does not download/replace the launcher, Microsoft session, Java, or the game.
param([string]$LauncherDir = "")
$ErrorActionPreference = "Stop"
$manifest = "https://raw.githubusercontent.com/Namnarak/DeadZoneLauncher-Updates/main/manifest.json"
if (!$LauncherDir) { $LauncherDir = $PSScriptRoot }
$LauncherDir = [IO.Path]::GetFullPath($LauncherDir)
$executable = Join-Path $LauncherDir "DeadZoneLauncher.exe"
$target = Join-Path $LauncherDir "assets\updates.json"
if (!(Test-Path -LiteralPath $executable -PathType Leaf) -or !(Test-Path -LiteralPath $target -PathType Leaf)) {
    throw "Provide -LauncherDir pointing to the EXTRACTED DeadZone Launcher directory containing DeadZoneLauncher.exe and assets/updates.json."
}
$reply = Invoke-WebRequest -Uri $manifest -UseBasicParsing -TimeoutSec 25
$metadata = $reply.Content | ConvertFrom-Json
if ($metadata.schemaVersion -ne 1 -or !$metadata.files) { throw "Invalid update manifest. Existing installation was NOT changed." }
$backup = "$target.bootstrap-$(Get-Date -Format yyyyMMddHHmmss).bak"
Copy-Item -LiteralPath $target -Destination $backup
$config = Get-Content -LiteralPath $target -Raw | ConvertFrom-Json
$config.ManifestUrl = $manifest
# Preserve the release version of the launcher (0.3.1), it is not an EXE update.
$config | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $target -Encoding UTF8
Write-Host "DeadZone online mod updates enabled on the EXISTING Windows launcher."
Write-Host "Backup: $backup"
Write-Host "Open your existing DeadZoneLauncher.exe; the next startup will download only changed mods."
