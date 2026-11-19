import { defaultLocale, type Locale } from '../i18n/config';

/** Joins a path to the site's base (`/isensa/` on GitHub Pages), keeping one slash between parts. */
export function withBase(path: string, base: string = import.meta.env.BASE_URL): string {
  const root = base.endsWith('/') ? base : `${base}/`;
  return root + path.replace(/^\/+/, '');
}

/** The URL path of a page in a language: `''` is the home page, `'terms'` the terms. */
export function localePath(locale: Locale, page = '', base?: string): string {
  const parts = [locale, page].filter(Boolean).join('/');
  return withBase(`${parts}/`, base);
}

export { defaultLocale };
