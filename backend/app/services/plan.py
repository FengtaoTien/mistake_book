from datetime import date, timedelta
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.mistake import Mistake
from app.models.plan import StudyPlan
from app.ai.llm import chat_json
from app.ai.prompts import GENERATE_PLAN


def _week_start(d: date | None = None) -> date:
    d = d or date.today()
    return d - timedelta(days=d.weekday())


async def generate_plan(db: AsyncSession, user_id: str) -> StudyPlan:
    result = await db.execute(
        select(Mistake).where(Mistake.user_id == user_id, Mistake.is_active.is_(True))
    )
    mistakes = result.scalars().all()

    if not mistakes:
        ws = _week_start()
        plan = StudyPlan(user_id=user_id, week_start=ws, plan_json={"plan": [], "summary": "还没有错题数据"})
        db.add(plan)
        await db.commit()
        await db.refresh(plan)
        return plan

    summary_lines = []
    for m in mistakes:
        summary_lines.append(f"- 【{m.subject}】{m.question_text[:50]} (难度:{m.difficulty}, 错因:{m.mistake_reason})")
    mistakes_summary = "\n".join(summary_lines)

    try:
        result_data = await chat_json([{"role": "user", "content": GENERATE_PLAN.format(mistakes_summary=mistakes_summary)}])
        plan_json = result_data
    except Exception:
        plan_json = {"plan": [], "summary": "AI 生成失败，请稍后重试"}

    ws = _week_start()
    plan = StudyPlan(user_id=user_id, week_start=ws, plan_json=plan_json)
    db.add(plan)
    await db.commit()
    await db.refresh(plan)
    return plan


async def get_current_plan(db: AsyncSession, user_id: str) -> StudyPlan | None:
    ws = _week_start()
    result = await db.execute(
        select(StudyPlan).where(StudyPlan.user_id == user_id, StudyPlan.week_start == ws)
        .order_by(StudyPlan.created_at.desc())
    )
    return result.scalars().first()
