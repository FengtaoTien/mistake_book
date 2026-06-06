from datetime import datetime
from uuid import UUID
from pydantic import BaseModel


class MistakeCreate(BaseModel):
    subject: str
    question_text: str = ""
    answer_text: str = ""
    mistake_reason: str = ""
    difficulty: int = 3
    tags: list[str] = []
    image_url: str = ""
    source: str = ""


class MistakeUpdate(BaseModel):
    subject: str | None = None
    question_text: str | None = None
    answer_text: str | None = None
    mistake_reason: str | None = None
    difficulty: int | None = None
    tags: list[str] | None = None
    correct_count: int | None = None
    is_active: bool | None = None


class MistakeResponse(BaseModel):
    id: UUID
    subject: str
    question_text: str
    answer_text: str
    mistake_reason: str
    difficulty: int
    tags: list[str]
    image_url: str
    source: str
    correct_count: int
    next_review_at: datetime | None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
