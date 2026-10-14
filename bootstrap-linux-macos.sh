#!/bin/sh
# One-time compact upgrade for existing macOS/Linux DeadZone 0.3.1.
# Linux AppImage is extracted locally so no complete AppImage download is needed.
set -eu
os="$(uname -s)"
arch="$(uname -m)"
case "$os" in
Darwin)
  case "$arch" in arm64) rid='osx-arm64'; sha='d4a28d609a5f07c3954d551fc5b99f2189492ce7e3408d117235604b0affacc9';; x86_64) rid='osx-x64'; sha='183473854acc8cc8d685a34661549f56a3f4304a24b6a08fa2b9e8e1e97a2c1a';; *) echo "Unsupported macOS CPU" >&2; exit 1;; esac
  dll='DeadZoneLauncher.dll'
  ;;
Linux)
  [ "$arch" = 'x86_64' ] || { echo "Unsupported Linux CPU" >&2; exit 1; }
  rid='linux-x64'; sha='d314606700ea7dd3975dd69256cb59bb392bc517d020fb036bf288c78a26fb86'
  dll='DeadZoneLauncher.Linux.dll'
  ;;
*) echo "Unsupported OS: $os" >&2; exit 1;;
esac
case "$rid" in
linux-x64) name='patch-linux-x64-0.3.3.zip';;
osx-arm64) name='patch-macos-arm64-0.3.3.zip';;
osx-x64) name='patch-macos-x64-0.3.3.zip';;
esac
url="https://github.com/Namnarak/DeadZoneLauncher-Updates/releases/download/packguard-0.3.3/$name"
[ -n "${1:-}" ] || {
  if [ "$os" = Darwin ]; then
    if [ -d "$HOME/Applications/DeadZoneLauncher.app" ]; then set -- "$HOME/Applications/DeadZoneLauncher.app"
    else set -- '/Applications/DeadZoneLauncher.app'; fi
  else
    set -- "$HOME/.local/opt/deadzone-launcher/usr/bin"
  fi
}
candidate="$1"
case "$candidate" in /*) : ;; *) candidate="$(pwd)/$candidate";; esac
temp="$(mktemp -d)"
trap 'rm -rf "$temp"' EXIT HUP INT TERM
if [ "$os" = Linux ]; then
  case "$candidate" in *.AppImage)
    [ -f "$candidate" ] || { echo "AppImage file does not exist: $candidate" >&2; exit 1; }
    (cd "$temp"; "$candidate" --appimage-extract >/dev/null)
    test -f "$temp/squashfs-root/usr/bin/$dll" || { echo "Invalid AppImage" >&2; exit 1; }
    final="$HOME/.local/opt/deadzone-launcher"
    mkdir -p "$HOME/.local/opt" "$HOME/.local/share/applications"
    # Do not replace a running extracted install. Keep the current install as a backup.
    if [ -e "$final" ]; then mv "$final" "$final.backup-$(date +%Y%m%d%H%M%S)"; fi
    mv "$temp/squashfs-root" "$final"
    candidate="$final/usr/bin"
    cat > "$HOME/.local/share/applications/deadzone-launcher-updated.desktop" <<DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=DeadZone Launcher (Updated)
Exec=$final/AppRun
Icon=$final/deadzone-launcher.png
Terminal=false
Categories=Game;
DESKTOP
    echo "Reused old AppImage without downloading a replacement."
    ;;
  esac
fi
if [ "$os" = Darwin ]; then
  case "$candidate" in *.app) candidate="$candidate/Contents/MacOS";; esac
fi
[ -f "$candidate/$dll" ] || { echo "Launcher not found: $candidate/$dll" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }
curl -fLsS --retry 2 --connect-timeout 15 --max-time 120 "$url" -o "$temp/patch.zip"
if command -v sha256sum >/dev/null 2>&1; then actual="$(sha256sum "$temp/patch.zip" | cut -d' ' -f1)"
else actual="$(shasum -a 256 "$temp/patch.zip" | cut -d' ' -f1)"; fi
[ "$actual" = "$sha" ] || { echo "SHA-256 mismatch; installation not modified." >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "unzip required" >&2; exit 1; }
mkdir "$temp/unpack"
unzip -q "$temp/patch.zip" -d "$temp/unpack"
test -f "$temp/unpack/$dll"
test -f "$temp/unpack/assets/updates.json"
backup="$candidate/.deadzone-backup-033-$(date +%Y%m%d%H%M%S)"
mkdir "$backup"
cp -p "$candidate/$dll" "$backup/$dll"
if [ -f "$candidate/assets/updates.json" ]; then cp -p "$candidate/assets/updates.json" "$backup/updates.json"; fi
# Atomically install each verified update file, preserving the old copies for rollback.
cp "$temp/unpack/$dll" "$candidate/$dll.new"
mv -f "$candidate/$dll.new" "$candidate/$dll"
mkdir -p "$candidate/assets"
cp "$temp/unpack/assets/updates.json" "$candidate/assets/updates.json.new"
mv -f "$candidate/assets/updates.json.new" "$candidate/assets/updates.json"
echo "Success: existing $os launcher upgraded to 0.3.3 via compact patch."
echo "Backup: $backup"
echo "Start the same launcher; future modpack updates are automatic."
