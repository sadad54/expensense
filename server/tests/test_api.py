from tests.conftest import AEON_RECEIPT, jpeg_bytes, ocr_transport


def test_health(client_factory):
    assert client_factory().get("/healthz").json() == {"status": "ok"}


def test_scan_happy_path_keeps_key_server_side(client_factory):
    transport, seen = ocr_transport()
    resp = client_factory(transport).post("/v1/receipts/scan", files={"image": ("r.jpg", jpeg_bytes((3000, 4000)), "image/jpeg")})
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["total"] == 19.70 and body["date"] == "2018-12-25" and body["currency"] == "MYR"
    assert body["category"]["name"] == "Food & Groceries" and body["category"]["source"] == "merchant"
    assert body["needs_review"] is False
    assert seen["apikey"] == "server-key"
    assert seen["size"] < 1_100_000  # image re-encoded under the OCR limit (plus multipart overhead)
    assert resp.headers["x-request-id"]


def test_parse_text_endpoint(client_factory):
    resp = client_factory().post("/v1/receipts/parse", json={"text": AEON_RECEIPT})
    assert resp.status_code == 200
    assert resp.json()["merchant"] == "AEON CO. (M) BHD"


def test_needs_review_when_fields_missing(client_factory):
    resp = client_factory().post("/v1/receipts/parse", json={"text": "XQZ\nhello"})
    assert resp.json()["needs_review"] is True


def test_rejects_non_image(client_factory):
    transport, _ = ocr_transport()
    resp = client_factory(transport).post("/v1/receipts/scan", files={"image": ("a.pdf", b"%PDF", "application/pdf")})
    assert resp.status_code == 415


def test_rejects_corrupt_image(client_factory):
    transport, _ = ocr_transport()
    resp = client_factory(transport).post("/v1/receipts/scan", files={"image": ("a.jpg", b"not really", "image/jpeg")})
    assert resp.status_code == 422


def test_ocr_failure_maps_to_502(client_factory):
    transport, _ = ocr_transport(errored=True)
    resp = client_factory(transport).post("/v1/receipts/scan", files={"image": ("r.jpg", jpeg_bytes(), "image/jpeg")})
    assert resp.status_code == 502


def test_rate_limited_per_user(client_factory):
    transport, _ = ocr_transport()
    client = client_factory(transport, limit=2)
    codes = [client.post("/v1/receipts/scan", files={"image": ("r.jpg", jpeg_bytes(), "image/jpeg")}).status_code
             for _ in range(3)]
    assert codes == [200, 200, 429]


def test_requires_bearer_token(client_factory):
    client = client_factory(user=None)
    assert client.get("/v1/categories").status_code == 401
    assert client.get("/v1/categories", headers={"Authorization": "Bearer junk"}).status_code == 401


def test_categories(client_factory):
    names = client_factory().get("/v1/categories").json()["categories"]
    assert "Food & Groceries" in names and "Transportation" in names
