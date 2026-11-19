# Contributing to iSensa

Thank you for helping. Issues and pull requests are welcome in English or Portuguese.

## Principles every change keeps

- **Honest data.** Never invent a sensor name. A sensor is named only after it was verified on that
  Mac model (`verifiedOn` in `SensorCatalog.json`); anything else shows its raw key. Estimated and
  derived values are labelled as such.
- **Fan safety.** The privileged helper validates every command again, clamps speeds to the limits the
  hardware reports and returns the fans to automatic control on any failure. Changes to fan control
  need tests for the failure paths.
- **Nothing leaves the Mac.** The app makes no network connections.
- **Ten languages.** Every user-visible string is translated (see below).
- **Accessibility and performance.** VoiceOver labels, keyboard access, Reduce Motion, and low energy
  use when only the menu bar is visible.

## The app

```bash
brew install xcodegen swiftlint
scripts/bootstrap.sh            # generates iSensa.xcodeproj
scripts/ci.sh                   # lint, package tests and the app build
```

- Swift 6 with strict concurrency, SwiftLint `--strict`.
- Package tests: `swift test --package-path Packages/iSensaKit`.
- UI tests run against labelled demo data (`-iSensaDemoMode`).
- Translations: edit `scripts/localization/<language>.txt`, then run
  `scripts/localization/build-catalogs.py` and `scripts/check-localizations.py`.
- Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Design: [docs/DESIGN.md](docs/DESIGN.md).

## The website

The site lives in [`website/`](website/README.md) (Astro, TypeScript). `npm run ci` there runs the
type check, lint, tests, build and the build verification.

## Pull requests

1. Open an issue first for larger changes, so the approach can be discussed.
2. Keep each pull request focused, with tests for new behaviour.
3. Make sure `scripts/ci.sh` (app) or `npm run ci` (website) passes.
4. By contributing, you agree that your contribution is licensed under the [MIT License](LICENSE).
