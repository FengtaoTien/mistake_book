from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.services import review as review_service

router = APIRouter(prefix="/reviews", tags=["reviews"])
USER_ID = "default-user"


@router.get("/due")
async def due_mistakes(db: AsyncSession = Depends(get_db)):
    mistakes = await review_service.get_due_mistakes(db, USER_ID)
    return [
        {
            "id": str(m.id),
            "subject": m.subject,
            "question_text": m.question_text,
            "answer_text": m.answer_text,
            "difficulty": m.difficulty,
            "tags": m.tags,
            "correct_count": m.correct_count,
            "repetitions": m.repetitions,
            "ef": m.ef,
            "interval_days": m.interval_days,
        }
        for m in mistakes
    ]


@router.post("/{mistake_id}/review")
async def review(mistake_id: UUID, quality: int, db: AsyncSession = Depends(get_db)):
    if quality < 0 or quality > 5:
        raise HTTPException(status_code=400, detail="Quality must be 0-5")
    mistake = await review_service.review_mistake(db, mistake_id, quality)
    if not mistake:
        raise HTTPException(status_code=404, detail="Mistake not found")
    return {
        "id": str(mistake.id),
        "next_review_at": mistake.next_review_at.isoformat() if mistake.next_review_at else None,
        "repetitions": mistake.repetitions,
        "interval_days": mistake.interval_days,
        "ef": mistake.ef,
        "correct_count": mistake.correct_count,
    }
