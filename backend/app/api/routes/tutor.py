import uuid
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.services import tutor as tutor_service

router = APIRouter(prefix="/tutor", tags=["tutor"])
USER_ID = "default-user"


@router.post("/sessions")
async def create_session(mistake_id: str | None = None, db: AsyncSession = Depends(get_db)):
    session = await tutor_service.create_session(db, USER_ID, mistake_id)
    return {
        "id": str(session.id),
        "messages": session.messages,
    }


@router.post("/sessions/{session_id}/chat")
async def chat(
    session_id: uuid.UUID,
    text: str = Form(""),
    audio: UploadFile | None = None,
    db: AsyncSession = Depends(get_db),
):
    audio_bytes = await audio.read() if audio else None
    try:
        session = await tutor_service.chat_in_session(db, session_id, text=text, audio=audio_bytes)
    except ValueError:
        raise HTTPException(status_code=404, detail="Session not found")
    return {
        "id": str(session.id),
        "messages": session.messages,
    }
