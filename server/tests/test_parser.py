from datetime import date

import pytest

from app.parser import extract_date, extract_merchant, extract_total, parse_receipt
from tests.conftest import AEON_RECEIPT


def test_full_receipt():
    r = parse_receipt(AEON_RECEIPT)
    assert r.merchant == "AEON CO. (M) BHD"
    assert r.total == 19.70  # rounded amount actually paid, not 19.71
    assert r.date == date(2018, 12, 25)
    assert r.currency == "MYR"
    assert [(i.description, i.amount, i.quantity) for i in r.line_items] == [
        ("MILO 3IN1 18S 1", 15.90, 1.0), ("GARDENIA BREAD 1", 3.80, 1.0)]


@pytest.mark.parametrize("text,expected", [
    ("SUB-TOTAL 10.00\nTOTAL 10.60\nCASH 20.00\nCHANGE 9.40", 10.60),
    ("Subtotal: RM 8.00\nGrand Total: RM 8.48", 8.48),
    ("TOTAL QTY: 3\nNETT TOTAL 1,234.50", 1234.50),
    ("TOTAL\n45.90\nTHANK YOU", 45.90),  # label and value on separate OCR lines
    ("TOTAL : 4.90\nGST SUMMARY\nTAX CODE % AMOUNT TAX\nTOTAL : 4.60 0.28", 4.90),  # tax table ignored
    ("TOTAL SALES (INCLUSIVE GST) RM 45.34\nROUNDING ADJUSTMENT RM .01\nROUNDING RM 45.35", 45.35),
    ("ITEM A 3.00\nITEM B 7.50\nCASH 20.00\nCHANGE 9.50", 7.50),  # no label: largest non-payment amount
    ("no amounts here", None),
])
def test_total(text, expected):
    assert extract_total(text) == expected


@pytest.mark.parametrize("text,expected", [
    ("DATE: 25/12/2018 8:13:39 PM", date(2018, 12, 25)),
    ("Date 03-01-19", date(2019, 1, 3)),  # day-first, two-digit year
    ("2019-04-07 13:22", date(2019, 4, 7)),
    ("12 MAR 2018", date(2018, 3, 12)),
    ("Jan 5, 2019", date(2019, 1, 5)),
    ("INV 31/02/2018", None),  # impossible date rejected
    ("ref 12/25/2018", date(2018, 12, 25)),  # falls back to month-first when day-first is impossible
])
def test_date(text, expected):
    assert extract_date(text) == expected


def test_labelled_date_wins_over_earlier_date():
    assert extract_date("PROMO VALID TILL 31/12/2019\nDATE: 02/01/2019") == date(2019, 1, 2)


@pytest.mark.parametrize("text,expected", [
    ("99 SPEED MART S/B (519537-X)\nLOT P.T. 2811, JALAN ANGSA,", "99 SPEED MART S/B"),
    ("POPULAR BOOK\nCO. (M) SDN BHD\n(CO. NO. 113825-W)", "POPULAR BOOK CO. (M) SDN BHD"),
    ("TAX INVOICE\nKEDAI RUNCIT AH HOCK\nNO. 12 JALAN 3", "KEDAI RUNCIT AH HOCK"),
    ("THREE STOOGES\n109, SS21/1A,", "THREE STOOGES"),
])
def test_merchant(text, expected):
    assert extract_merchant(text) == expected
