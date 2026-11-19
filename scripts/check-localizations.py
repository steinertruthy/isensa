#!/usr/bin/env python3 -I
"""Fails when a tr("…") key used in SensaFeatures — or a String(localized:) key in the app — is
missing a translation for any shipped language in its String Catalog.

Usage: scripts/check-localizations.py [--list-missing LANG] [--dump-keys]
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LANGUAGES = ["pt-BR", "es", "fr", "de", "it", "ja", "ko", "zh-Hans", "zh-Hant"]
TARGETS = [
    (ROOT / "Packages/SensaKit/Sources/SensaFeatures", ROOT / "Packages/SensaKit/Sources/SensaFeatures/Resources/Localizable.xcstrings",
     re.compile(r'\btr\("((?:[^"\\]|\\.)*)"')),
    (ROOT / "App", ROOT / "App/Resources/Localizable.xcstrings",
     re.compile(r'String\(localized: "((?:[^"\\]|\\.)*)"')),
]


def unescape(key):
    return key.encode().decode("unicode_escape").encode("latin-1").decode("utf-8")


def used_keys(sources, pattern):
    keys = set()
    for path in sources.rglob("*.swift"):
        for match in pattern.finditer(path.read_text(encoding="utf-8")):
            keys.add(unescape(match.group(1)))
    return keys


def translated(catalog, language):
    return {
        key for key, entry in catalog["strings"].items()
        if entry.get("localizations", {}).get(language, {}).get("stringUnit", {}).get("value")
    }


def main():
    failures = 0
    for sources, path, pattern in TARGETS:
        catalog = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {"strings": {}}
        keys = used_keys(sources, pattern)
        if "--dump-keys" in sys.argv:
            print(json.dumps(sorted(keys), ensure_ascii=False, indent=1))
            continue
        for language in LANGUAGES:
            missing = sorted(keys - translated(catalog, language))
            if "--list-missing" in sys.argv and sys.argv[sys.argv.index("--list-missing") + 1] == language:
                print(json.dumps(missing, ensure_ascii=False, indent=1))
            for key in missing:
                failures += 1
                if "--list-missing" not in sys.argv:
                    print(f"error: {path.name} [{language}] missing: {key}")
        unused = sorted(set(catalog["strings"]) - keys)
        if unused and "--list-missing" not in sys.argv:
            print(f"note: {len(unused)} unused keys in {path.relative_to(ROOT)}")
    if "--list-missing" in sys.argv or "--dump-keys" in sys.argv:
        return 0
    if failures:
        return 1
    print(f"Localizations OK ({len(LANGUAGES) + 1} languages).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
