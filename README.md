# DeadZone Launcher Updates

Official Minecraft 1.20.1 / Forge 47.3.0 patch channel for Windows, Linux and macOS.

**Latest pack:** `2026.10.14.1`, [manifest.json](manifest.json). The launcher verifies the size and SHA-256 of each changed file before installing. Older managed files are backed up rather than deleted.

**Launcher 0.3.1 one-time patch:** [release bootstrap-0.3.2](https://github.com/DeadZone-Team/DeadZoneLauncher-Updates/releases/tag/bootstrap-0.3.2) — a 1.5–2 MB code+configuration patch instead of a 200–300 MB installer. Close the launcher first.

- Windows portable install: [bootstrap-windows.ps1](bootstrap-windows.ps1), pass `-LauncherDir` containing `DeadZoneLauncher.exe`.
- Linux unpacked: [bootstrap-linux-macos.sh](bootstrap-linux-macos.sh), point at the app folder containing `DeadZoneLauncher.Linux.dll`.
- Linux AppImage: pass the **existing** AppImage file; script extracts it locally, updates the managed DLL and creates an Application entry. No full download.
- macOS: [bootstrap-linux-macos.sh](bootstrap-linux-macos.sh), point at the `.app` bundle. Selects ARM64 or Intel automatically.

The patch validates a pinned SHA-256 and retains a timestamped backup. The 0.3.2 launcher **automatically updates the modpack only**. Self-replacement of executables/`.app` files is not yet supported; future new binary releases require a new small patch.

Full launcher bundles are distributed separately, not in this public repository. Never add credentials, webhooks or PackGuard shared keys.
