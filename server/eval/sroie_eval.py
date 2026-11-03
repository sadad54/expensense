"""Evaluate receipt field extraction on SROIE (ICDAR 2019), 626 scanned Malaysian receipts.

SROIE ships the OCR text of every receipt as word boxes plus hand-labelled
company, date and total. This script rebuilds each receipt's text line by line
(the way an OCR API returns it), runs the parser, and scores it against the
labels. It also scores the original client-side regex parser as a baseline.

    git clone --depth 1 https://github.com/zzzDavid/ICDAR-2019-SROIE.git /tmp/sroie
    python eval/sroie_eval.py /tmp/sroie/data [--split dev|test|all] [--json out.json]

Split: receipts are sorted by file name; the first 300 are "dev" (used while
writing the parser) and the remaining 326 are "test" (held out, reported).
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
from datetime import date, datetime
from pathlib import Path

from rapidfuzz import fuzz

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.categoriser import Categoriser  # noqa: E402
from app.parser import parse_receipt  # noqa: E402

DEV_SIZE = 300


def rebuild_text(box_csv: Path) -> str:
    """Group OCR word boxes into lines by vertical overlap, left to right."""
    words = []
    for raw in box_csv.read_text(encoding="utf-8", errors="ignore").splitlines():
        parts = raw.split(",", 8)
        if len(parts) < 9:
            continue
        xs, ys = [int(parts[i]) for i in (0, 2, 4, 6)], [int(parts[i]) for i in (1, 3, 5, 7)]
        words.append((min(ys), max(ys), min(xs), parts[8].strip()))
    words.sort(key=lambda w: (w[0] + w[1]) / 2)
    lines: list[list[tuple[int, int, int, str]]] = []
    for w in words:
        mid = (w[0] + w[1]) / 2
        if lines:
            top = min(x[0] for x in lines[-1])
            bottom = max(x[1] for x in lines[-1])
            if top <= mid <= bottom:
                lines[-1].append(w)
                continue
        lines.append([w])
    return "\n".join(" ".join(t for *_, t in sorted(line, key=lambda x: x[2])) for line in lines)


GOLD_DATE_FORMATS = ["%d/%m/%Y", "%d/%m/%y", "%d-%m-%Y", "%d-%m-%y", "%d.%m.%Y", "%d.%m.%y", "%Y-%m-%d", "%Y/%m/%d",
                     "%d %b %Y", "%d-%b-%Y", "%d-%b-%y", "%d %B %Y", "%b %d, %Y", "%d %b %y", "%d%b%Y", "%d/%b/%Y"]


def gold_date(raw: str) -> date | None:
    cleaned = re.sub(r"\s+", " ", raw.strip()).title()
    for fmt in GOLD_DATE_FORMATS:
        try:
            return datetime.strptime(cleaned, fmt.replace("%b", "%b").replace("%B", "%B")).date()
        except ValueError:
            continue
    return None


def norm_name(s: str) -> str:
    return re.sub(r"[^A-Z0-9]", "", s.upper())


def baseline(text: str) -> tuple[float | None, date | None, str | None]:
    """The parser the app shipped before the API (lib/util/receipt_parser.dart), ported 1:1.

    Dart's DateTime.tryParse only accepts ISO-8601, so a day-first date such as
    25/12/2018 failed to parse and the app silently saved today's date instead.
    """
    m = re.search(r"(total|amount|paid)[^\d]*([\d,]+\.\d{2})", text, re.I)
    total = float(m.group(2).replace(",", "")) if m else None
    d = re.search(r"\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b", text)
    parsed = None
    if d:
        try:
            parsed = datetime.fromisoformat(d.group(0)).date()
        except ValueError:
            parsed = None
    lines = [ln.strip() for ln in text.split("\n") if ln.strip()]
    return total, parsed, lines[0] if lines else None


def score(data_dir: Path, split: str) -> dict:
    keys = sorted((data_dir / "key").glob("*.json"))
    if split == "dev":
        keys = keys[:DEV_SIZE]
    elif split == "test":
        keys = keys[DEV_SIZE:]
    cat = Categoriser.default()
    counts = {k: 0 for k in ("n", "total_n", "date_n", "total", "date", "merchant", "base_total", "base_date", "base_merchant",
                             "categorised", "any_field_ok")}
    misses: list[dict] = []
    elapsed = 0.0
    for key_path in keys:
        gold = json.loads(key_path.read_text(encoding="utf-8", errors="ignore"))
        text = rebuild_text(data_dir / "box" / (key_path.stem + ".csv"))
        start = time.perf_counter()
        parsed = parse_receipt(text)
        category = cat.categorise(text, merchant=parsed.merchant)
        elapsed += time.perf_counter() - start
        counts["n"] += 1
        gold_match = re.search(r"\d[\d,]*(?:\.\d+)?", gold.get("total", ""))
        gold_total = float(gold_match.group(0).replace(",", "")) if gold_match else None
        counts["total_n"] += gold_total is not None
        ok_total = gold_total is not None and parsed.total is not None and abs(parsed.total - gold_total) < 0.005
        counts["total"] += ok_total
        g_date = gold_date(gold.get("date", ""))
        if g_date:
            counts["date_n"] += 1
            counts["date"] += parsed.date == g_date
        ok_merchant = parsed.merchant is not None and fuzz.ratio(norm_name(parsed.merchant), norm_name(gold.get("company", ""))) >= 90
        counts["merchant"] += ok_merchant
        counts["categorised"] += category.category != "Uncategorized"
        b_total, b_date, b_merchant = baseline(text)
        counts["base_total"] += gold_total is not None and b_total is not None and abs(b_total - gold_total) < 0.005
        counts["base_date"] += bool(g_date and b_date == g_date)
        counts["base_merchant"] += b_merchant is not None and fuzz.ratio(norm_name(b_merchant), norm_name(gold.get("company", ""))) >= 90
        if gold_total is not None and not ok_total:
            misses.append({"id": key_path.stem, "gold": gold.get("total"), "got": parsed.total, "merchant": parsed.merchant, "gold_company": gold.get("company")})
    n, dn = counts["n"], max(counts["date_n"], 1)
    return {
        "split": split,
        "receipts": n,
        "receipts_with_parseable_gold_date": counts["date_n"],
        "receipts_with_gold_total": counts["total_n"],
        "total_accuracy": round(counts["total"] / counts["total_n"], 4),
        "date_accuracy": round(counts["date"] / dn, 4),
        "merchant_accuracy": round(counts["merchant"] / n, 4),
        "category_coverage": round(counts["categorised"] / n, 4),
        "baseline_total_accuracy": round(counts["base_total"] / counts["total_n"], 4),
        "baseline_date_accuracy": round(counts["base_date"] / dn, 4),
        "baseline_merchant_accuracy": round(counts["base_merchant"] / n, 4),
        "mean_parse_ms": round(1000 * elapsed / n, 3),
        "total_misses": misses,
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("data_dir", type=Path, help="SROIE data/ folder containing box/ and key/")
    ap.add_argument("--split", choices=["dev", "test", "all"], default="test")
    ap.add_argument("--json", type=Path)
    ap.add_argument("--show-misses", type=int, default=0)
    args = ap.parse_args()
    result = score(args.data_dir, args.split)
    misses = result.pop("total_misses")
    print(json.dumps(result, indent=2))
    for m in misses[: args.show_misses]:
        print(m)
    if args.json:
        args.json.write_text(json.dumps(result, indent=2) + "\n")


if __name__ == "__main__":
    main()
