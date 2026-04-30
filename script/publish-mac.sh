#!/usr/bin/env bash
# Publish a notarized macOS app to the OTA host.
#
# Validates that the input is a Developer ID-signed and notarized .app
# (with the Apple ticket already stapled), re-zips it with the correct
# ditto flags, drops the result into mac/, rewrites the build-info line
# on mac/install.html, and pushes to main.
#
# Input can be:
#   - a stapled .app directory
#   - an .xcarchive (latest Submissions/*/.app is used)
#   - an existing notarized .zip (extracted and re-validated)
#
# Usage: script/publish-mac.sh [--dry-run] <path-to-app-xcarchive-or-zip>

set -euo pipefail

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
  shift
fi

if [ $# -ne 1 ]; then
  echo "usage: $0 [--dry-run] <path-to-stapled-app | xcarchive | notarized-zip>" >&2
  exit 64
fi

INPUT="$1"
if [ ! -e "$INPUT" ]; then
  echo "error: not found: $INPUT" >&2
  exit 66
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Resolve the input into a single .app path inside $WORK.
APP=""
case "$INPUT" in
  *.app)
    if [ ! -d "$INPUT" ]; then
      echo "error: $INPUT looks like a .app but isn't a directory" >&2
      exit 65
    fi
    cp -R "$INPUT" "$WORK/"
    APP="$WORK/$(basename "$INPUT")"
    ;;
  *.xcarchive)
    # Find the most recently modified Submissions/<uuid>/<name>.app
    LATEST_SUB=""
    while IFS= read -r -d '' sub; do
      if [ -z "$LATEST_SUB" ] || [ "$sub" -nt "$LATEST_SUB" ]; then
        LATEST_SUB="$sub"
      fi
    done < <(find "$INPUT/Submissions" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    if [ -z "$LATEST_SUB" ]; then
      echo "error: no Submissions/ inside $INPUT — was the archive ever exported via Developer ID Distribution?" >&2
      exit 65
    fi
    SRC_APP="$(find "$LATEST_SUB" -maxdepth 1 -type d -name '*.app' -print -quit)"
    if [ -z "$SRC_APP" ]; then
      echo "error: no .app inside $LATEST_SUB" >&2
      exit 65
    fi
    cp -R "$SRC_APP" "$WORK/"
    APP="$WORK/$(basename "$SRC_APP")"
    ;;
  *.zip)
    ditto -x -k "$INPUT" "$WORK"
    APP="$(find "$WORK" -maxdepth 2 -type d -name '*.app' -print -quit)"
    if [ -z "$APP" ]; then
      echo "error: no .app extracted from $INPUT" >&2
      exit 65
    fi
    ;;
  *)
    echo "error: unsupported input type. Pass a .app, .xcarchive, or .zip." >&2
    exit 64
    ;;
esac

echo "Resolved app: $APP"

# Validate notarization. stapler validate fails if the ticket is missing
# or the bundle has been mutated since stapling. spctl assess confirms
# the resulting source classification — must be "Notarized Developer ID".
echo "Validating staple..."
xcrun stapler validate "$APP"

echo "Validating Gatekeeper acceptance..."
SPCTL_OUT="$(spctl -a -vv -t exec "$APP" 2>&1)"
echo "$SPCTL_OUT"
if ! grep -q "source=Notarized Developer ID" <<<"$SPCTL_OUT"; then
  echo "error: spctl did not report 'source=Notarized Developer ID'. Refusing to publish." >&2
  exit 70
fi

# Read versions from the .app's Info.plist.
SHORT_VER=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")
BUILD_VER=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Contents/Info.plist")
TODAY=$(date +%Y-%m-%d)

echo "Publishing macOS build $SHORT_VER ($BUILD_VER) dated $TODAY"

if $DRY_RUN; then
  echo "dry run: would re-zip into mac/RegionalLeadershipHub-macOS.zip"
  echo "dry run: would rewrite build-info line in mac/install.html to:"
  echo "  Build <strong>${SHORT_VER} (${BUILD_VER})</strong> · published ${TODAY} · notarized by Apple"
  echo "dry run: would commit + push if anything changed"
  exit 0
fi

# Re-zip the validated bundle. --sequesterRsrc --keepParent matches what
# Apple's notary submission expected — preserves resource forks and
# extended attributes, and includes the .app's parent dir in the archive.
DEST_ZIP="mac/RegionalLeadershipHub-macOS.zip"
mkdir -p mac
rm -f "$DEST_ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$DEST_ZIP"

# Rewrite the build-info line in mac/install.html. Matches:
#   <whitespace>Build <strong>X.Y (N)</strong> · published YYYY-MM-DD · notarized by Apple
NEW_LINE_PATTERN="s|^( +)Build <strong>[^<]+</strong> · published [0-9-]+ · notarized by Apple\$|\\1Build <strong>${SHORT_VER} (${BUILD_VER})</strong> · published ${TODAY} · notarized by Apple|"
if [ -f mac/install.html ]; then
  sed -i '' -E "$NEW_LINE_PATTERN" mac/install.html
fi

git add "$DEST_ZIP" mac/install.html

if git diff --cached --quiet; then
  echo "nothing changed (zip and install page already match) — skipping commit"
  exit 0
fi

git commit -m "macOS: publish $SHORT_VER ($BUILD_VER)"
git push origin HEAD:main

echo "live at https://only21mil.github.io/regional-leadership-hub-site/mac/install.html"
