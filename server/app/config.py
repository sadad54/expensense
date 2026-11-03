from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    ocr_api_key: str = ""
    ocr_url: str = "https://api.ocr.space/parse/image"
    ocr_timeout_seconds: float = 30.0
    ocr_max_bytes: int = 1_000_000  # OCR.space free-tier upload limit

    # "firebase" verifies Firebase ID tokens; "disabled" is for local development only.
    auth_mode: str = "firebase"
    firebase_project_id: str = ""

    max_upload_bytes: int = 10 * 1024 * 1024
    scans_per_minute: int = 10
    cors_origins: list[str] = []


@lru_cache
def get_settings() -> Settings:
    return Settings()
