#!/usr/bin/env bash
# Publish a built IPA to the OTA host.
#
# Reads CFBundleShortVersionString and CFBundleVersion from the IPA's
# Info.plist, copies the IPA into ota/, updates manifest.plist's
# bundle-version, rewrites the build-info line in both install pages,
# then commits and pushes to main.
#
# Usage: script/publish-ota.sh /path/to/RegionalLeadershipHub.ipa

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <path-to-ipa>" >&2
  exit 64
fi

SRC_IPA="$1"
if [ ! -f "$SRC_IPA" ]; then
  echo "error: IPA not found: $SRC_IPA" >&2
  exit 66
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

unzip -q "$SRC_IPA" -d "$WORK"
APP="$(find "$WORK/Payload" -maxdepth 1 -name '*.app' -print -quit)"
if [ -z "$APP" ]; then
  echo "error: no .app inside Payload/" >&2
  exit 65
fi

SHORT_VER=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Info.plist")
BUILD_VER=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Info.plist")
TODAY=$(date +%Y-%m-%d)

echo "publishing build $SHORT_VER ($BUILD_VER) dated $TODAY"

cp "$SRC_IPA" ota/RegionalLeadershipHub.ipa

/usr/libexec/PlistBuddy -c "Set :items:0:metadata:bundle-version $BUILD_VER" ota/manifest.plist

for page in ota/install.html ota/install-now.html; do
  sed -i '' -E "s|^( +)Build <strong>[^<]+</strong> · published [0-9-]+\$|\\1Build <strong>${SHORT_VER} (${BUILD_VER})</strong> · published ${TODAY}|" "$page"
done

git add ota/RegionalLeadershipHub.ipa ota/manifest.plist ota/install.html ota/install-now.html
if git diff --cached --quiet; then
  echo "nothing changed — skipping commit"
  exit 0
fi
git commit -m "OTA: publish $SHORT_VER ($BUILD_VER)"
git push origin HEAD:main

echo "live at https://only21mil.github.io/regional-leadership-hub-site/ota/install.html"
