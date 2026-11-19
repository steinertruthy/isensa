/** The parts of the GitHub Releases API that the download section uses. */
export interface ReleaseAsset {
  name: string;
  size: number;
  browser_download_url: string;
  content_type?: string;
  digest?: string | null;
}

export interface Release {
  tag_name: string;
  name: string | null;
  html_url: string;
  published_at: string | null;
  prerelease: boolean;
  draft: boolean;
  body?: string | null;
  assets: ReleaseAsset[];
}

export type Architecture = 'universal' | 'arm64' | 'x86_64';

export interface Installer {
  version: string;
  channel: 'stable' | 'beta';
  published: Date | null;
  notesURL: string;
  asset: ReleaseAsset;
  /** Only when the file name says so; never assumed. */
  architecture: Architecture | null;
  sha256: string | null;
}

const installerPattern = /\.(dmg|pkg|zip)$/i;

/** Prefers a disk image, then an installer package, then a zip archive. */
function rank(asset: ReleaseAsset): number {
  const extension = asset.name.toLowerCase().split('.').pop();
  return extension === 'dmg' ? 0 : extension === 'pkg' ? 1 : 2;
}

export function architecture(fileName: string): Architecture | null {
  const name = fileName.toLowerCase();
  if (/universal/.test(name)) return 'universal';
  if (/(arm64|aarch64|apple[-_]?silicon)/.test(name)) return 'arm64';
  if (/(x86[-_]?64|intel|amd64)/.test(name)) return 'x86_64';
  return null;
}

/** A SHA-256 published by GitHub (`digest`), or in a `<file>.sha256` asset's name list, or in the notes. */
export function checksum(asset: ReleaseAsset, release: Release): string | null {
  const digest = asset.digest?.match(/^sha256:([a-f\d]{64})$/i);
  if (digest) return digest[1].toLowerCase();
  const line = release.body?.split('\n').find((text) => text.includes(asset.name) && /[a-f\d]{64}/i.test(text));
  return line?.match(/[a-f\d]{64}/i)?.[0].toLowerCase() ?? null;
}

/**
 * The newest published release that has a macOS installer. Stable releases win over newer betas;
 * a beta is offered only when no stable release has an installer.
 */
export function latestInstaller(releases: readonly Release[]): Installer | null {
  const published = releases.filter((release) => !release.draft);
  const ordered = [...published.filter((r) => !r.prerelease), ...published.filter((r) => r.prerelease)];
  for (const release of ordered) {
    const asset = release.assets.filter((a) => installerPattern.test(a.name)).sort((a, b) => rank(a) - rank(b))[0];
    if (!asset) continue;
    return {
      version: release.tag_name.replace(/^v(?=\d)/, ''),
      channel: release.prerelease ? 'beta' : 'stable',
      published: release.published_at ? new Date(release.published_at) : null,
      notesURL: release.html_url,
      asset,
      architecture: architecture(asset.name),
      sha256: checksum(asset, release),
    };
  }
  return null;
}

export function formatBytes(bytes: number, locale: string): string {
  const units = ['byte', 'kilobyte', 'megabyte', 'gigabyte'] as const;
  let value = bytes;
  let unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit += 1;
  }
  return new Intl.NumberFormat(locale, {
    style: 'unit',
    unit: units[unit],
    unitDisplay: 'short',
    maximumFractionDigits: unit === 0 ? 0 : 1,
  }).format(value);
}

/** macOS, but not an iPad asking for the desktop site (it reports “Macintosh” and has touch). */
export function isMacOS(platform: string, userAgent: string, maxTouchPoints: number): boolean {
  const mac = /mac/i.test(platform) || /Macintosh/.test(userAgent);
  return mac && maxTouchPoints <= 1;
}

/** Replaces `{name}` placeholders. */
export function fill(template: string, values: Record<string, string | number>): string {
  return template.replace(/\{(\w+)\}/g, (match, key: string) => (key in values ? String(values[key]) : match));
}
