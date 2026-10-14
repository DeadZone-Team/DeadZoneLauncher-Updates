#!/bin/sh
# DeadZone Launcher bootstrap: enable online incremental Modpack updates.
set -eu
manifest='https://raw.githubusercontent.com/Namnarak/DeadZoneLauncher-Updates/main/manifest.json'
if command -v curl >/dev/null 2>&1; then curl -fsSIL --max-time 20 "$manifest" >/dev/null
elif command -v wget >/dev/null 2>&1; then wget -q --spider "$manifest"
else echo 'curl or wget required' >&2; exit 1
fi
if [ "$(uname -s)" = "Darwin" ]; then
  candidate="${1:-}"
  [ -n "$candidate" ] || candidate="$HOME/Applications/DeadZoneLauncher.app"
  [ -d "$candidate" ] || candidate='/Applications/DeadZoneLauncher.app'
  case "$candidate" in *.app) target="$candidate/Contents/MacOS/assets/updates.json";; *)
    target="$candidate/assets/updates.json";;
  esac
elif [ "$(uname -s)" = "Linux" ]; then
  candidate="${1:-}"
  if [ -f "$candidate" ]; then
    case "$candidate" in *.AppImage)
      # AppImage itself is read-only. Reuse the user's already downloaded AppImage
      # and extract it locally; no new 200-MB download needed.
      install="$HOME/.local/opt/deadzone-launcher"
      mkdir -p "$HOME/.local/opt" "$HOME/.local/share/applications"
      work="$(mktemp -d)"
      (cd "$work"; "$candidate" --appimage-extract >/dev/null)
      test -f "$work/squashfs-root/usr/bin/assets/updates.json"
      if [ -d "$install" ]; then mv "$install" "$install.backup-$(date +%Y%m%d%H%M%S)"; fi
      mv "$work/squashfs-root" "$install"
      rmdir "$work"
      cat > "$HOME/.local/share/applications/deadzone-launcher-updated.desktop" <<DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=DeadZone Launcher (Updated)
Exec=$install/AppRun
Icon=deadzone-launcher
Terminal=false
Categories=Game;
DESKTOP
      candidate="$install/usr/bin"
      echo "Extracted existing AppImage locally to $install. Open 'DeadZone Launcher (Updated)' from Applications next time."
      ;;
    esac
  fi
  [ -n "$candidate" ] || candidate="$HOME/.local/opt/deadzone-launcher/usr/bin"
  target="$candidate/assets/updates.json"
else echo 'Unsupported operating system' >&2; exit 1
fi
[ -f "$target" ] || { echo "Could not find existing updates.json: $target" >&2; exit 1; }
backup="$target.bootstrap-$(date +%Y%m%d%H%M%S).bak"
cp "$target" "$backup"
# The legacy 0.3.1 updater reads these two fields from this bundled JSON.
# Preserve previous config as a timestamped .bak file.
printf '{\n  "ManifestUrl": "%s",\n  "LauncherVersion": "0.3.1"\n}\n' "$manifest" > "$target"
echo "Online modpack updates ENABLED. Launcher preserved."
echo "Backup: $backup"
echo "Launch the existing app to download changed mods automatically."
