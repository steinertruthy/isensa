import { repository } from '../lib/site';
import { fill, formatBytes, isMacOS, latestInstaller, type Installer, type Release } from '../lib/releases';

interface Strings {
  tag: string;
  version: string;
  stable: string;
  beta: string;
  loading: string;
  buttonMac: string;
  buttonOther: string;
  noReleaseTitle: string;
  noReleaseText: string;
  errorText: string;
  notMac: string;
  archUnknown: string;
  allReleases: string;
  copied: string;
  copy: string;
  architectures: Record<'universal' | 'arm64' | 'x86_64', string>;
  latest: string;
  noRelease: string;
}

const cacheKey = 'isensa.releases';
const cacheAge = 10 * 60 * 1000;

/** Public GitHub data, cached for ten minutes per visitor to stay well within the API's rate limit. */
async function github(): Promise<{ releases: Release[] }> {
  try {
    const cached = JSON.parse(sessionStorage.getItem(cacheKey) ?? 'null');
    if (cached && Date.now() - cached.at < cacheAge) return cached.data;
  } catch {
    // No storage: fetch every time.
  }
  const headers = { Accept: 'application/vnd.github+json' };
  const releases = await fetch(`${repository.api}/releases?per_page=20`, { headers });
  if (!releases.ok) throw new Error(`GitHub releases: ${releases.status}`);
  const data = { releases: (await releases.json()) as Release[] };
  try {
    sessionStorage.setItem(cacheKey, JSON.stringify({ at: Date.now(), data }));
  } catch {
    // Ignore.
  }
  return data;
}

export function setUpDownload(): void {
  const panel = document.querySelector<HTMLElement>('[data-download]');
  const footerVersion = document.querySelector<HTMLElement>('[data-footer-version]');
  const strings = panel ? (JSON.parse(panel.querySelector('[data-download-strings]')?.textContent ?? '{}') as Strings) : null;
  const onMac = isMacOS(
    (navigator as Navigator & { userAgentData?: { platform?: string } }).userAgentData?.platform ?? navigator.platform,
    navigator.userAgent,
    navigator.maxTouchPoints,
  );

  if (panel && strings) {
    panel.dataset.state = 'loading';
    panel.querySelector<HTMLElement>('[data-download-note]')!.textContent = strings.loading;
  }

  github()
    .then(({ releases }) => {
      const installer = latestInstaller(releases);
      if (panel && strings) showRelease(panel, strings, installer, onMac);
      if (footerVersion) {
        footerVersion.textContent = installer ? fill(footerVersion.dataset.latest ?? '{version}', { version: installer.version }) : footerVersion.textContent;
      }
    })
    .catch(() => {
      if (!panel || !strings) return;
      panel.dataset.state = 'error';
      panel.querySelector<HTMLElement>('[data-download-note]')!.textContent = strings.errorText;
      if (!onMac) panel.querySelector<HTMLElement>('[data-download-label]')!.textContent = strings.buttonOther;
    });
}

function showRelease(panel: HTMLElement, strings: Strings, installer: Installer | null, onMac: boolean): void {
  const note = panel.querySelector<HTMLElement>('[data-download-note]')!;
  const button = panel.querySelector<HTMLAnchorElement>('[data-download-button]')!;
  const label = panel.querySelector<HTMLElement>('[data-download-label]')!;
  const version = panel.querySelector<HTMLElement>('[data-download-version]')!;
  const channel = panel.querySelector<HTMLElement>('[data-download-channel]')!;
  const hero = document.querySelector<HTMLAnchorElement>('[data-download-primary]');

  if (!installer) {
    // No installer published: the button keeps pointing at the releases page, never at a file.
    panel.dataset.state = 'empty';
    version.textContent = strings.noReleaseTitle;
    note.textContent = onMac ? strings.noReleaseText : `${strings.notMac} ${strings.noReleaseText}`;
    label.textContent = strings.allReleases;
    return;
  }

  panel.dataset.state = 'ready';
  version.textContent = fill(strings.version, { version: installer.version });
  channel.textContent = installer.channel === 'beta' ? strings.beta : strings.stable;
  channel.dataset.kind = installer.channel === 'beta' ? 'experimental' : 'available';
  channel.hidden = false;

  if (onMac) {
    // The installer is hosted by GitHub, another domain: like every external link, a new tab.
    for (const link of [button, hero]) {
      if (!link) continue;
      link.href = installer.asset.browser_download_url;
      link.target = '_blank';
      link.rel = 'noopener noreferrer';
    }
    label.textContent = strings.buttonMac;
    note.textContent = '';
  } else {
    label.textContent = strings.buttonOther;
    note.textContent = strings.notMac;
  }

  const facts = panel.querySelector<HTMLElement>('[data-download-facts]')!;
  const set = (name: string, value: string) => (facts.querySelector(`[data-fact="${name}"]`)!.textContent = value);
  set(
    'released',
    installer.published ? new Intl.DateTimeFormat(strings.tag, { dateStyle: 'medium' }).format(installer.published) : '—',
  );
  set('size', formatBytes(installer.asset.size, strings.tag));
  set('architecture', installer.architecture ? strings.architectures[installer.architecture] : strings.archUnknown);
  if (installer.sha256) {
    set('checksum', installer.sha256);
    const row = facts.querySelector<HTMLElement>('[data-fact-row="checksum"]')!;
    row.hidden = false;
    const copy = row.querySelector<HTMLButtonElement>('[data-copy-checksum]')!;
    copy.addEventListener('click', () => {
      navigator.clipboard?.writeText(installer.sha256 ?? '').then(() => {
        copy.setAttribute('aria-label', strings.copied);
        setTimeout(() => copy.setAttribute('aria-label', strings.copy), 2000);
      });
    });
  }
  facts.hidden = false;
  const notes = panel.querySelector<HTMLElement>('[data-notes-item]');
  if (notes) {
    notes.hidden = false;
    notes.querySelector<HTMLAnchorElement>('[data-notes-link]')!.href = installer.notesURL;
  }
}
