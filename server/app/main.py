"""ExpenSense receipt API.

POST /v1/receipts/scan   image -> OCR -> parsed, categorised receipt
POST /v1/receipts/parse  OCR text -> parsed, categorised receipt (no OCR call)
GET  /v1/categories      the spending categories the categoriser can assign
GET  /healthz            liveness
"""
import logging
import time
import uuid

from fastapi import Depends, FastAPI, File, HTTPException, Request, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware

from .auth import User, current_user
from .categoriser import UNCATEGORISED, Categoriser
from .config import Settings, get_settings
from .imaging import BadImage, prepare_for_ocr
from .ocr import OcrClient, OcrError
from .parser import parse_receipt
from .ratelimit import RateLimiter
from .schemas import CategoryOut, LineItemOut, ParseIn, ReceiptOut

log = logging.getLogger("expensense")
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

settings = get_settings()
app = FastAPI(title="ExpenSense API", version="1.0.0")
if settings.cors_origins:
    app.add_middleware(CORSMiddleware, allow_origins=settings.cors_origins, allow_methods=["*"], allow_headers=["*"])

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"}
_limiter = RateLimiter(settings.scans_per_minute)


def get_ocr(s: Settings = Depends(get_settings)) -> OcrClient:
    return OcrClient(s.ocr_url, s.ocr_api_key, s.ocr_timeout_seconds)


def get_limiter() -> RateLimiter:
    return _limiter


@app.middleware("http")
async def request_log(request: Request, call_next):
    request_id = request.headers.get("x-request-id") or uuid.uuid4().hex[:12]
    start = time.perf_counter()
    response = await call_next(request)
    response.headers["x-request-id"] = request_id
    log.info("%s %s %s %.1fms id=%s", request.method, request.url.path, response.status_code,
             1000 * (time.perf_counter() - start), request_id)
    return response


def build_receipt(text: str) -> ReceiptOut:
    parsed = parse_receipt(text)
    match = Categoriser.default().categorise(text, merchant=parsed.merchant)
    return ReceiptOut(
        merchant=parsed.merchant,
        total=parsed.total,
        currency=parsed.currency,
        date=parsed.date,
        category=CategoryOut(name=match.category, source=match.source, matched=match.matched, confidence=match.confidence),
        line_items=[LineItemOut(**vars(i)) for i in parsed.line_items],
        raw_text=text,
        needs_review=parsed.total is None or parsed.date is None or match.category == UNCATEGORISED,
    )


@app.get("/healthz")
def healthz() -> dict:
    return {"status": "ok"}


@app.get("/v1/categories")
def categories(_: User = Depends(current_user)) -> dict:
    return {"categories": Categoriser.default().categories}


@app.post("/v1/receipts/parse", response_model=ReceiptOut)
def parse_text(body: ParseIn, _: User = Depends(current_user)) -> ReceiptOut:
    return build_receipt(body.text)


@app.post("/v1/receipts/scan", response_model=ReceiptOut)
async def scan(
    image: UploadFile = File(...),
    user: User = Depends(current_user),
    ocr: OcrClient = Depends(get_ocr),
    limiter: RateLimiter = Depends(get_limiter),
    s: Settings = Depends(get_settings),
) -> ReceiptOut:
    allowed, retry_after = limiter.allow(user.uid)
    if not allowed:
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, "scan limit reached, try again shortly",
                            {"Retry-After": str(max(1, round(retry_after)))})
    if image.content_type not in ALLOWED_TYPES:
        raise HTTPException(status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, "upload a JPEG, PNG, WebP or HEIC image")
    data = await image.read(s.max_upload_bytes + 1)
    if len(data) > s.max_upload_bytes:
        raise HTTPException(status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, "image is larger than 10 MB")
    try:
        jpeg = prepare_for_ocr(data, s.ocr_max_bytes)
    except BadImage as exc:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, str(exc))
    try:
        text = await ocr.read_text(jpeg)
    except OcrError as exc:
        log.warning("ocr failed uid=%s: %s", user.uid, exc)
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "could not read the receipt, try a clearer photo")
    return build_receipt(text)
