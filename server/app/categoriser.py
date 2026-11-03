"""Three-stage spending categoriser: merchant dictionary, keyword vote, fuzzy fallback.

The tables come from the Flutter app (exported by tools/export_categories.py),
so the server and the app's offline fallback agree. Compared with the original
client-side matcher this version matches whole words only ("shell" no longer
fires on "shellfish"), lets keywords vote instead of taking the first hit, and
fuzzy-matches individual words so OCR typos such as "chiken" still match.
"""
from __future__ import annotations

import json
import re
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

from rapidfuzz import fuzz, process

DATA = Path(__file__).parent / "data" / "categories.json"
UNCATEGORISED = "Uncategorized"
FUZZY_THRESHOLD = 88


@dataclass(frozen=True)
class CategoryMatch:
    category: str
    source: str  # merchant | keyword | fuzzy | none
    matched: str | None
    confidence: float


def _pattern(term: str) -> re.Pattern[str]:
    return re.compile(r"(?<![a-z0-9])" + re.escape(term) + r"(?![a-z0-9])")


class Categoriser:
    def __init__(self, merchants: dict[str, str], keywords: dict[str, list[str]]):
        # Longest merchant names first, so "walmart pharmacy" beats "walmart".
        self._merchants = sorted(((m, c, _pattern(m)) for m, c in merchants.items()), key=lambda t: -len(t[0]))
        self._keywords = [(kw, cat, _pattern(kw)) for cat, kws in keywords.items() for kw in kws]
        self._single_words = {kw: cat for kw, cat, _ in self._keywords if " " not in kw and len(kw) >= 5}

    @classmethod
    @lru_cache(maxsize=1)
    def default(cls) -> "Categoriser":
        data = json.loads(DATA.read_text(encoding="utf-8"))
        return cls(data["merchants"], data["keywords"])

    @property
    def categories(self) -> list[str]:
        return sorted({c for _, c, _ in self._keywords} | {c for _, c, _ in self._merchants})

    def categorise(self, text: str, merchant: str | None = None) -> CategoryMatch:
        lowered = text.lower()
        head = (merchant or "").lower() + "\n" + lowered
        for name, category, pattern in self._merchants:
            if pattern.search(head):
                return CategoryMatch(category, "merchant", name, 0.95)

        votes: dict[str, list[str]] = {}
        for kw, category, pattern in self._keywords:
            if pattern.search(lowered):
                votes.setdefault(category, []).append(kw)
        if votes:
            ranked = sorted(votes.items(), key=lambda kv: (-len(kv[1]), kv[0]))
            winner, hits = ranked[0]
            total_hits = sum(len(v) for v in votes.values())
            return CategoryMatch(winner, "keyword", ", ".join(hits[:5]), round(0.5 + 0.4 * len(hits) / total_hits, 2))

        words = {w for w in re.findall(r"[a-z]{5,}", lowered)}
        best: tuple[str, str, float] | None = None
        for word in words:
            hit = process.extractOne(word, self._single_words.keys(), scorer=fuzz.ratio, score_cutoff=FUZZY_THRESHOLD)
            if hit and (best is None or hit[1] > best[2]):
                best = (self._single_words[hit[0]], hit[0], hit[1])
        if best:
            return CategoryMatch(best[0], "fuzzy", best[1], round(best[2] / 100 * 0.6, 2))
        return CategoryMatch(UNCATEGORISED, "none", None, 0.0)
