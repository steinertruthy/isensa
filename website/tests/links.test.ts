import { describe, expect, it } from 'vitest';
import { isExternal } from '../src/lib/links';
import { localePath, withBase } from '../src/lib/paths';

const site = 'https://steinertruthy.github.io';

describe('isExternal', () => {
  it('keeps the site’s own pages and anchors in the same tab', () => {
    expect(isExternal('#download', site, '/isensa/')).toBe(false);
    expect(isExternal('/isensa/pt-br/terms/', site, '/isensa/')).toBe(false);
    expect(isExternal(`${site}/isensa/en/`, site, '/isensa/')).toBe(false);
  });

  it('opens other domains, and other projects on the same host, in a new tab', () => {
    expect(isExternal('https://github.com/steinertruthy/isensa', site, '/isensa/')).toBe(true);
    expect(isExternal('https://api.github.com/repos', site, '/isensa/')).toBe(true);
    expect(isExternal(`${site}/another-project/`, site, '/isensa/')).toBe(true);
    expect(isExternal('mailto:someone@example.com', site, '/isensa/')).toBe(true);
  });
});

describe('paths under the base', () => {
  it('builds every URL under /isensa/', () => {
    expect(withBase('media/hero.mp4', '/isensa/')).toBe('/isensa/media/hero.mp4');
    expect(withBase('', '/isensa')).toBe('/isensa/');
    expect(localePath('pt-br', 'privacy', '/isensa/')).toBe('/isensa/pt-br/privacy/');
    expect(localePath('en', '', '/')).toBe('/en/');
  });
});
