import { describe, expect, it } from 'vitest';
import { architecture, fill, formatBytes, isMacOS, latestInstaller, type Release } from '../src/lib/releases';

const release = (overrides: Partial<Release>): Release => ({
  tag_name: 'v1.0.0',
  name: null,
  html_url: 'https://github.com/steinertruthy/isensa/releases/tag/v1.0.0',
  published_at: '2026-12-01T10:00:00Z',
  prerelease: false,
  draft: false,
  body: '',
  assets: [],
  ...overrides,
});
const asset = (name: string, extra = {}) => ({ name, size: 10_500_000, browser_download_url: `https://github.com/x/${name}`, ...extra });

describe('latestInstaller', () => {
  it('finds nothing without releases or installers', () => {
    expect(latestInstaller([])).toBeNull();
    expect(latestInstaller([release({ assets: [asset('notes.txt')] })])).toBeNull();
  });

  it('prefers a disk image and reads the version from the tag', () => {
    const found = latestInstaller([release({ assets: [asset('iSensa.zip'), asset('iSensa-1.0.0.dmg')] })]);
    expect(found?.asset.name).toBe('iSensa-1.0.0.dmg');
    expect(found?.version).toBe('1.0.0');
    expect(found?.channel).toBe('stable');
  });

  it('prefers a stable release over a newer beta, and skips drafts', () => {
    const found = latestInstaller([
      release({ tag_name: 'v2.0.0-beta.1', prerelease: true, assets: [asset('beta.dmg')] }),
      release({ tag_name: 'v3.0.0', draft: true, assets: [asset('draft.dmg')] }),
      release({ tag_name: 'v1.2.0', assets: [asset('stable.dmg')] }),
    ]);
    expect(found?.version).toBe('1.2.0');
  });

  it('offers a beta when it is the only installer', () => {
    const found = latestInstaller([release({ tag_name: 'v0.2.0-beta', prerelease: true, assets: [asset('iSensa.dmg')] })]);
    expect(found?.channel).toBe('beta');
  });

  it('reports the architecture only when the file name states it', () => {
    expect(architecture('iSensa-1.0-arm64.dmg')).toBe('arm64');
    expect(architecture('iSensa-universal.dmg')).toBe('universal');
    expect(architecture('iSensa-x86_64.dmg')).toBe('x86_64');
    expect(architecture('iSensa.dmg')).toBeNull();
  });

  it('takes the SHA-256 from GitHub’s digest, or from the release notes', () => {
    const hash = 'a'.repeat(64);
    expect(latestInstaller([release({ assets: [asset('i.dmg', { digest: `sha256:${hash}` })] })])?.sha256).toBe(hash);
    expect(latestInstaller([release({ body: `${'b'.repeat(64)}  i.dmg`, assets: [asset('i.dmg')] })])?.sha256).toBe('b'.repeat(64));
    expect(latestInstaller([release({ assets: [asset('i.dmg')] })])?.sha256).toBeNull();
  });
});

describe('helpers', () => {
  it('formats sizes for the visitor’s language', () => {
    expect(formatBytes(10_500_000, 'en')).toBe('10.5 MB');
    expect(formatBytes(10_500_000, 'pt-BR')).toBe('10,5 MB');
  });

  it('recognizes macOS but not an iPad asking for the desktop site', () => {
    expect(isMacOS('MacIntel', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', 0)).toBe(true);
    expect(isMacOS('macOS', '', 0)).toBe(true);
    expect(isMacOS('MacIntel', 'Mozilla/5.0 (Macintosh)', 5)).toBe(false);
    expect(isMacOS('Win32', 'Mozilla/5.0 (Windows NT 10.0)', 0)).toBe(false);
  });

  it('fills placeholders and leaves unknown ones', () => {
    expect(fill('{current} of {total}', { current: 1, total: 9 })).toBe('1 of 9');
    expect(fill('{x}', {})).toBe('{x}');
  });
});
