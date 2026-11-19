#!/bin/zsh
# Full validation: lint, localization coverage, package tests, app build and UI tests.
# Hardware-tagged tests skip automatically where the interfaces do not exist (e.g. CI VMs).
set -euo pipefail
cd "$(dirname "$0")/.."
swiftlint lint --strict --quiet App Helper Packages/SensaKit/Sources Packages/SensaKit/Tests
# Catalogs are generated from scripts/localization/*.txt: they must match exactly.
python3 -I scripts/localization/build-catalogs.py --check
python3 -I scripts/check-localizations.py
(cd Packages/SensaKit && swift build -Xswiftc -warnings-as-errors && swift test)
xcodegen generate
xcodebuild -project Sensa.xcodeproj -scheme Sensa -destination 'platform=macOS' -derivedDataPath build/DerivedData test
