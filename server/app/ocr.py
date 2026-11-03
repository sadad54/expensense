"""OCR.space client. The API key lives only on the server."""
import httpx


class OcrError(RuntimeError):
    pass


class OcrClient:
    def __init__(self, url: str, api_key: str, timeout: float, transport: httpx.AsyncBaseTransport | None = None):
        self._url, self._key, self._timeout, self._transport = url, api_key, timeout, transport

    async def read_text(self, jpeg: bytes) -> str:
        if not self._key:
            raise OcrError("OCR is not configured on the server")
        form = {"language": "eng", "OCREngine": "2", "scale": "true", "isTable": "true", "detectOrientation": "true"}
        async with httpx.AsyncClient(timeout=self._timeout, transport=self._transport) as client:
            try:
                resp = await client.post(self._url, data=form, headers={"apikey": self._key},
                                         files={"file": ("receipt.jpg", jpeg, "image/jpeg")})
            except httpx.HTTPError as exc:
                raise OcrError(f"OCR request failed: {exc.__class__.__name__}") from exc
        if resp.status_code != 200:
            raise OcrError(f"OCR provider returned HTTP {resp.status_code}")
        body = resp.json()
        if body.get("IsErroredOnProcessing") or not body.get("ParsedResults"):
            message = body.get("ErrorMessage") or "no text found"
            raise OcrError(message[0] if isinstance(message, list) else str(message))
        return "\n".join(r.get("ParsedText", "") for r in body["ParsedResults"]).strip()
