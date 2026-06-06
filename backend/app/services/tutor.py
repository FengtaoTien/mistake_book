import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.mistake import Mistake
from app.models.tutor import TutorSession
from app.ai.llm import chat
from app.ai.prompts import TUTOR_INTRO
from app.ai.tts import synthesize
from app.ai.stt import transcribe
from app.config import UPLOAD_DIR


async def create_session(db: AsyncSession, user_id: str, mistake_id: str | None = None) -> TutorSession:
    session = TutorSession(user_id=user_id)
    if mistake_id:
        session.mistake_id = uuid.UUID(mistake_id)
        result = await db.execute(select(Mistake).where(Mistake.id == session.mistake_id))
        mistake = result.scalar_one_or_none()
        if mistake:
            intro = TUTOR_INTRO.format(
                question_text=mistake.question_text,
                answer_text=mistake.answer_text,
                subject=mistake.subject,
                tags=", ".join(mistake.tags),
                mistake_reason=mistake.mistake_reason,
            )
            session.messages = [{"role": "system", "content": intro}]
            llm_reply = await chat(session.messages)
            session.messages.append({"role": "assistant", "content": llm_reply})
            audio_file = f"tutor_{uuid.uuid4().hex}.mp3"
            audio_url = await synthesize(llm_reply, audio_file)
            session.messages[-1]["audio_url"] = audio_url

    db.add(session)
    await db.commit()
    await db.refresh(session)
    return session


async def chat_in_session(db: AsyncSession, session_id: uuid.UUID, text: str = "", audio: bytes | None = None) -> TutorSession:
    result = await db.execute(select(TutorSession).where(TutorSession.id == session_id))
    session = result.scalar_one_or_none()
    if not session:
        raise ValueError("Session not found")

    if audio:
        filename = f"user_audio_{uuid.uuid4().hex}.webm"
        path = UPLOAD_DIR / filename
        path.write_bytes(audio)
        text = await transcribe(str(path))

    session.messages.append({"role": "user", "content": text})

    messages = [{"role": "user" if m["role"] == "system" else m["role"], "content": m["content"]}
                for m in session.messages]

    llm_reply = await chat(messages)
    audio_file = f"tutor_{uuid.uuid4().hex}.mp3"
    audio_url = await synthesize(llm_reply, audio_file)

    session.messages.append({"role": "assistant", "content": llm_reply, "audio_url": audio_url})
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return session
