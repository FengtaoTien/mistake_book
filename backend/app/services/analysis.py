from app.ai.llm import chat_json
from app.ai.prompts import ANALYZE_MISTAKE
from app.schemas.mistake import MistakeCreate


async def analyze_mistake(question_text: str) -> dict:
    prompt = ANALYZE_MISTAKE.format(question_text=question_text)
    result = await chat_json([{"role": "user", "content": prompt}])
    return {
        "subject": result.get("subject", ""),
        "question_text": result.get("question_text", question_text),
        "tags": result.get("tags", []),
        "mistake_reason": result.get("mistake_reason", ""),
        "difficulty": result.get("difficulty", 3),
    }


async def enrich_create(data: MistakeCreate) -> MistakeCreate:
    if not data.question_text:
        return data
    if data.subject and data.mistake_reason:
        return data
    try:
        analysis = await analyze_mistake(data.question_text)
        return MistakeCreate(
            subject=data.subject or analysis["subject"],
            question_text=analysis["question_text"],
            answer_text=data.answer_text,
            mistake_reason=data.mistake_reason or analysis["mistake_reason"],
            difficulty=data.difficulty if data.difficulty != 3 else analysis["difficulty"],
            tags=data.tags or analysis["tags"],
            image_url=data.image_url,
            source=data.source,
        )
    except Exception:
        return data
