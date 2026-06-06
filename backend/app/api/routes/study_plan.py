from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.services import plan as plan_service

router = APIRouter(prefix="/plans", tags=["study_plans"])
USER_ID = "default-user"


@router.get("/")
async def get_plan(db: AsyncSession = Depends(get_db)):
    plan = await plan_service.get_current_plan(db, USER_ID)
    if not plan:
        return None
    return {
        "id": str(plan.id),
        "week_start": str(plan.week_start),
        "plan_json": plan.plan_json,
        "progress": plan.progress,
        "completed": plan.completed,
    }


@router.post("/generate")
async def generate_plan(db: AsyncSession = Depends(get_db)):
    plan = await plan_service.generate_plan(db, USER_ID)
    return {
        "id": str(plan.id),
        "week_start": str(plan.week_start),
        "plan_json": plan.plan_json,
        "progress": plan.progress,
        "completed": plan.completed,
    }
