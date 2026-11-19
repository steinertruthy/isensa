#!/bin/zsh
# Generates the Xcode project from project.yml and checks the toolchain.
set -euo pipefail
cd "$(dirname "$0")/.."
command -v xcodegen >/dev/null || { echo "Install XcodeGen: brew install xcodegen"; exit 1; }
command -v swiftlint >/dev/null || echo "warning: SwiftLint missing (brew install swiftlint)"
xcodegen generate
echo "Open Sensa.xcodeproj or run scripts/ci.sh"
