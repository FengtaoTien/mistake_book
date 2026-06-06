from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.schemas.mistake import MistakeCreate, MistakeUpdate, MistakeResponse
from app.services import mistake as service
from app.services.analysis import enrich_create

router = APIRouter(prefix="/mistakes", tags=["mistakes"])

USER_ID = "default-user"


@router.get("/", response_model=list[MistakeResponse])
async def list_mistakes(db: AsyncSession = Depends(get_db)):
    return await service.list_mistakes(db, USER_ID)


@router.get("/{mistake_id}", response_model=MistakeResponse)
async def get_mistake(mistake_id: UUID, db: AsyncSession = Depends(get_db)):
    m = await service.get_mistake(db, mistake_id)
    if not m:
        raise HTTPException(status_code=404, detail="Mistake not found")
    return m


@router.post("/", response_model=MistakeResponse, status_code=201)
async def create_mistake(data: MistakeCreate, db: AsyncSession = Depends(get_db)):
    enriched = await enrich_create(data)
    return await service.create_mistake(db, USER_ID, enriched)


@router.put("/{mistake_id}", response_model=MistakeResponse)
async def update_mistake(mistake_id: UUID, data: MistakeUpdate, db: AsyncSession = Depends(get_db)):
    m = await service.update_mistake(db, mistake_id, data)
    if not m:
        raise HTTPException(status_code=404, detail="Mistake not found")
    return m


@router.delete("/{mistake_id}", status_code=204)
async def delete_mistake(mistake_id: UUID, db: AsyncSession = Depends(get_db)):
    ok = await service.delete_mistake(db, mistake_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Mistake not found")
