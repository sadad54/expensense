"""Server-side image preparation: upright, greyscale, contrast, and under the OCR size limit."""
import io

from PIL import Image, ImageEnhance, ImageOps, UnidentifiedImageError

try:  # iPhone photos arrive as HEIC
    from pillow_heif import register_heif_opener

    register_heif_opener()
except ImportError:  # pragma: no cover
    pass


class BadImage(ValueError):
    pass


def prepare_for_ocr(data: bytes, max_bytes: int, width: int = 1600) -> bytes:
    try:
        image = Image.open(io.BytesIO(data))
        image.load()
    except (UnidentifiedImageError, OSError) as exc:
        raise BadImage("not a readable image") from exc
    image = ImageOps.exif_transpose(image).convert("L")  # also drops EXIF (location, device)
    if image.width > width:
        image = image.resize((width, round(image.height * width / image.width)), Image.LANCZOS)
    image = ImageEnhance.Contrast(image).enhance(1.2)

    quality = 85
    while True:
        buf = io.BytesIO()
        image.save(buf, "JPEG", quality=quality, optimize=True)
        if buf.tell() <= max_bytes:
            return buf.getvalue()
        if quality > 55:
            quality -= 10
        elif image.width > 600:
            image = image.resize((int(image.width * 0.85), int(image.height * 0.85)), Image.LANCZOS)
            quality = 80
        else:
            raise BadImage("image too large even after compression")
