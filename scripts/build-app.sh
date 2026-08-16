#!/usr/bin/env bash
set -euo pipefail

REPOFEED_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPOFEED_OUTPUT="${1:-$REPOFEED_ROOT/dist}"
REPOFEED_APP="$REPOFEED_OUTPUT/RepoFeed.app"

if [[ -z "$REPOFEED_OUTPUT" || "$REPOFEED_OUTPUT" == "/" ]]; then
  echo "Refusing unsafe output directory" >&2
  exit 1
fi

cd "$REPOFEED_ROOT"
swift build -c release

mkdir -p "$REPOFEED_OUTPUT"
if [[ -d "$REPOFEED_APP" ]]; then
  rm -rf "$REPOFEED_APP"
fi
mkdir -p "$REPOFEED_APP/Contents/MacOS" "$REPOFEED_APP/Contents/Resources"
cp ".build/release/RepoFeed" "$REPOFEED_APP/Contents/MacOS/RepoFeed"
cp "Resources/Info.plist" "$REPOFEED_APP/Contents/Info.plist"

codesign --force --deep --sign - \
  --entitlements "Resources/RepoFeed.entitlements" \
  "$REPOFEED_APP"

echo "$REPOFEED_APP"
