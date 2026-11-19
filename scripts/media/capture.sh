#!/bin/zsh
# Captures real screenshots of iSensa running on this Mac, in dark and light, for the website.
# macOS asks once for an administrator password to allow UI automation, and iSensa may ask for
# folder access: answer those prompts during the first 25 seconds.
#
#   scripts/media/capture.sh [screenshots-folder]   (default: website/src/assets/screens)
#
# Privacy: the computer name is hidden, the greeting does not use your name and technical details
# (IP addresses) stay closed. The test runner's own recording is deleted with the temporary folder.
set -euo pipefail
cd "$(dirname "$0")/../.."
out=${1:-$PWD/website/src/assets/screens}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$out"

xcodegen generate --quiet
TEST_RUNNER_ISENSA_CAPTURE=1 xcodebuild test -project iSensa.xcodeproj -scheme iSensa \
  -destination 'platform=macOS' -derivedDataPath "$work/dd" -resultBundlePath "$work/capture.xcresult" \
  -only-testing:iSensaUITests/ProductCaptureTests -quiet

xcrun xcresulttool export attachments --path "$work/capture.xcresult" --output-path "$work/attachments" >/dev/null
python3 - "$work/attachments" "$out" <<'PY'
import json, re, shutil, sys
attachments, screens = sys.argv[1:3]
for test in json.load(open(f"{attachments}/manifest.json")):
    for item in test["attachments"]:
        found = re.match(r"(.+?)_\d+_[0-9A-F-]+\.png$", item["suggestedHumanReadableName"])
        if found:
            shutil.copy(f"{attachments}/{item['exportedFileName']}", f"{screens}/{found.group(1)}.png")
PY
echo "Screenshots in $out"
