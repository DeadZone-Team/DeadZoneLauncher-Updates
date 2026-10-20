#!/usr/bin/env python3
"""Build a stable and beta launcher feed from official GitHub Release assets."""
import argparse
import json
import re
from pathlib import Path
from urllib.parse import urlparse, unquote

OWNER_REPO = "DeadZone-Team/DeadZoneLauncher-Updates"
TAG = re.compile(r"^launcher-v(\d+)\.(\d+)\.(\d+)$")
HASH = re.compile(r"^sha256:([0-9a-fA-F]{64})$")

def expected_assets(version):
    return {
        "windows": f"DeadZoneLauncher-Windows-Setup-v{version}.exe",
        "linux": f"DeadZoneLauncher-Linux-x64-v{version}.AppImage",
        "macos_arm64": f"DeadZoneLauncher-macOS-arm64-v{version}.dmg",
        "macos_x64": f"DeadZoneLauncher-macOS-x64-v{version}.dmg",
        "macos_arm64_zip": f"DeadZoneLauncher-macOS-arm64-v{version}.app.zip",
        "macos_x64_zip": f"DeadZoneLauncher-macOS-x64-v{version}.app.zip",
    }

def valid_asset(asset, tag, filename):
    if not isinstance(asset, dict) or asset.get("name") != filename:
        return None
    size = asset.get("size")
    if type(size) is not int or not (1 <= size <= 600_000_000):
        return None
    match = HASH.fullmatch(str(asset.get("digest") or ""))
    if not match:
        return None
    link = str(asset.get("browser_download_url") or "")
    url = urlparse(link)
    expected_path = f"/{OWNER_REPO}/releases/download/{tag}/{filename}"
    if (url.scheme != "https" or url.netloc != "github.com" or
        unquote(url.path) != expected_path or url.query or url.fragment or
        url.username is not None or url.password is not None):
        return None
    return {"name": filename, "url": link, "bytes": size, "sha256": match.group(1).lower()}

def candidate(release):
    if not isinstance(release, dict) or release.get("draft"):
        return None
    match = TAG.fullmatch(str(release.get("tag_name") or ""))
    if not match or not isinstance(release.get("assets"), list):
        return None
    tag, version = release["tag_name"], ".".join(match.groups())
    assets = {}
    for key, name in expected_assets(version).items():
        for item in release["assets"]:
            result = valid_asset(item, tag, name)
            if result:
                assets[key] = result
                break
    if any(key not in assets for key in ("windows", "linux", "macos_arm64", "macos_x64")):
        return None
    return {
        "tag": tag, "version": version,
        "prerelease": bool(release.get("prerelease")),
        "releasedAt": release.get("published_at"),
        "assets": assets,
    }

def generate(releases):
    if not isinstance(releases, list):
        raise ValueError("GitHub releases must be a JSON array")
    channels = {"stable": None, "beta": None}
    for release in releases:
        item = candidate(release)
        if not item:
            continue
        channel = "beta" if item["prerelease"] else "stable"
        before = channels[channel]
        versions = tuple(map(int, item["version"].split(".")))
        if before is None or versions > tuple(map(int, before["version"].split("."))):
            channels[channel] = item
    return {"schemaVersion": 1, "source": OWNER_REPO, "channels": channels}

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True, type=Path)
    p.add_argument("--output", required=True, type=Path)
    args = p.parse_args()
    releases = json.loads(args.input.read_text(encoding="utf8"))
    result = generate(releases)
    if not any(result["channels"].values()):
        raise SystemExit("No complete launcher releases: refuse to replace the feed")
    args.output.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf8")
    print("Channels: " + ", ".join(
        f"{channel}=v{release['version']}" if release else f"{channel}=none"
        for channel, release in result["channels"].items()
    ))

if __name__ == "__main__":
    main()
