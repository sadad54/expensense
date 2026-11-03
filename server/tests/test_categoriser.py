from app.categoriser import Categoriser


def cat(text, merchant=None):
    return Categoriser.default().categorise(text, merchant=merchant)


def test_known_merchant():
    m = cat("TESCO STORES (M) SDN BHD\nMILK 6.50")
    assert (m.category, m.source, m.matched) == ("Food & Groceries", "merchant", "tesco")


def test_longest_merchant_wins():
    assert cat("WALMART PHARMACY #4411").category == "Health & Personal Care"


def test_whole_words_only():
    # "shell" (petrol) must not fire inside "shellfish"
    m = cat("SEAFOOD HOUSE\nSHELLFISH PLATTER 45.00")
    assert m.category != "Transportation"


def test_keyword_vote():
    m = cat("KEDAI ABC\nRICE 5KG\nCHICKEN\nEGGS\nPANADOL")
    assert (m.category, m.source) == ("Food & Groceries", "keyword")


def test_fuzzy_fallback_handles_ocr_typo():
    m = cat("KEDAI ABC\nSUPERMARKKET")
    assert (m.category, m.source, m.matched) == ("Food & Groceries", "fuzzy", "supermarket")


def test_uncategorised():
    m = cat("XQZ 123\n0000")
    assert (m.category, m.source, m.confidence) == ("Uncategorized", "none", 0.0)
