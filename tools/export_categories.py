"""Export the Flutter app's merchant and keyword tables to JSON for the API.

The Dart files in lib/util/ stay the source of truth, so the app's offline
fallback and the server categorise receipts the same way.

    python tools/export_categories.py
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MATCHER = ROOT / "lib/util/category_hybrid_matcher.dart"
KEYWORDS = ROOT / "lib/util/category_keywords.dart"
OUT = ROOT / "server/app/data/categories.json"


def _body(source: str, name: str) -> str:
    match = re.search(name + r"\s*=\s*\{(.*?)\n\};", source, re.S)
    if not match:
        raise SystemExit(f"could not find {name}")
    return re.sub(r"//[^\n]*", "", match.group(1))


def main() -> None:
    merchants: dict[str, str] = {}
    for key, value in re.findall(r'"([^"]+)"\s*:\s*"([^"]+)"', _body(MATCHER.read_text(), "merchantToCategory")):
        merchants.setdefault(key.lower(), value)

    keywords: dict[str, list[str]] = {}
    body = _body(KEYWORDS.read_text(), "categoryKeywords")
    for category, items in re.findall(r'"([^"]+)"\s*:\s*\[(.*?)\]', body, re.S):
        seen: list[str] = []
        for word in re.findall(r'"([^"]+)"', items):
            if word.lower() not in seen:
                seen.append(word.lower())
        keywords[category] = seen

    OUT.write_text(json.dumps({"merchants": merchants, "keywords": keywords}, indent=2, ensure_ascii=False) + "\n")
    print(f"{len(merchants)} merchants, {sum(map(len, keywords.values()))} keywords, {len(keywords)} categories -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
