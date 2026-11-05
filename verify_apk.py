"""Audit actual compiled manifest, rather than trusting source placeholders.

Usage: python verify_apk.py <SDK build-tools/34.0.0/aapt[.exe]> <apk>
"""
import json
import re
import subprocess
import sys

aapt, apk = sys.argv[1:]
badging = subprocess.check_output([aapt, "dump", "badging", apk], encoding="utf-8")
tree = subprocess.check_output([aapt, "dump", "xmltree", apk, "AndroidManifest.xml"], encoding="utf-8")
assert "package: name='com.k3nnut.cleanyourtv.unified'" in badging
assert "sdkVersion:'26'" in badging
assert "targetSdkVersion:'34'" in badging
nodes, stack = [], []
for line in tree.splitlines():
    element = re.match(r"^(\s*)E: ([\w-]+)\s*(?:\(|$)", line)
    if element:
        depth = len(element[1])
        while stack and stack[-1][0] >= depth:
            stack.pop()
        node = {"tag": element[2], "parent": stack[-1][1] if stack else None, "attrs": {}}
        nodes.append(node)
        stack.append((depth, node))
    elif stack:
        attribute = re.match(r'\s*A: android:(\w+)(?:\([^)]*\))?=(.*)', line)
        if attribute:
            stack[-1][1]["attrs"][attribute[1]] = attribute[2]

def named(node, name):
    return name in node["attrs"].get("name", "")

def component(name):
    matches = [n for n in nodes if n["tag"] in ("activity", "service") and named(n, name)]
    assert len(matches) == 1, name
    return matches[0]

def boolean(node, attr):
    value = node["attrs"].get(attr, "")
    assert value, f"Explicit {attr} required"
    return not value.endswith("0x0")

home = []
for node in nodes:
    if node["tag"] == "category" and named(node, "android.intent.category.HOME"):
        parent = node["parent"]
        while parent and parent["tag"] not in ("activity", "activity-alias"):
            parent = parent["parent"]
        if parent:
            home.append(parent)
assert len(home) == 1 and named(home[0], "HomeCandidateActivity")
assert boolean(home[0], "enabled") and boolean(home[0], "exported")
assert not boolean(component("MainActivity"), "enabled")
gallery = component("AmbientPhotoActivity")
assert boolean(gallery, "enabled") and not boolean(gallery, "exported")
dream = component("AmbientPhotoDream")
assert boolean(dream, "enabled") and boolean(dream, "exported")
assert "android.permission.BIND_DREAM_SERVICE" in dream["attrs"]["permission"]
for name in ("HomeKeyService", "InputKeyService", "ThemeProvider", "ClockDream"):
    matches = [n for n in nodes if named(n, name)]
    assert len(matches) == 1 and not boolean(matches[0], "enabled"), name
permissions = re.findall(r"uses-permission: name='([^']+)'", badging)
required_permissions = {
    "android.permission.INTERNET", "android.permission.ACCESS_NETWORK_STATE",
    "android.permission.ACCESS_WIFI_STATE"
}
assert required_permissions <= set(permissions), permissions
assert set(permissions) <= required_permissions | {
    "com.k3nnut.cleanyourtv.unified.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"
}, permissions
app = next(n for n in nodes if n["tag"] == "application")
assert not boolean(app, "allowBackup")
assert not boolean(app, "usesCleartextTraffic")  # outbound Android clients; local listener remains HTTP
print(json.dumps({"result": "PASS", "package": "com.k3nnut.cleanyourtv.unified",
                  "minSdk": 26, "targetSdk": 34,
                  "homeHandlers": 1, "gallery": "internal", "dream": "permission-protected",
                  "permissions": permissions}, indent=2))
