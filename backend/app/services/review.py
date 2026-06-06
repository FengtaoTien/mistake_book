from datetime import datetime, timedelta
from uuid import UUID
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.mistake import Mistake


def _sm2(quality: int, repetitions: int, ef: float, interval: int) -> tuple[int, float, int]:
    """SM-2 algorithm. quality: 0-5."""
    if quality < 3:
        return 0, max(1.3, ef - 0.2), 1
    ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    ef = max(1.3, ef)
    if repetitions == 0:
        interval = 1
    elif repetitions == 1:
        interval = 6
    else:
        interval = round(interval * ef)
    return repetitions + 1, ef, interval


async def get_due_mistakes(db: AsyncSession, user_id: str) -> list[Mistake]:
    now = datetime.now()
    result = await db.execute(
        select(Mistake).where(
            Mistake.user_id == user_id,
            Mistake.is_active.is_(True),
            (Mistake.next_review_at == None) | (Mistake.next_review_at <= now),
        ).order_by(Mistake.next_review_at.asc().nullsfirst())
    )
    return list(result.scalars().all())


async def review_mistake(db: AsyncSession, mistake_id: UUID, quality: int) -> Mistake | None:
    result = await db.execute(select(Mistake).where(Mistake.id == mistake_id))
    mistake = result.scalar_one_or_none()
    if not mistake:
        return None

    reps, ef_val, interval = _sm2(quality, mistake.repetitions, mistake.ef, mistake.interval_days)
    mistake.repetitions = reps
    mistake.ef = ef_val
    mistake.interval_days = interval
    mistake.next_review_at = datetime.now() + timedelta(days=interval)
    mistake.correct_count += 1 if quality >= 3 else 0

    await db.commit()
    await db.refresh(mistake)
    return mistake
