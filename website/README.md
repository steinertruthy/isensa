# iSensa website

The official site of iSensa, published at <https://steinertruthy.github.io/isensa/>. It is a static
[Astro](https://astro.build) site in TypeScript, built and deployed to GitHub Pages by
[`.github/workflows/pages.yml`](../.github/workflows/pages.yml). It never runs a server.

## Run it locally

Node.js 22.23.4 or later (see `.nvmrc`).

```bash
cd website
npm ci
npm run dev        # http://localhost:4321/isensa/
```

`npm run ci` runs everything the workflow runs: type check (`astro check`), ESLint, unit tests (Vitest),
the production build and `scripts/verify-build.mjs`, which checks that every page exists in every
language, every internal URL stays under `/isensa/` and resolves, and every external link opens in a new
tab with `rel="noopener noreferrer"`.

## How it is organized

| Path | What it holds |
|---|---|
| `src/i18n/locales/*.ts` | All text, one file per language. English is the reference; tests fail if a language misses a key or a placeholder. |
| `src/i18n/config.ts` | The languages (the same ten as the app) and the browser-language matching. |
| `src/components/` | Page sections. `Link.astro` decides, for every link, whether it opens in a new tab. |
| `src/lib/` | Pure logic: GitHub release selection, paths under the base, link rules. |
| `src/scripts/` | The little JavaScript the page needs: theme, menu, videos, gallery, GitHub data. |
| `src/assets/screens/` | Real screenshots of the app, dark and light. |
| `public/media/` | The real recordings: `hero.*` (muted loop) and `tour.mp4`. |

Pages: `/isensa/` picks a language (a manual choice is remembered and wins over the browser's
language), `/isensa/<language>/`, `/terms/` and `/privacy/` in each language, `sitemap.xml` with
`hreflang` alternates, and `404.html`.

## Screenshots and videos

They are captured from the real app on a Mac, never drawn:

```bash
scripts/media/capture.sh          # from the repository root
```

The script runs `UITests/ProductCaptureTests.swift` against the real sensors (computer name hidden,
technical details closed), exports the screenshots, and `scripts/media/edit.py` crops the test runner's
screen recording to iSensa's own windows to produce `hero.mp4`, `hero.webm`, `tour.mp4` and posters.
macOS asks for an administrator password to allow UI automation.

## Downloads

The download section reads <https://api.github.com/repos/steinertruthy/isensa/releases> in the
visitor's browser. It offers the first `.dmg` (then `.pkg`, then `.zip`) of the newest non-draft
release, preferring stable releases over betas. Architecture is shown only when the file name states
it (`arm64`, `universal`, `x86_64`), and the SHA-256 comes from GitHub's asset digest or from a line in
the release notes. Without a release the button points to the releases page, never to a file.

## Publishing

Every push to `main` that touches `website/` builds and deploys the site. One-time repository setup:
**Settings › Pages › Build and deployment › Source: GitHub Actions**.

### Custom domain (later)

1. Add the domain in **Settings › Pages › Custom domain** and create the DNS records GitHub shows.
2. In **Settings › Secrets and variables › Actions › Variables**, set `SITE_URL` (for example
   `https://isensa.example`) and `BASE_PATH` to `/`.
3. Push any change to `website/` (or run the workflow manually). Canonical URLs, `hreflang`, the
   sitemap and `robots.txt` follow these values.
