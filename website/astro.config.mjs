// @ts-check
import { defineConfig } from 'astro/config';

// GitHub Pages serves the project at https://steinertruthy.github.io/isensa/.
// For a custom domain later, build with SITE_URL=https://example.com BASE_PATH=/ (see README.md).
const site = process.env.SITE_URL ?? 'https://steinertruthy.github.io';
const base = process.env.BASE_PATH ?? '/isensa';

export default defineConfig({
  site,
  base,
  trailingSlash: 'always',
  build: { format: 'directory', inlineStylesheets: 'auto' },
  devToolbar: { enabled: false },
  compressHTML: true,
});
