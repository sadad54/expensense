"""Turn raw receipt OCR text into structured fields.

Tuned for Malaysian receipts: amounts in RM, day-first dates, and company names
ending in "SDN BHD" and similar. Everything here is pure functions over text, so
it is unit-tested directly and evaluated offline on the SROIE receipts dataset
(see eval/).
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import date
from typing import Optional

MONEY = re.compile(r"(?<![\d.,])(?:RM\s*)?(\d{1,3}(?:,\d{3})+|\d*)\s?[.,](\d{2})(?![\d%])", re.I)
# Tax breakdown tables repeat the word "total" with net and tax columns; ignore them.
SUMMARY_START = re.compile(r"(gst|sst|tax)\s*summary|tax\s*code\s*%|summary\s*of\s*tax", re.I)
ROUNDING = re.compile(r"round(?:ing)?\s*(?:adj|adjustment)|\badj(?:ustment)?\b.*round|^round(?:ing)?\b", re.I)

# Labels that introduce the amount the customer actually paid, strongest first.
# Lower index wins; within one rank the last occurrence wins (totals come last).
TOTAL_LABELS: list[re.Pattern[str]] = [
    re.compile(p, re.I)
    for p in (
        r"round(?:ed|ing)?\s*d?\s*total|total\s*(?:\(rm\)\s*)?round(?:ed|ing)|nett?\s*total\s*round",
        r"grand\s*total",
        r"total\s*(?:amount\s*)?(?:incl|inclusive|include)|total\s*(?:amount\s*)?payable|amount\s*payable",
        r"nett?\s*total|total\s*nett?|net\s*amount|nett?\s*amt",
        r"total\s*(?:amount|amt)|amount\s*due|balance\s*due|total\s*due|total\s*sales",
        r"(?<!sub)(?<!sub\s)(?<!sub-)\btotal\b",
    )
]
# Lines that contain "total" but are not the amount paid.
NOT_TOTAL = re.compile(
    r"sub\s*-?\s*total|total\s*(?:qty|quantity|item|items|disc|discount|savings?|tax|gst|sst|sr|zr|excl|exclusive|before|saving)"
    r"|(?:gst|sst|tax|qty|items?)\s*total|total\s*(?:no\.?|number)\s*of",
    re.I,
)
PAYMENT_LINE = re.compile(r"\b(cash|change|tender(?:ed)?|visa|master\s*card|mastercard|debit|credit|card|paid|payment|balance|rounding|round\s*adj|adjustment)\b", re.I)
NON_ITEM = re.compile(
    r"total|tax|gst|sst|service\s*charge|svc|rounding|round|cash|change|tender|visa|master|debit|credit|card|discount"
    r"|balance|paid|payment|amount|subtotal|deposit|invoice|receipt|date|time|tel\b|fax|cashier|table|pax|member|qty\s*$",
    re.I,
)
COMPANY_HINT = re.compile(
    r"(sdn\.?\s*bhd|\bbhd\b|berhad|\bs/b\b|enterprise|trading|restaurant|restoran|\bcafe\b|bistro|\bpub\b|kedai|store|"
    r"\bmart\b|hardware|stationery|bakery|pharmacy|farmasi|\bplt\b|company|\bco\b\.?|corporation|marketing|services|"
    r"supermarket|hypermarket|pasaraya|pasar|perniagaan|food|industries|electrical|confectionery)",
    re.I,
)
# A line that is only a legal suffix belongs to the name on the line above it.
SUFFIX_ONLY = re.compile(r"^[\W\d]*(?:[a-z]+\)\s*)?(?:(?:restaurant|co\.?\s*\(m\)|\(m\))\s*)?(?:sdn\.?\s*bhd|bhd|berhad|s/b)\b", re.I)
REG_NUMBER = re.compile(r"\(?\s*(?:co\.?\s*(?:reg\.?\s*)?no\.?\s*:?\s*)?\d{4,}-?[a-z]\s*\)?|\(\s*\)", re.I)
ADDRESS = re.compile(r"\b(jalan|jln|lot|taman|no\.?\s*\d|lorong|persiaran|bandar|seksyen|kuala lumpur|selangor|johor|\d{5})\b", re.I)
NOISE_HEADER = re.compile(
    r"^(tax\s*invoice|invoice|receipt|official\s*receipt|cash\s*(?:bill|sale|receipt)|simplified|welcome|thank|tq\b|tel|fax|gst|"
    r"co\.?\s*(?:reg|no)|company\s*reg|roc|br\s*no|\(?\s*co\.?\s*no|dimiliki|owned|\d+$)",
    re.I,
)

MONTHS = {m: i for i, m in enumerate(
    ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"], start=1)}
DATE_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"\b(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})\b"), "ymd"),
    (re.compile(r"\b(\d{1,2})\s*[/\-.]\s*(\d{1,2})\s*[/\-.]\s*(\d{4}|\d{2})\b"), "dmy"),
    (re.compile(r"\b(\d{1,2})[\s\-/.]*([A-Za-z]{3,9})[\s\-/.,]*(\d{4}|\d{2})\b"), "d_mon_y"),
    (re.compile(r"\b([A-Za-z]{3,9})[\s\-.]*(\d{1,2}),?[\s\-.]*(\d{4})\b"), "mon_d_y"),
]


@dataclass
class LineItem:
    description: str
    amount: float
    quantity: Optional[float] = None


@dataclass
class ParsedReceipt:
    merchant: Optional[str]
    total: Optional[float]
    date: Optional[date]
    currency: str = "MYR"
    line_items: list[LineItem] = field(default_factory=list)


def _to_float(whole: str, cents: str) -> float:
    return float((whole.replace(",", "") or "0") + "." + cents)


def amounts_in(line: str) -> list[float]:
    return [_to_float(w, c) for w, c in MONEY.findall(line)]


def _lines(text: str) -> list[str]:
    return [ln.strip() for ln in text.replace("\r", "\n").split("\n") if ln.strip()]


def _apply_rounding(lines: list[str], index: int, total: float) -> float:
    """If a rounding adjustment follows the total, return the rounded amount actually paid."""
    for j in range(index + 1, min(index + 4, len(lines))):
        if not ROUNDING.search(lines[j]):
            continue
        adjustments = amounts_in(lines[j])
        if not adjustments:
            continue
        adj = adjustments[0]
        targets = {round(total + adj, 2), round(total - adj, 2)}
        for k in range(j, min(j + 3, len(lines))):
            for value in amounts_in(lines[k]):
                if round(value, 2) in targets and value != adj:
                    return round(value, 2)
    return total


def extract_total(text: str) -> Optional[float]:
    lines = _lines(text)
    for i, line in enumerate(lines):
        if SUMMARY_START.search(line) and i > 0:
            lines = lines[:i]
            break
    best: Optional[tuple[int, int, float]] = None  # (rank, line index, value)
    for i, line in enumerate(lines):
        if NOT_TOTAL.search(line):
            continue
        for rank, label in enumerate(TOTAL_LABELS):
            if not label.search(line):
                continue
            after = line[label.search(line).end():]
            values = amounts_in(after) or amounts_in(line)
            if not values and i + 1 < len(lines) and not TOTAL_LABELS[-1].search(lines[i + 1]):
                values = amounts_in(lines[i + 1])  # label and value split across lines
            if values and values[-1] > 0:
                candidate = (rank, i, values[-1])
                if best is None or rank < best[0] or (rank == best[0] and i > best[1]):
                    best = candidate
            break
    if best:
        return _apply_rounding(lines, best[1], best[2])
    # No label survived OCR: take the largest amount outside payment lines.
    pool = [v for ln in lines if not PAYMENT_LINE.search(ln) for v in amounts_in(ln)]
    return max(pool) if pool else None


def _valid(y: int, m: int, d: int) -> Optional[date]:
    if y < 100:
        y += 2000
    try:
        found = date(y, m, d)
    except ValueError:
        return None
    return found if 2000 <= found.year <= 2100 else None


def _dates_in(line: str) -> list[date]:
    out: list[date] = []
    for pattern, kind in DATE_PATTERNS:
        for g in pattern.findall(line):
            if kind == "ymd":
                d = _valid(int(g[0]), int(g[1]), int(g[2]))
            elif kind == "dmy":
                d = _valid(int(g[2]), int(g[1]), int(g[0])) or _valid(int(g[2]), int(g[0]), int(g[1]))
            elif kind == "d_mon_y":
                month = MONTHS.get(g[1][:3].lower())
                d = _valid(int(g[2]), month, int(g[0])) if month else None
            else:
                month = MONTHS.get(g[0][:3].lower())
                d = _valid(int(g[2]), month, int(g[1])) if month else None
            if d:
                out.append(d)
    return out


def extract_date(text: str) -> Optional[date]:
    lines = _lines(text)
    labelled = [d for ln in lines if re.search(r"date|tarikh|dt\b", ln, re.I) for d in _dates_in(ln)]
    if labelled:
        return labelled[0]
    for ln in lines:
        found = _dates_in(ln)
        if found:
            return found[0]
    return None


def _clean_name(name: str) -> str:
    name = REG_NUMBER.sub(" ", name)
    return re.sub(r"\s+", " ", name).strip(" .,:-")


def extract_merchant(text: str) -> Optional[str]:
    lines = _lines(text)[:8]
    for i, ln in enumerate(lines):
        if not COMPANY_HINT.search(ln) or NOISE_HEADER.search(ln) or ADDRESS.search(ln):
            continue
        name = ln
        if SUFFIX_ONLY.match(ln) and i > 0 and not ADDRESS.search(lines[i - 1]):
            name = lines[i - 1] + " " + ln
        elif i + 1 < len(lines) and (ln.rstrip().endswith(("&", "(", ",")) or ln.count("(") > ln.count(")")
                                     or SUFFIX_ONLY.match(lines[i + 1])):
            name = ln + " " + lines[i + 1]
        cleaned = _clean_name(name)
        if sum(ch.isalpha() for ch in cleaned) >= 3:
            return cleaned
    for ln in lines:
        letters = sum(ch.isalpha() for ch in ln)
        if letters >= 3 and letters / len(ln) > 0.5 and not NOISE_HEADER.search(ln) and not ADDRESS.search(ln):
            return _clean_name(ln)
    return None


def extract_line_items(text: str) -> list[LineItem]:
    items: list[LineItem] = []
    for ln in _lines(text):
        if NON_ITEM.search(ln):
            continue
        values = list(MONEY.finditer(ln))
        if not values:
            continue
        description = MONEY.sub("", ln[: values[0].start()]).strip(" :*-xX@")
        description = re.sub(r"^\d{6,}\s*", "", description)  # leading barcode
        if sum(ch.isalpha() for ch in description) < 3:
            continue
        qty_match = re.search(r"(?:^|\s)(\d+(?:\.\d+)?)\s*(?:x|pcs?|qty|@)\b", ln, re.I)
        last = values[-1]
        items.append(LineItem(
            description=re.sub(r"\s+", " ", description),
            amount=_to_float(last.group(1), last.group(2)),
            quantity=float(qty_match.group(1)) if qty_match else None,
        ))
    return items


def parse_receipt(text: str) -> ParsedReceipt:
    return ParsedReceipt(
        merchant=extract_merchant(text),
        total=extract_total(text),
        date=extract_date(text),
        line_items=extract_line_items(text),
    )
