from datetime import date

from pydantic import BaseModel, Field


class LineItemOut(BaseModel):
    description: str
    amount: float
    quantity: float | None = None


class CategoryOut(BaseModel):
    name: str
    source: str = Field(description="merchant | keyword | fuzzy | none")
    matched: str | None = None
    confidence: float


class ReceiptOut(BaseModel):
    merchant: str | None
    total: float | None
    currency: str
    date: date | None
    category: CategoryOut
    line_items: list[LineItemOut]
    raw_text: str
    needs_review: bool = Field(description="true when total, date or category could not be determined")


class ParseIn(BaseModel):
    text: str = Field(min_length=1, max_length=20_000)
