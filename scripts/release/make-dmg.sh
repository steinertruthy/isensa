#!/bin/zsh
# Builds iSensa (Release, Apple Silicon) and packs it into a disk image with an Applications shortcut.
# Output: build/release/iSensa-<version>-arm64.dmg and its .sha256 next to it.
#
# Without a Developer ID the app is signed ad hoc: macOS asks for confirmation on first open
# (see docs/DISTRIBUTION.md for signing and notarization once an Apple Developer account exists).
set -euo pipefail
cd "$(dirname "$0")/../.."

version=$(/usr/bin/awk -F'"' '/CFBundleShortVersionString/ { print $2; exit }' project.yml)
output=build/release
derived=build/release/DerivedData
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

xcodegen generate --quiet
xcodebuild -project iSensa.xcodeproj -scheme iSensa -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath "$derived" ARCHS=arm64 ONLY_ACTIVE_ARCH=NO clean build -quiet

app="$derived/Build/Products/Release/iSensa.app"
codesign --verify --deep --strict "$app"
built=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist")
[[ "$built" == "$version" ]] || { echo "Version mismatch: project.yml $version, app $built" >&2; exit 1; }

ditto "$app" "$stage/iSensa.app"
ln -s /Applications "$stage/Applications"
dmg="$output/iSensa-$version-arm64.dmg"
rm -f "$dmg" "$dmg.sha256"
hdiutil create -volname "iSensa $version" -srcfolder "$stage" -fs APFS -format ULFO -ov "$dmg" -quiet
hdiutil verify "$dmg" -quiet
(cd "$output" && shasum -a 256 "$(basename "$dmg")" > "$(basename "$dmg").sha256")
echo "$dmg"
cat "$dmg.sha256"
