#!/bin/zsh
# Captures real screenshots and a recorded tour of iSensa running on this Mac, then edits the videos
# for the website. macOS asks once for an administrator password to allow UI automation, and iSensa
# may ask for folder access: answer those prompts during the first 25 seconds.
#
#   scripts/media/capture.sh [output-folder]      (default: website media and screenshot folders)
#
# Privacy: the computer name is hidden, the greeting does not use your name, technical details (IP
# addresses) stay closed, and the runner's whole-screen recording is cropped to iSensa's own windows
# by edit.py and deleted with the temporary folder.
set -euo pipefail
cd "$(dirname "$0")/../.."
out=${1:-$PWD/website}
work=$(mktemp -d)
trap 'rm -rf "$work"; rm -f iSensa.xcodeproj/xcshareddata/xcschemes/iSensaCapture.xcscheme' EXIT

xcodegen generate --quiet
schemes=iSensa.xcodeproj/xcshareddata/xcschemes
# A copy of the scheme that keeps the runner's screen recording even when the tests pass.
sed -e 's/<TestAction/<TestAction systemAttachmentLifetime = "keepAlways" preferredScreenCaptureFormat = "screenRecording"/' \
    "$schemes/iSensa.xcscheme" > "$schemes/iSensaCapture.xcscheme"

TEST_RUNNER_ISENSA_CAPTURE=1 xcodebuild test -project iSensa.xcodeproj -scheme iSensaCapture \
  -destination 'platform=macOS' -derivedDataPath "$work/dd" -resultBundlePath "$work/capture.xcresult" \
  -only-testing:iSensaUITests/ProductCaptureTests -quiet

xcrun xcresulttool export attachments --path "$work/capture.xcresult" --output-path "$work/attachments" >/dev/null
mkdir -p "$out/src/assets/screens" "$out/public/media"
# Screenshots and the tour's timeline; the tour recording and when it started.
read -r video start < <(python3 - "$work/attachments" "$out/src/assets/screens" "$work" <<'PY'
import json, re, shutil, sys
attachments, screens, work = sys.argv[1:4]
for test in json.load(open(f"{attachments}/manifest.json")):
    for item in test["attachments"]:
        name = item["suggestedHumanReadableName"]
        found = re.match(r"(.+?)_\d+_[0-9A-F-]+\.(png|json)$", name)
        if found and found.group(2) == "png":
            shutil.copy(f"{attachments}/{item['exportedFileName']}", f"{screens}/{found.group(1)}.png")
        elif found:
            shutil.copy(f"{attachments}/{item['exportedFileName']}", f"{work}/timeline.json")
        if name.startswith("Screen Recording") and "testRecordTour" in test["testIdentifier"]:
            print(f"{attachments}/{item['exportedFileName']}", item["timestamp"])
PY
)
python3 scripts/media/edit.py "$video" "$work/timeline.json" "$start" "$out/public/media"
(cd website && node scripts/posters.mjs "$out/public/media") && rm -f "$out/public/media/"{hero,tour}.jpg
echo "Screenshots in $out/src/assets/screens, videos in $out/public/media"
