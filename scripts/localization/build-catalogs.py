#!/usr/bin/env python3 -I
"""Builds Sensa's String Catalogs from numbered translation files.

Inputs (this folder):
  keys.json          — ordered [["F"|"A", english key], ...] (F = interface, A = app menus)
  <language>.txt     — one "number|translation" line per key, for every shipped language

Validation (fails the build): every number present, no empty values, and placeholder
counts identical to the English source (positional %1$@ forms are allowed).

  --check   verify the committed catalogs match the translation files, without writing.
"""
import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
LANGUAGES = ["pt-BR", "es", "fr", "de", "it", "ja", "ko", "zh-Hans", "zh-Hant"]
OUTPUTS = {
    "F": ROOT / "Packages/SensaKit/Sources/SensaFeatures/Resources/Localizable.xcstrings",
    "A": ROOT / "App/Resources/Localizable.xcstrings",
}
PLACEHOLDER = re.compile(r"%(?:\d+\$)?@")


def load(language, count):
    values = {}
    for number, line in enumerate((HERE / f"{language}.txt").read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        index, _, text = line.partition("|")
        if not index.strip().isdigit():
            raise SystemExit(f"{language}.txt line {number}: expected 'number|text'")
        values[int(index)] = text.strip()
    missing = [i for i in range(count) if not values.get(i)]
    if missing:
        raise SystemExit(f"{language}: missing translations for {missing[:20]}{'…' if len(missing) > 20 else ''}")
    return values


def main():
    keys = json.loads((HERE / "keys.json").read_text(encoding="utf-8"))
    tables = {language: load(language, len(keys)) for language in LANGUAGES}
    errors = []
    for index, (_, key) in enumerate(keys):
        expected = len(PLACEHOLDER.findall(key))
        for language in LANGUAGES:
            if len(PLACEHOLDER.findall(tables[language][index])) != expected:
                errors.append(f"{language} #{index} placeholders differ: {key!r} → {tables[language][index]!r}")
    if errors:
        raise SystemExit("\n".join(errors))
    check = "--check" in sys.argv
    stale = []
    for target, path in OUTPUTS.items():
        strings = {}
        for index, (kind, key) in enumerate(keys):
            if kind != target:
                continue
            strings[key] = {"localizations": {
                language: {"stringUnit": {"state": "translated", "value": tables[language][index]}} for language in LANGUAGES
            }}
        catalog = {"sourceLanguage": "en", "version": "1.0", "strings": dict(sorted(strings.items()))}
        content = json.dumps(catalog, ensure_ascii=False, indent=2) + "\n"
        if check:
            if not path.exists() or path.read_text(encoding="utf-8") != content:
                stale.append(str(path.relative_to(ROOT)))
            continue
        path.write_text(content, encoding="utf-8")
        print(f"wrote {path.relative_to(ROOT)} ({len(strings)} keys × {len(LANGUAGES)} languages)")
    if stale:
        raise SystemExit("error: out of date, run scripts/localization/build-catalogs.py: " + ", ".join(stale))


if __name__ == "__main__":
    sys.exit(main())
