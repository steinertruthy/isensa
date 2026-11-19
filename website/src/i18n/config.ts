/** The website speaks exactly the languages the macOS app ships (CFBundleLocalizations). */
export const locales = ['en', 'pt-br', 'es', 'fr', 'de', 'it', 'ja', 'ko', 'zh-hans', 'zh-hant'] as const;
export type Locale = (typeof locales)[number];
export const defaultLocale: Locale = 'en';

interface LocaleInfo {
  /** Name of the language in that language. */
  name: string;
  /** BCP 47 tag for `lang`, `hreflang` and `Intl`. */
  tag: string;
  /** Open Graph locale. */
  og: string;
}

export const localeInfo: Record<Locale, LocaleInfo> = {
  en: { name: 'English', tag: 'en', og: 'en_US' },
  'pt-br': { name: 'Português (Brasil)', tag: 'pt-BR', og: 'pt_BR' },
  es: { name: 'Español', tag: 'es', og: 'es_ES' },
  fr: { name: 'Français', tag: 'fr', og: 'fr_FR' },
  de: { name: 'Deutsch', tag: 'de', og: 'de_DE' },
  it: { name: 'Italiano', tag: 'it', og: 'it_IT' },
  ja: { name: '日本語', tag: 'ja', og: 'ja_JP' },
  ko: { name: '한국어', tag: 'ko', og: 'ko_KR' },
  'zh-hans': { name: '简体中文', tag: 'zh-Hans', og: 'zh_CN' },
  'zh-hant': { name: '繁體中文', tag: 'zh-Hant', og: 'zh_TW' },
};

export function isLocale(value: string | undefined): value is Locale {
  return locales.includes(value as Locale);
}

/**
 * Picks the closest supported language for a browser's preference list (`navigator.languages`).
 * Regional variants fall back to their language; Chinese is split by script, inferring it from the
 * region when only a region is given (zh-TW, zh-HK, zh-MO → Traditional).
 *
 * Self-contained on purpose: its source is also inlined into the root page, which redirects first-time
 * visitors before anything renders.
 */
export function matchLocale(
  preferences: readonly string[],
  supported: readonly string[] = locales,
  fallback: string = defaultLocale,
): Locale {
  for (const preference of preferences) {
    const tag = preference.toLowerCase().replace(/_/g, '-');
    if (supported.includes(tag)) return tag as Locale;
    const parts = tag.split('-');
    const language = parts[0];
    if (language === 'zh') {
      const traditional = parts.includes('hant') || parts.some((part) => part === 'tw' || part === 'hk' || part === 'mo');
      return (traditional ? 'zh-hant' : 'zh-hans') as Locale;
    }
    if (language === 'pt') return 'pt-br' as Locale;
    if (supported.includes(language)) return language as Locale;
  }
  return fallback as Locale;
}
