import pytest

from app.imaging import BadImage, prepare_for_ocr
from app.ratelimit import RateLimiter
from tests.conftest import jpeg_bytes


def test_prepare_for_ocr_fits_limit():
    out = prepare_for_ocr(jpeg_bytes((4000, 6000)), max_bytes=200_000)
    assert len(out) <= 200_000 and out[:2] == b"\xff\xd8"


def test_prepare_for_ocr_rejects_garbage():
    with pytest.raises(BadImage):
        prepare_for_ocr(b"nope", 1_000_000)


def test_rate_limiter_window():
    now = [0.0]
    rl = RateLimiter(2, 60, clock=lambda: now[0])
    assert rl.allow("a")[0] and rl.allow("a")[0]
    allowed, wait = rl.allow("a")
    assert not allowed and wait == pytest.approx(60)
    assert rl.allow("b")[0]  # other users unaffected
    now[0] = 61
    assert rl.allow("a")[0]
