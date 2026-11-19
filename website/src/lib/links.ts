/**
 * A link leaves the website when it points to another origin, or to a path on this origin outside
 * the site's base (GitHub Pages hosts other projects on the same host). Such links open in a new tab.
 */
export function isExternal(href: string, siteOrigin: string, base = '/'): boolean {
  if (/^(mailto|tel):/i.test(href)) return true;
  if (href.startsWith('#') || (!/^[a-z][a-z\d+\-.]*:/i.test(href) && !href.startsWith('//'))) return false;
  try {
    const url = new URL(href, siteOrigin);
    if (url.origin !== new URL(siteOrigin).origin) return true;
    return !url.pathname.startsWith(base);
  } catch {
    return false;
  }
}

export const externalAttributes = { target: '_blank', rel: 'noopener noreferrer' } as const;
