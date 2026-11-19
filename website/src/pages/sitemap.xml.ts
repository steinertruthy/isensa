import type { APIRoute } from 'astro';
import { defaultLocale, localeInfo, locales } from '../i18n';
import { localePath, withBase } from '../lib/paths';

const pages = ['', 'terms', 'privacy'] as const;

/** Every page in every language, each listing its translations (hreflang). */
export const GET: APIRoute = ({ site }) => {
  const absolute = (path: string) => new URL(path, site).href;
  const entries = pages.flatMap((page) =>
    locales.map((locale) => {
      const alternates = locales
        .map((code) => `<xhtml:link rel="alternate" hreflang="${localeInfo[code].tag}" href="${absolute(localePath(code, page))}"/>`)
        .join('');
      const fallback = page === '' ? withBase('') : localePath(defaultLocale, page);
      return `<url><loc>${absolute(localePath(locale, page))}</loc>${alternates}<xhtml:link rel="alternate" hreflang="x-default" href="${absolute(fallback)}"/></url>`;
    }),
  );
  const body = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">${entries.join('')}</urlset>\n`;
  return new Response(body, { headers: { 'Content-Type': 'application/xml; charset=utf-8' } });
};
