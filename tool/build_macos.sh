#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin ]]; then
  echo 'macOS and Xcode are required.' >&2
  exit 1
fi
flutter pub get
flutter build macos --release
app='build/macos/Build/Products/Release/Font V.app'
test -d "$app"
mkdir -p artifacts/macos
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
ditto "$app" "$stage/Font V.app"
ln -s /Applications "$stage/Applications"
# An unsigned/ad-hoc disk image for local verification; production signing and
# notarization are performed separately with Developer ID credentials.
hdiutil create -volname 'Font V' -srcfolder "$stage" -ov -format UDZO artifacts/macos/FontV.dmg
hdiutil verify artifacts/macos/FontV.dmg
