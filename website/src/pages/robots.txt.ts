import type { APIRoute } from 'astro';
import { withBase } from '../lib/paths';

// On GitHub Pages this file lives under /isensa/, where crawlers do not look for it; it takes effect with
// a custom domain. The sitemap is also declared in the page head for search consoles.
export const GET: APIRoute = ({ site }) =>
  new Response(`User-agent: *\nAllow: /\n\nSitemap: ${new URL(withBase('sitemap.xml'), site).href}\n`, {
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  });
