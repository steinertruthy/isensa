// Checks the production build before it is published: every page in every language exists, every
// internal URL lives under the base path and points to a real file, and every external link opens
// in a new tab with rel="noopener noreferrer".
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';

const dist = new URL('../dist/', import.meta.url).pathname;
const base = (process.env.BASE_PATH ?? '/isensa').replace(/\/?$/, '/');
const site = new URL(process.env.SITE_URL ?? 'https://steinertruthy.github.io');
const locales = ['en', 'pt-br', 'es', 'fr', 'de', 'it', 'ja', 'ko', 'zh-hans', 'zh-hant'];
const tags = { en: 'en', 'pt-br': 'pt-BR', es: 'es', fr: 'fr', de: 'de', it: 'it', ja: 'ja', ko: 'ko', 'zh-hans': 'zh-Hans', 'zh-hant': 'zh-Hant' };
const problems = [];

if (!existsSync(dist)) {
  console.error('dist/ is missing: run the build first.');
  process.exit(1);
}

const walk = (folder) =>
  readdirSync(folder).flatMap((name) => {
    const path = join(folder, name);
    return statSync(path).isDirectory() ? walk(path) : [path];
  });
const files = walk(dist);
const pages = files.filter((file) => file.endsWith('.html'));

const required = ['index.html', '404.html', 'sitemap.xml', 'robots.txt', 'favicon.svg', 'manifest.webmanifest', 'media/hero.mp4', 'media/hero.webm', 'media/tour.mp4'];
for (const locale of locales) for (const page of ['', 'terms/', 'privacy/']) required.push(`${locale}/${page}index.html`);
for (const file of required) if (!existsSync(join(dist, file))) problems.push(`missing ${file}`);

/** The file a URL path under the base would be served from. */
function served(path) {
  const clean = decodeURIComponent(path.split(/[?#]/)[0]).slice(base.length);
  const target = join(dist, clean);
  if (clean === '' || clean.endsWith('/')) return existsSync(join(target, 'index.html'));
  return existsSync(target);
}

for (const file of pages) {
  const html = readFileSync(file, 'utf8');
  const name = relative(dist, file);
  const locale = name.split('/')[0];
  if (tags[locale] && !html.includes(`<html lang="${tags[locale]}"`)) problems.push(`${name}: wrong lang attribute`);
  if (name !== '404.html' && (html.match(/hreflang="/g) ?? []).length < locales.length + 1) problems.push(`${name}: missing hreflang links`);
  if (!/<link rel="canonical" href="https?:\/\//.test(html)) problems.push(`${name}: missing canonical URL`);

  for (const [, attribute, value] of html.matchAll(/\s(href|src|srcset|poster)="([^"]*)"/g)) {
    for (const url of attribute === 'srcset' ? value.split(',').map((part) => part.trim().split(/\s+/)[0]) : [value]) {
      if (!url || url.startsWith('#') || url.startsWith('data:') || /^(mailto|tel):/.test(url)) continue;
      const absolute = new URL(url, site);
      if (absolute.origin !== site.origin) continue;
      if (!absolute.pathname.startsWith(base)) problems.push(`${name}: ${url} is outside ${base}`);
      else if (!served(absolute.pathname)) problems.push(`${name}: ${url} does not exist in the build`);
    }
  }

  for (const [tag] of html.matchAll(/<a\s[^>]*>/g)) {
    const href = tag.match(/href="([^"]*)"/)?.[1];
    if (!href || href.startsWith('#')) continue;
    const url = new URL(href, site);
    const external = url.origin !== site.origin || !url.pathname.startsWith(base);
    const opensNewTab = tag.includes('target="_blank"') && /rel="noopener noreferrer"/.test(tag);
    if (external && !opensNewTab) problems.push(`${name}: external link without target/rel: ${href}`);
    if (!external && tag.includes('target="_blank"')) problems.push(`${name}: internal link opens a new tab: ${href}`);
  }
}

const sitemap = readFileSync(join(dist, 'sitemap.xml'), 'utf8');
const listed = (sitemap.match(/<loc>/g) ?? []).length;
if (listed !== locales.length * 3) problems.push(`sitemap lists ${listed} pages, expected ${locales.length * 3}`);

if (problems.length) {
  console.error(`Build check failed (${problems.length}):\n- ${[...new Set(problems)].join('\n- ')}`);
  process.exit(1);
}
console.log(`Build check passed: ${pages.length} pages, ${files.length} files, base ${base}.`);
