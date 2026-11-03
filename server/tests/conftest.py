import io
import sys
from pathlib import Path

import httpx
import pytest
from fastapi.testclient import TestClient
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import main  # noqa: E402
from app.auth import User, current_user  # noqa: E402
from app.ocr import OcrClient  # noqa: E402
from app.ratelimit import RateLimiter  # noqa: E402

AEON_RECEIPT = """AEON CO. (M) BHD (126926-H)
3RD FLR, AEON TAMAN MALURI SC
JLN JEJAKA, TAMAN MALURI
CHERAS, 55100 KUALA LUMPUR
TAX INVOICE
DATE: 25/12/2018 8:13 PM
MILO 3IN1 18S 1 x 15.90 15.90
GARDENIA BREAD 1 x 3.80 3.80
SUB-TOTAL : 19.70
TOTAL INCL GST : 19.71
ROUNDING ADJ -0.01
RM 19.70
CASH RM 50.00
CHANGE RM 30.30
GST SUMMARY AMOUNT TAX
TOTAL : 18.59 1.12
"""


def jpeg_bytes(size=(800, 1200)) -> bytes:
    buf = io.BytesIO()
    Image.new("RGB", size, "white").save(buf, "JPEG")
    return buf.getvalue()


def ocr_transport(text: str = AEON_RECEIPT, status: int = 200, errored: bool = False):
    seen: dict = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen["apikey"] = request.headers.get("apikey")
        seen["size"] = len(request.content)
        body = {"IsErroredOnProcessing": errored, "ParsedResults": [] if errored else [{"ParsedText": text}],
                "ErrorMessage": ["E301: bad image"] if errored else None}
        return httpx.Response(status, json=body)

    return httpx.MockTransport(handler), seen


@pytest.fixture
def client_factory():
    def make(transport=None, limit: int = 100, user: User | None = User(uid="u1")):
        app = main.app
        app.dependency_overrides.clear()
        if user is not None:
            app.dependency_overrides[current_user] = lambda: user
        if transport is not None:
            app.dependency_overrides[main.get_ocr] = lambda: OcrClient("https://ocr.test/parse", "server-key", 5, transport)
        limiter = RateLimiter(limit)
        app.dependency_overrides[main.get_limiter] = lambda: limiter
        return TestClient(app)

    yield make
    main.app.dependency_overrides.clear()
