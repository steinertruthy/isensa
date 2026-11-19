/** Header, theme and language preference. */
type Theme = 'system' | 'light' | 'dark';
const themeKey = 'isensa.theme';
const localeKey = 'isensa.locale';

function read(key: string): string | null {
  try {
    return localStorage.getItem(key);
  } catch {
    return null;
  }
}

function write(key: string, value: string | null): void {
  try {
    if (value === null) localStorage.removeItem(key);
    else localStorage.setItem(key, value);
  } catch {
    // Private windows can refuse storage; the choice then lasts for this page only.
  }
}

function setUpTheme(): void {
  const button = document.querySelector<HTMLButtonElement>('[data-theme-toggle]');
  if (!button) return;
  const names = JSON.parse(button.dataset.names ?? '{}') as Record<Theme, string>;
  const order: Theme[] = ['system', 'light', 'dark'];
  const apply = (theme: Theme) => {
    if (theme === 'system') delete document.documentElement.dataset.theme;
    else document.documentElement.dataset.theme = theme;
    button.dataset.current = theme;
    button.setAttribute('aria-label', `${button.dataset.label}: ${names[theme]}`);
    button.title = names[theme];
  };
  const saved = read(themeKey);
  apply(saved === 'light' || saved === 'dark' ? saved : 'system');
  button.addEventListener('click', () => {
    const current = (button.dataset.current as Theme) ?? 'system';
    const next = order[(order.indexOf(current) + 1) % order.length];
    write(themeKey, next === 'system' ? null : next);
    apply(next);
  });
}

function setUpHeader(): void {
  const header = document.querySelector<HTMLElement>('[data-header]');
  if (!header) return;
  const update = () => header.toggleAttribute('data-scrolled', window.scrollY > 8);
  update();
  window.addEventListener('scroll', update, { passive: true });

  const toggle = header.querySelector<HTMLButtonElement>('[data-menu-toggle]');
  const panel = document.getElementById('mobile-nav');
  if (!toggle || !panel) return;
  const setOpen = (open: boolean) => {
    toggle.setAttribute('aria-expanded', String(open));
    toggle.setAttribute('aria-label', (open ? toggle.dataset.close : toggle.dataset.open) ?? '');
    header.toggleAttribute('data-open', open);
    panel.hidden = !open;
    document.body.style.overflow = open ? 'hidden' : '';
  };
  toggle.addEventListener('click', () => setOpen(toggle.getAttribute('aria-expanded') !== 'true'));
  panel.querySelectorAll('[data-close-menu]').forEach((link) => link.addEventListener('click', () => setOpen(false)));
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && !panel.hidden) {
      setOpen(false);
      toggle.focus();
    }
  });
  window.matchMedia('(min-width: 861px)').addEventListener('change', (event) => event.matches && setOpen(false));

  // The language menu closes when focus or a click goes elsewhere.
  document.querySelectorAll<HTMLDetailsElement>('[data-menu]').forEach((menu) => {
    document.addEventListener('click', (event) => {
      if (menu.open && !menu.contains(event.target as Node)) menu.open = false;
    });
    menu.addEventListener('keydown', (event) => {
      if (event.key === 'Escape' && menu.open) {
        menu.open = false;
        menu.querySelector('summary')?.focus();
      }
    });
  });
}

/** A language chosen by hand wins over the browser's language on later visits. */
function setUpLanguage(): void {
  document.querySelectorAll<HTMLAnchorElement>('[data-locale-link]').forEach((link) => {
    link.addEventListener('click', () => write(localeKey, link.dataset.localeLink ?? null));
  });
}

export function setUpChrome(): void {
  setUpTheme();
  setUpHeader();
  setUpLanguage();
}
