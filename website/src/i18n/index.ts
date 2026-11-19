import type { Locale } from './config';
import type { Dictionary } from './locales/en';
import en from './locales/en';
import ptBR from './locales/pt-br';
import es from './locales/es';
import fr from './locales/fr';
import de from './locales/de';
import it from './locales/it';
import ja from './locales/ja';
import ko from './locales/ko';
import zhHans from './locales/zh-hans';
import zhHant from './locales/zh-hant';

export const dictionaries: Record<Locale, Dictionary> = {
  en,
  'pt-br': ptBR,
  es,
  fr,
  de,
  it,
  ja,
  ko,
  'zh-hans': zhHans,
  'zh-hant': zhHant,
};

export function translations(locale: Locale): Dictionary {
  return dictionaries[locale];
}

export type { Dictionary };
export * from './config';
