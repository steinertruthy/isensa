import { describe, expect, it } from 'vitest';
import { dictionaries } from '../src/i18n';
import { locales, matchLocale } from '../src/i18n/config';

/** Every leaf path of a dictionary, with arrays indexed, so missing or extra keys show up by name. */
function shape(value: unknown, path = ''): string[] {
  if (typeof value === 'string') return [path];
  if (Array.isArray(value)) return value.flatMap((item, index) => shape(item, `${path}[${index}]`));
  return Object.entries(value as Record<string, unknown>).flatMap(([key, child]) => shape(child, path ? `${path}.${key}` : key));
}

function leaves(value: unknown): string[] {
  if (typeof value === 'string') return [value];
  if (Array.isArray(value)) return value.flatMap(leaves);
  return Object.values(value as Record<string, unknown>).flatMap(leaves);
}

describe('translations', () => {
  const reference = shape(dictionaries.en).sort();

  it.each(locales)('%s has exactly the English keys', (locale) => {
    expect(shape(dictionaries[locale]).sort()).toEqual(reference);
  });

  it.each(locales)('%s has no empty text and keeps every placeholder', (locale) => {
    const english = leaves(dictionaries.en);
    leaves(dictionaries[locale]).forEach((text, index) => {
      expect(text.trim().length, `empty text at ${index}`).toBeGreaterThan(0);
      const expected = english[index].match(/\{\w+\}/g)?.sort() ?? [];
      expect(text.match(/\{\w+\}/g)?.sort() ?? [], `placeholders in “${text}”`).toEqual(expected);
    });
  });

  it.each(locales.filter((locale) => locale !== 'en'))('%s is translated, not copied from English', (locale) => {
    const english = leaves(dictionaries.en);
    const same = leaves(dictionaries[locale]).filter((text, index) => text === english[index] && text.length > 24);
    expect(same).toEqual([]);
  });
});

describe('language detection', () => {
  it.each([
    [['pt-BR'], 'pt-br'],
    [['pt-PT'], 'pt-br'],
    [['es-MX', 'en'], 'es'],
    [['fr-CA'], 'fr'],
    [['de-AT'], 'de'],
    [['ja-JP'], 'ja'],
    [['ko-KR'], 'ko'],
    [['zh-CN'], 'zh-hans'],
    [['zh-TW'], 'zh-hant'],
    [['zh-HK'], 'zh-hant'],
    [['zh-Hant-TW'], 'zh-hant'],
    [['zh'], 'zh-hans'],
    [['ru', 'it-IT'], 'it'],
    [['nl'], 'en'],
    [[], 'en'],
  ])('%j → %s', (preferences, expected) => {
    expect(matchLocale(preferences)).toBe(expected);
  });
});
