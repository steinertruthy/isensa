#!/usr/bin/env python3 -I
"""Fails when a tr("…") key used in SensaFeatures has no pt-BR translation in the String Catalog.

Usage: scripts/check-localizations.py [--list-missing]
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCES = ROOT / "Packages/SensaKit/Sources/SensaFeatures"
CATALOG = SOURCES / "Resources/Localizable.xcstrings"
PATTERN = re.compile(r'\btr\("((?:[^"\\]|\\.)*)"')


def used_keys():
    keys = set()
    for path in SOURCES.rglob("*.swift"):
        for match in PATTERN.finditer(path.read_text(encoding="utf-8")):
            keys.add(match.group(1).encode().decode("unicode_escape").encode("latin-1").decode("utf-8"))
    return keys


def main():
    catalog = json.loads(CATALOG.read_text(encoding="utf-8")) if CATALOG.exists() else {"strings": {}}
    translated = {
        key for key, entry in catalog["strings"].items()
        if entry.get("localizations", {}).get("pt-BR", {}).get("stringUnit", {}).get("value")
    }
    missing = sorted(used_keys() - translated)
    if "--list-missing" in sys.argv:
        print(json.dumps(missing, ensure_ascii=False, indent=1))
        return 0
    if missing:
        for key in missing:
            print(f"error: missing pt-BR translation: {key}")
        return 1
    print(f"Localizations OK ({len(translated)} keys).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
