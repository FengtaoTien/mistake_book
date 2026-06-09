from uuid import UUID
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.mistake import Mistake
from app.schemas.mistake import MistakeCreate, MistakeUpdate


async def list_mistakes(db: AsyncSession, user_id: str, subject: str | None = None, grade: str | None = None) -> list[Mistake]:
    filters = [Mistake.user_id == user_id, Mistake.is_active.is_(True)]
    if subject:
        filters.append(Mistake.subject == subject)
    if grade:
        filters.append(Mistake.grade == grade)
    result = await db.execute(
        select(Mistake).where(and_(*filters))
        .order_by(Mistake.created_at.desc())
    )
    return list(result.scalars().all())


async def get_mistake(db: AsyncSession, mistake_id: UUID) -> Mistake | None:
    result = await db.execute(select(Mistake).where(Mistake.id == mistake_id))
    return result.scalar_one_or_none()


async def create_mistake(db: AsyncSession, user_id: str, data: MistakeCreate) -> Mistake:
    mistake = Mistake(user_id=user_id, **data.model_dump())
    db.add(mistake)
    await db.commit()
    await db.refresh(mistake)
    return mistake


async def update_mistake(db: AsyncSession, mistake_id: UUID, data: MistakeUpdate) -> Mistake | None:
    mistake = await get_mistake(db, mistake_id)
    if not mistake:
        return None
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(mistake, key, value)
    await db.commit()
    await db.refresh(mistake)
    return mistake


async def delete_mistake(db: AsyncSession, mistake_id: UUID) -> bool:
    mistake = await get_mistake(db, mistake_id)
    if not mistake:
        return False
    mistake.is_active = False
    await db.commit()
    return True
