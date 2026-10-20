import unittest
from build_launcher_feed import generate
BASE="https://github.com/DeadZone-Team/DeadZoneLauncher-Updates/releases/download/"
def release(version,beta=True,missing=(),bad=False):
    tag="launcher-v"+version
    names={"windows":f"DeadZoneLauncher-Windows-Setup-v{version}.exe",
           "linux":f"DeadZoneLauncher-Linux-x64-v{version}.AppImage",
           "arm":f"DeadZoneLauncher-macOS-arm64-v{version}.dmg",
           "intel":f"DeadZoneLauncher-macOS-x64-v{version}.dmg"}
    return {"tag_name":tag,"draft":False,"prerelease":beta,"published_at":"2026-10-20T00:00:00Z",
            "assets":[{"name":name,"size":123456,"digest":"sha256:"+"a"*64,
            "browser_download_url":BASE+tag+"/"+(name if not bad else "../unsafe")}
            for key,name in names.items() if key not in missing]}
class FeedTests(unittest.TestCase):
    def test_latest_complete_per_channel(self):
        x=generate([release("0.4.1"),release("0.4.9",missing=("intel",)),release("0.4.2"),release("0.3.8",beta=False)])
        self.assertEqual(x["channels"]["beta"]["version"],"0.4.2")
        self.assertEqual(x["channels"]["stable"]["version"],"0.3.8")
    def test_no_cross_release_mix(self):
        self.assertIsNone(generate([release("0.4.1",missing=("intel",))])["channels"]["beta"])
    def test_reject_unsafe_urls(self):
        self.assertIsNone(generate([release("0.4.1",bad=True)])["channels"]["beta"])
    def test_numeric_versions(self):
        self.assertEqual(generate([release("0.4.9"),release("0.4.10")])["channels"]["beta"]["version"],"0.4.10")
if __name__=="__main__":
    unittest.main()
